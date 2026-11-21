import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Markanın modelleri: başlık marka adı, satırda model adı ve ok.
struct ModelListPage: View {
    let model: AddVehicleModel
    let brand: VehicleBrand
    let onSelect: (VehicleModel) -> Void
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.vertical, Spacing.lg)
        }
        .garagePage(Text(verbatim: brand.name), onBack: onBack, onClose: onClose)
        .task { await model.loadModels(of: brand.id) }
    }

    @ViewBuilder private var content: some View {
        switch model.models[brand.id] ?? .loading {
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top, Spacing.xl)
        case .failed:
            LoadFailureView(messageKey: "garage.catalogLoadFailed") { Task { await model.loadModels(of: brand.id) } }
        case .loaded(let models):
            CatalogList(items: models) { item in
                CatalogRow(title: item.name, detail: nil) {
                    EmptyView()
                } action: {
                    onSelect(item)
                }
            }
        }
    }
}
