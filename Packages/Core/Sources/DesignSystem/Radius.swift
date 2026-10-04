import CoreGraphics

/// Köşe yarıçapı ölçeği.
///
/// Token adı yarıçapın **kullanım yerini** anlatır, değerini değil. Böylece
/// tasarımda kart yuvarlaklığı değiştiğinde tek bir token güncellenir,
/// ekranlar taranmaz.
public enum Radius {

    /// 0pt — kenara dayanan tam genişlik öğeler.
    public static let none: CGFloat = 0

    /// 8pt — çipler, rozetler, küçük etiketler.
    public static let chip: CGFloat = 8

    /// 12pt — form alanları, giriş kutuları, küçük butonlar.
    public static let field: CGFloat = 12

    /// 16pt — kartlar, liste blokları, bilgi panelleri.
    public static let card: CGFloat = 16

    /// 24pt — alt sayfalar (bottom sheet), büyük paneller.
    public static let sheet: CGFloat = 24

    /// Tam yuvarlak — kapsül butonlar, avatarlar, durum göstergeleri.
    ///
    /// Öğenin yüksekliğinin yarısından büyük herhangi bir değer aynı sonucu verir.
    /// Sabit bir sayı yerine bu token kullanılır ki öğe yüksekliği değiştiğinde
    /// kapsül biçimi bozulmasın.
    public static let pill: CGFloat = 999
}
