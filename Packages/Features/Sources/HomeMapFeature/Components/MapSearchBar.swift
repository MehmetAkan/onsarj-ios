import DesignSystem
import Localization
import SwiftUI

/// Alt sayfanın üstündeki arama çubuğu.
///
/// Arama alanı gibi görünür ama metin almaz: dokunulduğunda `action` çağrılır. Arama
/// ekranı açıldığında yazma orada başlar.
struct MapSearchBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
                Text("home.search.placeholder", bundle: .onsarj)
                    .foregroundStyle(Theme.textPlaceholder)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(Typography.body)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: Spacing.minTapTarget)
            .background(Theme.backgroundSubtle, in: shape)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.field)
    }
}
