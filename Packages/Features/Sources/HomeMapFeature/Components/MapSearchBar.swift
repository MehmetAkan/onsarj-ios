import DesignSystem
import Localization
import SwiftUI

/// Alt sayfanın başlığındaki arama satırı: arama alanı ve yapay zekâ asistanı butonu.
///
/// İki ayrı öğedir. Arama alanı kalan genişliği doldurur; arama alanı gibi görünür ama metin
/// almaz, dokunulduğunda `onSearch` çağrılır ve yazma arama ekranında başlar. Asistan butonu
/// daire biçimindedir ve yüksekliği arama alanınınkine eşittir; yazı büyüdükçe birlikte büyür.
struct MapSearchBar: View {
    let onSearch: () -> Void
    let onAssistant: () -> Void

    /// Arama alanının ölçülen yüksekliği; asistan butonunun çapı.
    @State private var fieldHeight: CGFloat = Spacing.minTapTarget

    var body: some View {
        HStack(spacing: Spacing.sm) {
            searchField
            assistantButton
        }
        .font(Typography.body)
    }

    private var searchField: some View {
        Button(action: onSearch) {
            HStack(spacing: Spacing.sm) {
                AppIcon.search
                    .foregroundStyle(Theme.textSecondary)
                Text("home.search.placeholder", bundle: .onsarj)
                    .foregroundStyle(Theme.textPlaceholder)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: Spacing.minTapTarget)
            .background(Theme.backgroundCard, in: fieldShape)
            .contentShape(fieldShape)
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            fieldHeight = height
        }
    }

    private var assistantButton: some View {
        Button(action: onAssistant) {
            AppIcon.assistant
                .frame(width: fieldHeight, height: fieldHeight)
                .background(Theme.backgroundCard, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("home.accessibility.assistant", bundle: .onsarj))
    }

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.field)
    }
}
