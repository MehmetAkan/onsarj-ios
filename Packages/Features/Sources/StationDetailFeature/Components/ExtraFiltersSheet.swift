import DesignSystem
import SwiftUI

/// "Ek filtreler": iki anahtar. Değişiklik anında uygulanır; kaydet düğmesi yoktur. Sayfa içerik
/// yüksekliğindedir. Etkin araç yoksa "Aracımla uyumlu" pasiftir ve altında açıklama görünür.
struct ExtraFiltersSheet: View {
    @Bindable var model: StationListModel
    @State private var height: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(StationDetailText.localized("stationList.moreFilters"))
                .font(Typography.headline)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            DetailCard {
                Toggle(isOn: $model.filters.onlyAvailable) {
                    Text(StationDetailText.localized("stationList.onlyAvailable"))
                        .font(Typography.body)
                        .foregroundStyle(Theme.textPrimary)
                }
                Divider().overlay(Theme.borderSubtle)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Toggle(isOn: vehicleBinding) {
                        Text(StationDetailText.localized("stationList.matchesVehicle"))
                            .font(Typography.body)
                            .foregroundStyle(model.isVehicleFilterAvailable ? Theme.textPrimary : Theme.textDisabled)
                    }
                    .disabled(!model.isVehicleFilterAvailable)
                    if !model.isVehicleFilterAvailable {
                        Text(StationDetailText.localized("stationList.noActiveVehicle"))
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .tint(Theme.brandPrimary)
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents(height > 0 ? [.height(height)] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.backgroundSheet)
    }

    /// Araç yokken anahtar kapalı görünür (süzgeç de uygulanmaz).
    private var vehicleBinding: Binding<Bool> {
        Binding(
            get: { model.isVehicleFilterAvailable && model.filters.matchesVehicle },
            set: { model.filters.matchesVehicle = $0 }
        )
    }
}
