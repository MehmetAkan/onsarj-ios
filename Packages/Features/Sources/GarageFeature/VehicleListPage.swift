import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// "Araçlarınız": her araç bir kart, etkin aracın çevresinde belirgin çerçeve. Karta dokunmak aracı
/// etkin yapar ve modalı kapatır. Altta "Yeni araç ekle".
///
/// Sayfa ideal yüksekliğini (üst çubuk + kartlar + düğme + alt güvenli alan) bildirir; kök görünüm
/// modalı bu yükseklikte açar.
struct VehicleListPage: View {
    let model: GarageModel
    let onAddNew: () -> Void
    let onClose: () -> Void
    let onIdealHeightChange: (CGFloat) -> Void

    @Environment(\.locale) private var locale
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var footerHeight: CGFloat = 0
    @State private var bottomInset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            GarageHeader(title: Text("garage.title", bundle: .onsarj), onClose: onClose)
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { headerHeight = $0 }
            ScrollView {
                content
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            PrimaryButton("garage.addNew", bundle: .onsarj, action: onAddNew)
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.vertical, Spacing.md)
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { footerHeight = $0 }
        }
        .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.bottom) { bottomInset = $0 }
        .onChange(of: headerHeight + contentHeight + footerHeight + bottomInset, initial: true) { _, height in
            onIdealHeightChange(height)
        }
        .background(Theme.backgroundSheet.ignoresSafeArea())
        .hidesNavigationBar()
        .task { await model.load() }
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
        case .failed:
            LoadFailureView(messageKey: "garage.loadFailed") { Task { await model.load() } }
        case .loaded:
            VStack(spacing: Spacing.sm) {
                ForEach(model.vehicles) { vehicle in
                    VehicleListCard(
                        vehicle: vehicle,
                        isActive: vehicle.id == model.activeVehicleID,
                        isSelecting: model.selectingID == vehicle.id,
                        locale: locale
                    ) {
                        Task { if await model.select(vehicle.id) { onClose() } }
                    }
                    .disabled(model.selectingID != nil)
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.sm)
        }
    }
}
