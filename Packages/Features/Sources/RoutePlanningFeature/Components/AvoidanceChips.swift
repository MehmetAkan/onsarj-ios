import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// "Rotadan kaçının" çipleri: çoklu seçim. Seçili çip dolgulu, seçili olmayan sade. Satıra sığmayan
/// çip alt satıra sarar.
struct AvoidanceChips: View {
    let selected: Set<RouteAvoidance>
    let onToggle: (RouteAvoidance) -> Void

    var body: some View {
        WrappingHStack(spacing: Spacing.sm) {
            ForEach(RouteAvoidance.allCases, id: \.self) { avoidance in
                chip(avoidance, isSelected: selected.contains(avoidance))
            }
        }
    }

    private func chip(_ avoidance: RouteAvoidance, isSelected: Bool) -> some View {
        Button {
            onToggle(avoidance)
        } label: {
            HStack(spacing: Spacing.xs) {
                avoidance.icon
                Text(avoidance.titleKey, bundle: .onsarj)
            }
            .font(Typography.secondary)
            .foregroundStyle(isSelected ? Theme.onActionPrimary : Theme.textPrimary)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(
                isSelected ? Theme.actionPrimary : Theme.backgroundCard,
                in: RoundedRectangle(cornerRadius: Radius.chip)
            )
            .frame(minHeight: Spacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
