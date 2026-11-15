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
    /// Ayarlar (ör. araç ayarları). `gearshape` (iOS 14)
    case settings
    /// Açılır seçim (ör. araç değiştirme). `chevron.down` (iOS 13)
    case dropdown
    /// Sayfayı kapatma. `xmark` (iOS 13)
    case close
    /// Metin alanını temizleme. `xmark.circle.fill` (iOS 13)
    case clearText
    /// Ev adresi. `house.fill` (iOS 13)
    case home
    /// İş adresi. `briefcase.fill` (iOS 13)
    case work
    /// Ekleme. `plus` (iOS 13)
    case add
    /// Geçmiş. `clock.arrow.circlepath` (iOS 14)
    case history
    /// Yer, konum önerisi. `mappin.and.ellipse` (iOS 14)
    case place
    /// Şarj istasyonu. `bolt.fill` (iOS 13)
    case charger
    /// Bir önceki sayfaya dönme. `chevron.left` (iOS 13)
    case back
    /// Satırın başka bir sayfa veya modal açtığını gösteren ok. `chevron.right` (iOS 13)
    case disclosure
    /// Genel araç (ör. logosu olmayan marka). `car.fill` (iOS 13)
    case vehicle
    /// Listeden kaldırma. `xmark` (iOS 13)
    case remove
    /// Eklendi, seçildi. `checkmark` (iOS 13)
    case checkmark

    /// Geçiş ücretleri. `creditcard` (iOS 13)
    case avoidTolls
    /// Otoyollar. `road.lanes` (iOS 16)
    case avoidHighways
    /// Feribotlar ve araba trenleri. `ferry` (iOS 16)
    case avoidFerries
    /// Ülke sınırları. `flag` (iOS 13)
    case avoidBorders

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
        case .settings: .symbol("gearshape")
        case .dropdown: .symbol("chevron.down")
        case .close: .symbol("xmark")
        case .clearText: .symbol("xmark.circle.fill")
        case .home: .symbol("house.fill")
        case .work: .symbol("briefcase.fill")
        case .add: .symbol("plus")
        case .history: .symbol("clock.arrow.circlepath")
        case .place: .symbol("mappin.and.ellipse")
        case .charger: .symbol("bolt.fill")
        case .back: .symbol("chevron.left")
        case .disclosure: .symbol("chevron.right")
        case .vehicle: .symbol("car.fill")
        case .remove: .symbol("xmark")
        case .checkmark: .symbol("checkmark")
        case .avoidTolls: .symbol("creditcard")
        case .avoidHighways: .symbol("road.lanes")
        case .avoidFerries: .symbol("ferry")
        case .avoidBorders: .symbol("flag")
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
        .search, .options, .savedPlans, .assistant, .settings, .dropdown,
        .close, .clearText, .home, .work, .add, .history, .place, .charger,
        .back, .disclosure, .vehicle, .remove, .checkmark,
        .avoidTolls, .avoidHighways, .avoidFerries, .avoidBorders,
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
