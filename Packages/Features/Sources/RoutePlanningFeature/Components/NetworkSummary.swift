import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Plan seçeneklerindeki şarj ağları özeti.
///
/// Hiç ağ yoksa "Tercih edilen ağ yok."; varsa "Tercih edilen" ve "Kaçınılan" küçük başlıkları, altlarında
/// virgülle ayrılmış ağ adları. İki grup ince bir çizgiyle ayrılır. Uzun liste kısaltılır ve "…" ile biter.
struct NetworkSummary: View {
    let preferences: RoutePreferences
    let name: (ChargingNetwork.ID) -> String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if preferences.preferredNetworks.isEmpty && preferences.avoidedNetworks.isEmpty {
                Text("plan.networks.none", bundle: .onsarj)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            if !preferences.preferredNetworks.isEmpty {
                group("plan.networks.preferred", networks: preferences.preferredNetworks)
            }
            if !preferences.preferredNetworks.isEmpty && !preferences.avoidedNetworks.isEmpty {
                Divider().overlay(Theme.borderSubtle)
            }
            if !preferences.avoidedNetworks.isEmpty {
                group("plan.networks.avoided", networks: preferences.avoidedNetworks)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
    }

    private func group(_ titleKey: LocalizedStringKey, networks: [ChargingNetwork.ID]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(titleKey, bundle: .onsarj)
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(verbatim: networks.map(displayName).joined(separator: ", "))
                .font(Typography.secondary)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
    }

    private func displayName(_ networkID: ChargingNetwork.ID) -> String {
        name(networkID) ?? String(localized: "networks.unknown", bundle: .onsarj)
    }
}
