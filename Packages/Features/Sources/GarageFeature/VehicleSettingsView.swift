import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Araç ayarları modalının kökü: ayarlar, konnektör türleri, sürüş profilleri ve profil formu aynı
/// modal içinde yığınla açılır; değerler küçük bir değer modalıyla düzenlenir.
///
/// Uygulama katmanı bu görünümü sunar; ana sayfa onu bilmez (CLAUDE.md 5.3). Her sayfadaki X modalın
/// tamamını kapatır. Araç silinince de `onClose` çağrılır. Tüm sayfalar aynı `VehicleSettingsModel`'i
/// paylaşır.
public struct VehicleSettingsView: View {
    enum Destination: Hashable {
        case connectors
        case profiles
        /// `nil`: yeni profil.
        case profileForm(DrivingProfile.ID?)
    }

    @State private var model: VehicleSettingsModel
    @State private var path: [Destination] = []
    @State private var valueTarget: ValueEditTarget?
    private let onClose: () -> Void

    /// - Parameters:
    ///   - repository: Araç deposu; yazma işlemleri de buradan yapılır.
    ///   - vehicleID: Ayarları açılan araç.
    ///   - onClose: X'e dokunuldu veya araç silindi; modal kapatılmalı.
    public init(repository: any VehicleRepository, vehicleID: Vehicle.ID, onClose: @escaping () -> Void) {
        self.init(model: VehicleSettingsModel(repository: repository, vehicleID: vehicleID), onClose: onClose)
    }

    init(model: VehicleSettingsModel, onClose: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack(path: $path) {
            VehicleSettingsPage(
                model: model,
                onEdit: { valueTarget = $0 },
                onOpen: { path.append($0) },
                onClose: onClose
            )
            .navigationDestination(for: Destination.self, destination: destination)
        }
        .overlay(alignment: .bottom) {
            if let notice = model.notice {
                NoticeBanner(notice: notice, onDismiss: model.dismissNotice)
            }
        }
        .sheet(item: $valueTarget) { target in
            if let vehicle = model.vehicle {
                ValueEditorSheet(target: target, vehicle: vehicle) { editor in
                    _ = await model.save(target, editor: editor)
                    valueTarget = nil
                }
            }
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private func destination(_ destination: Destination) -> some View {
        switch destination {
        case .connectors:
            ConnectorTypesView(model: model, onBack: pop, onClose: onClose)
        case .profiles:
            DrivingProfilesView(
                model: model,
                onOpen: { path.append(.profileForm($0)) },
                onBack: pop,
                onClose: onClose
            )
        case .profileForm(let profileID):
            if let vehicle = model.vehicle {
                DrivingProfileFormView(
                    model: model,
                    vehicle: vehicle,
                    profile: vehicle.drivingProfiles.first { $0.id == profileID },
                    onDone: pop,
                    onClose: onClose
                )
            }
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

/// Garaj sayfalarının üst çubuğu: plan seçenekleriyle aynı `ModalHeader`.
struct GarageHeader: View {
    let title: Text
    var onBack: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        ModalHeader(
            title,
            backLabel: Text("common.back", bundle: .onsarj),
            onBack: onBack,
            closeLabel: Text("common.close", bundle: .onsarj),
            onClose: onClose
        )
        .background(Theme.backgroundSheet)
    }
}

extension View {
    /// Garaj sayfalarının ortak iskeleti: üst çubuk, sayfa zemini, gizli sistem çubuğu.
    func garagePage(_ title: Text, onBack: (() -> Void)? = nil, onClose: @escaping () -> Void) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            GarageHeader(title: title, onBack: onBack, onClose: onClose)
        }
        .background(Theme.backgroundSheet.ignoresSafeArea())
        .hidesNavigationBar()
    }
}
