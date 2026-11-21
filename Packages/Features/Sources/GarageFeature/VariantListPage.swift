import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Modelin varyantları. Satıra dokunmak aracı **onaysız** ekler: eklerken satırda ilerleme göstergesi,
/// diğer satırlar pasif. Başarılıysa modal kapanır; hata olursa "Araç eklenemedi" ve sayfada kalınır.
struct VariantListPage: View {
    let model: AddVehicleModel
    let vehicleModel: VehicleModel
    let onAdded: () -> Void
    let onBack: () -> Void
    let onClose: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.vertical, Spacing.lg)
        }
        .garagePage(Text(verbatim: vehicleModel.name), onBack: onBack, onClose: onClose)
        .task { await model.loadVariants(of: vehicleModel.id) }
    }

    @ViewBuilder private var content: some View {
        switch model.variants[vehicleModel.id] ?? .loading {
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top, Spacing.xl)
        case .failed:
            LoadFailureView(messageKey: "garage.catalogLoadFailed") {
                Task { await model.loadVariants(of: vehicleModel.id) }
            }
        case .loaded(let variants):
            CatalogList(items: variants) { variant in
                VariantRow(
                    variant: variant,
                    summary: GarageText.variantSummary(variant, locale: locale),
                    isAdding: model.addingVariantID == variant.id
                ) {
                    Task { if await model.add(variant) { onAdded() } }
                }
                .disabled(model.addingVariantID != nil)
            }
        }
    }
}
