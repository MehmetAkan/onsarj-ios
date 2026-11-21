import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// "Araç ekle": markalar. Arama alanı marka adında süzer. Satır: logo, ad, "N model", ok.
struct BrandListPage: View {
    let model: AddVehicleModel
    /// `nil`: akışın kökü (kartın "Araç ekle"sinden açıldı), geri düğmesi yok.
    let onBack: (() -> Void)?
    let onSelect: (VehicleBrand) -> Void
    let onClose: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                SearchField(
                    query: Binding(get: { model.brandQuery }, set: { model.brandQuery = $0 }),
                    placeholder: Text("common.search", bundle: .onsarj),
                    isFocused: $isSearchFocused
                )
                results
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
        .scrollDismissesKeyboard(.immediately)
        .garagePage(Text("garage.addVehicle", bundle: .onsarj), onBack: onBack, onClose: onClose)
        .task { await model.loadBrands() }
    }

    @ViewBuilder private var results: some View {
        switch model.brands {
        case .loading:
            ProgressView().padding(.top, Spacing.xl)
        case .failed:
            LoadFailureView(messageKey: "garage.catalogLoadFailed") { Task { await model.loadBrands() } }
        case .loaded:
            if model.filteredBrands.isEmpty {
                CatalogMessage(key: "common.noResults")
            } else {
                CatalogList(items: model.filteredBrands) { brand in
                    CatalogRow(title: brand.name, detail: GarageText.modelCount(brand.modelCount)) {
                        BrandLogo(url: brand.logoURL)
                    } action: {
                        onSelect(brand)
                    }
                }
            }
        }
    }
}

/// Marka logosu; yoksa veya yüklenemezse genel araç simgesi. Simge boyutunda çizilir ve yazıyla ölçeklenir.
struct BrandLogo: View {
    let url: URL?

    var body: some View {
        AppIcon.vehicle
            .font(Typography.titleSmall)
            .foregroundStyle(Theme.textSecondary)
            .opacity(url == nil ? 1 : 0)
            .overlay {
                if let url {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            AppIcon.vehicle
                                .font(Typography.titleSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .accessibilityHidden(true)
    }
}
