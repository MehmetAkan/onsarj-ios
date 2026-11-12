import DesignSystem
import SwiftUI

/// Gri daire içinde bir simge. Ekran başlığının üzerindeki görsel işaret.
///
/// Simge dışarıdan `Image` olarak verilir: asset kataloğundaki özel bir görsel ya da bir
/// SF Symbol. Özel görseller kendi renkleri ve doğal boyutlarıyla gösterilir; SF Symbol
/// verilirse `Typography.titleSmall` boyutunda ve `Theme.textSecondary` renginde çizilir.
///
/// Süslemedir; ekran okuyucudan gizlidir.
struct IconBadge: View {
    let image: Image

    /// Dairenin çapı. Yazı boyutuyla ölçeklenir.
    @ScaledMetric(relativeTo: .title2) private var diameter: CGFloat = 56

    var body: some View {
        image
            .font(Typography.titleSmall)
            .foregroundStyle(Theme.textSecondary)
            .frame(width: diameter, height: diameter)
            .background(Theme.backgroundSubtle, in: Circle())
            .accessibilityHidden(true)
    }
}
