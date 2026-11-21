import DesignSystem
import OnsarjDomain
import SwiftUI

/// "Soketler": her grup bir satır; simge, tür adı, hız sınıfı ve güç, sağda müsaitlik rozeti.
struct ConnectorsSection: View {
    let groups: [ConnectorGroup]
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTitle(key: "stationDetail.connectors")
            DetailCard {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    if index > 0 { Divider().overlay(Theme.borderSubtle) }
                    row(group)
                }
            }
        }
    }

    private func row(_ group: ConnectorGroup) -> some View {
        HStack(spacing: Spacing.md) {
            group.type.icon
                .font(Typography.sectionTitle)
                .foregroundStyle(Theme.textSecondary)
            (Text(StationDetailText.localized(group.type.nameKey)).font(Typography.bodyStrong)
                + Text(verbatim: " · ").foregroundStyle(Theme.textSecondary)
                + Text(StationDetailText.speedAndPower(group, locale: locale)).foregroundStyle(Theme.textSecondary))
                .font(Typography.body)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: Spacing.sm)
            Text(StationDetailText.ratio(available: group.available, total: group.total))
                .font(Typography.numeric)
                .foregroundStyle(group.availability.color)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    group.availability.color.opacity(StationDetailMetrics.availabilityBadgeOpacity), in: Capsule()
                )
                .accessibilityLabel(
                    StationDetailText.ratioAccessibility(available: group.available, total: group.total))
        }
        .accessibilityElement(children: .combine)
    }
}
