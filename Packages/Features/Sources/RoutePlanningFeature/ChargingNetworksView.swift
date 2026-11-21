import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Şarj ağları sayfası: tercih edilen ve kaçınılan ağlar, her birinin altında "+ … ekle" satırı.
struct ChargingNetworksView: View {
    let model: RoutePreferencesModel
    let onAdd: (NetworkPickerMode) -> Void
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                section(title: "networks.preferred", note: "networks.preferred.note") {
                    ForEach(model.preferences.preferredNetworks, id: \.self) { networkID in
                        NetworkRow(name: model.name(for: networkID)) { model.remove(networkID) }
                        InsetDivider()
                    }
                    AddRowButton(Text("networks.addPreferred", bundle: .onsarj)) { onAdd(.prefer) }
                }
                section(title: "networks.avoided", note: "networks.avoided.note") {
                    ForEach(model.preferences.avoidedNetworks, id: \.self) { networkID in
                        NetworkRow(name: model.name(for: networkID)) { model.remove(networkID) }
                        InsetDivider()
                    }
                    AddRowButton(Text("networks.addAvoided", bundle: .onsarj)) { onAdd(.avoid) }
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ModalHeader(
                Text("networks.title", bundle: .onsarj),
                backLabel: Text("common.back", bundle: .onsarj),
                onBack: onBack,
                closeLabel: Text("common.close", bundle: .onsarj),
                onClose: onClose
            )
            .background(Theme.backgroundSheet)
        }
        .background(Theme.backgroundSheet.ignoresSafeArea())
        .hidesNavigationBar()
    }

    private func section(
        title: LocalizedStringKey,
        note: LocalizedStringKey,
        @ViewBuilder rows: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title, bundle: .onsarj)
                .font(Typography.headline)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(note, bundle: .onsarj)
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 0) {
                rows()
            }
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
        }
    }
}
