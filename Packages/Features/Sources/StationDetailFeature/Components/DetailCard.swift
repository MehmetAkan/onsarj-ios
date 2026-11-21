import DesignSystem
import SwiftUI

/// Detay sayfasındaki kart: sayfa zemininin üstünde yuvarlak köşeli yüzey.
struct DetailCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            content
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
    }
}

/// Bölüm başlığı ("Soketler", "Olanaklar").
struct SectionTitle: View {
    let key: String

    var body: some View {
        Text(StationDetailText.localized(key))
            .font(Typography.headline)
            .foregroundStyle(Theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}
