import SwiftUI

/// Uygulamanın simgeleri (CLAUDE.md 6.9).
///
/// Ekranlar simgeyi **anlamıyla** çağırır (`AppIcon.search`), kaynağıyla değil.
/// `Image(systemName:)` veya asset adı ekranlarda yazılmaz; kaynak değişirse yalnızca bu
/// dosya değişir.
///
/// Simge bir görünümdür; metin gibi çevresindeki yazı tipiyle boyutlanır:
///
/// ```swift
/// Label { Text("home.action.options", bundle: .onsarj) } icon: { AppIcon.options }
///     .font(Typography.buttonSmall)
/// ```
///
/// **Kaynaklar**
/// - SF Symbols (varsayılan). Her sembolün iOS 17'de var olduğu doğrulanmıştır; yanında
///   ilk çıktığı sürüm yazar.
/// - Tasarımcının SVG'leri (`Resources/Media.xcassets`). Tek renkli olanlar şablon olarak
///   çizilir ve rengini çevresindeki `foregroundStyle`'dan alır; renkli olanlar özgün
///   renkleriyle çizilir.
public enum AppIcon: Sendable, Hashable {
    /// Arama alanı. `magnifyingglass` (iOS 13)
    case search
    /// Seçenekler butonu. `slider.horizontal.3` (iOS 13)
    case options
    /// Kayıtlı planlar butonu. `heart` (iOS 13)
    case savedPlans
    /// Yapay zekâ asistanı. Renkli SVG: `icon-assistant`
    case assistant

    /// `fork.knife` (iOS 15)
    case categoryRestaurant
    /// `cup.and.saucer` (iOS 15)
    case categoryCafe
    /// Tek renkli SVG: `icon-category-mosque`. SF Symbols'ta cami simgesi yok.
    case categoryMosque
    /// `cart` (iOS 13)
    case categoryMarket
    /// `cross.case` (iOS 14)
    case categoryPharmacy
    /// `bed.double` (iOS 13)
    case categoryHotel
    /// `banknote` (iOS 14)
    case categoryATM

    fileprivate enum Source {
        case symbol(String)
        case asset(String, Image.TemplateRenderingMode)
    }

    fileprivate var source: Source {
        switch self {
        case .search: .symbol("magnifyingglass")
        case .options: .symbol("slider.horizontal.3")
        case .savedPlans: .symbol("heart")
        case .assistant: .asset("icon-assistant", .original)
        case .categoryRestaurant: .symbol("fork.knife")
        case .categoryCafe: .symbol("cup.and.saucer")
        case .categoryMosque: .asset("icon-category-mosque", .template)
        case .categoryMarket: .symbol("cart")
        case .categoryPharmacy: .symbol("cross.case")
        case .categoryHotel: .symbol("bed.double")
        case .categoryATM: .symbol("banknote")
        }
    }
}

extension AppIcon: View {
    public var body: some View {
        switch source {
        case .symbol(let name):
            Image(systemName: name)
                .accessibilityHidden(true)
        case .asset(let name, let renderingMode):
            AssetIcon(name: name, renderingMode: renderingMode)
        }
    }
}

/// SVG simgeyi bir SF Symbol'ün kutusuna yerleştirir.
///
/// Asset kataloğundaki görsel kendi doğal boyutunda çizilir ve yazı boyutuyla büyümez.
/// SF Symbols ise yazı tipiyle ölçeklenir ve metnin taban çizgisine oturur. Görünmez bir
/// referans sembol yerleştirilip SVG onun kutusuna sığdırıldığında özel simgeler de
/// SF Symbols gibi davranır: aynı boyut, aynı hizalama, Dynamic Type ile birlikte büyüme.
private struct AssetIcon: View {
    /// Kutusu ölçü olarak kullanılan sembol; kare simgelerin kapladığı alanı verir.
    private static let sizingReference = "circle"

    let name: String
    let renderingMode: Image.TemplateRenderingMode

    var body: some View {
        Image(systemName: Self.sizingReference)
            .hidden()
            .overlay {
                Image(name, bundle: .module)
                    .renderingMode(renderingMode)
                    .resizable()
                    .scaledToFit()
            }
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("AppIcon") {
    let icons: [AppIcon] = [
        .search, .options, .savedPlans, .assistant,
        .categoryRestaurant, .categoryCafe, .categoryMosque, .categoryMarket,
        .categoryPharmacy, .categoryHotel, .categoryATM,
    ]
    return HStack(spacing: Spacing.md) {
        ForEach(icons, id: \.self) { $0 }
    }
    .font(Typography.body)
    .foregroundStyle(Theme.textPrimary)
    .padding(Spacing.xl)
    .background(Theme.backgroundSheet)
}
#endif
