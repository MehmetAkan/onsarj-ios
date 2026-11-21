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
                SelectableChip(
                    Text(avoidance.titleKey, bundle: .onsarj),
                    icon: avoidance.icon,
                    isSelected: selected.contains(avoidance)
                ) { onToggle(avoidance) }
            }
        }
    }
}
