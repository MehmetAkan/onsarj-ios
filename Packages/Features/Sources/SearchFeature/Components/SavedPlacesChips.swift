import DesignSystem
import Localization
import SwiftUI

/// Kayıtlı yerler satırı: "Ev ekle" ve "İş ekle" dolgulu çip, "Kayıtlı ekle" dolgusuz düğme.
///
/// Dar ekranda veya büyük yazıda yatay kayar; taşmaz.
struct SavedPlacesChips: View {
    let onSetHome: () -> Void
    let onSetWork: () -> Void
    let onAddSaved: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.sm) {
                CategoryChip("search.setHome", icon: .home, bundle: .onsarj, action: onSetHome)
                CategoryChip("search.setWork", icon: .work, bundle: .onsarj, action: onSetWork)
                Button(action: onAddSaved) {
                    HStack(spacing: Spacing.xs) {
                        AppIcon.add
                        Text("search.addSaved", bundle: .onsarj)
                            .lineLimit(1)
                    }
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .frame(minHeight: Spacing.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
    }
}
