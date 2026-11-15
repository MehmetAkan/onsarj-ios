import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Konnektör türleri: çoklu seçim, her dokunuş anında kaydedilir. Son seçili tür kaldırılamaz; satır
/// pasifleşmez, dokunulursa kısa uyarı gösterilir.
struct ConnectorTypesView: View {
    let model: VehicleSettingsModel
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(ConnectorType.allCases, id: \.self) { connector in
                    row(connector, isSelected: model.connectors.contains(connector))
                    if connector != ConnectorType.allCases.last {
                        InsetDivider()
                    }
                }
            }
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
        .garagePage(Text("vehicleSettings.connectors", bundle: .onsarj), onBack: onBack, onClose: onClose)
    }

    private func row(_ connector: ConnectorType, isSelected: Bool) -> some View {
        Button {
            Task { await model.toggleConnector(connector) }
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(verbatim: connector.name)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    AppIcon.checkmark
                        .font(Typography.bodyStrong)
                        .foregroundStyle(Theme.brandPrimary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: Spacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
