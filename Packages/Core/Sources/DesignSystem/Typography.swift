import SwiftUI

/// Tipografi token'ları.
///
/// Her token iOS'un kendi metin stillerinden birine dayanır. Bu kasıtlıdır:
/// `Font.system(size: 24)` yazmak boyutu sabitler ve kullanıcının yazı boyutu
/// ayarına tepki vermez. Metin stili üzerine kurmak ölçeklenmeyi bedava getirir.
///
/// Parantez içindeki puntolar varsayılan (`Large`) ayardaki değerlerdir.
/// Kullanıcı ayarı değiştirdiğinde hepsi birlikte ölçeklenir.
///
/// Token adı **işlevi** anlatır, puntoyu değil. `font20` değil `sectionTitle`.
public enum Typography {

    // MARK: - Başlıklar

    /// Ekranın en büyük başlığı. Nadir kullanılır. (34pt)
    public static let display = Font.largeTitle.weight(.bold)

    /// Ekran başlığı — "What's Your Phone?" gibi. (28pt)
    public static let title = Font.title.weight(.bold)

    /// İkincil başlık, kart grupları. (22pt)
    public static let titleSmall = Font.title2.weight(.semibold)

    /// Bölüm başlığı, liste grubu başlığı. (20pt)
    public static let sectionTitle = Font.title3.weight(.semibold)

    // MARK: - Gövde

    /// Vurgulu gövde metni, gezinme çubuğu başlığı. (17pt, semibold)
    public static let headline = Font.headline

    /// Varsayılan gövde metni. (17pt)
    public static let body = Font.body

    /// Vurgulanmış gövde metni. (17pt, semibold)
    public static let bodyStrong = Font.body.weight(.semibold)

    /// İkincil metin, açıklama satırları. (15pt)
    public static let secondary = Font.subheadline

    /// Küçük bilgi metni, yardım satırları. (13pt)
    public static let caption = Font.footnote

    /// En küçük metin: etiketler, zaman damgaları. (12pt)
    public static let captionSmall = Font.caption

    // MARK: - Eylem

    /// Birincil buton metni. (17pt, semibold)
    public static let button = Font.body.weight(.semibold)

    /// İkincil veya küçük buton metni. (15pt, semibold)
    public static let buttonSmall = Font.subheadline.weight(.semibold)

    // MARK: - Sayısal gösterim

    /// Değişen sayılar: kalan menzil, varış saati, batarya yüzdesi, şarj gücü.
    ///
    /// Sabit genişlikli rakamlar kullanır. Navigasyon sırasında sayı her
    /// güncellendiğinde metnin yatayda zıplamasını önler — sürüş halindeki
    /// kullanıcı için okunabilirlik açısından önemlidir. (17pt)
    public static let numeric = Font.body.monospacedDigit()

    /// Büyük sayısal gösterim: navigasyon ekranındaki kalan mesafe gibi. (28pt)
    public static let numericLarge = Font.title.weight(.bold).monospacedDigit()
}

public extension View {

    /// Uygulamanın desteklediği yazı boyutu aralığını sınırlar.
    ///
    /// Alt sınır `xSmall`, üst sınır `xxxLarge` — yani iOS'un standart aralığının
    /// tamamı. Erişilebilirlik kademeleri (`accessibility1`–`accessibility5`)
    /// kapsam dışıdır; o boyutlarda yerleşim bozulur ve araç içi kullanımda
    /// test edilemez.
    ///
    /// Uygulama kökünde bir kez uygulanır.
    func onsarjDynamicTypeRange() -> some View {
        dynamicTypeSize(.xSmall ... .xxxLarge)
    }
}
