#if canImport(UIKit)
import UIKit

/// `Typography` token'larının UIKit karşılıkları.
///
/// Bazı bileşenler UIKit ile yazılır: metin girişinde karakter süzme (`UITextField`),
/// navigasyon arayüzü ve CarPlay. Bu bileşenler `UIFont` ister, SwiftUI `Font`
/// kabul etmez. Eşleşme burada tek noktada tutulur; bileşenlerin içine dağıtılmaz.
///
/// **Yalnızca ihtiyaç duyulan token'lar eklenir.** Yeni bir UIKit bileşeni başka bir
/// token'a ihtiyaç duyarsa önce proje sahibine sorulur (CLAUDE.md 6.5).
///
/// Tüm değerler `UIFontMetrics` üzerinden ölçeklenir. Bunları kullanan görünümlerde
/// `adjustsFontForContentSizeCategory = true` ayarlanmalıdır; aksi halde kullanıcı
/// yazı boyutunu değiştirdiğinde metin güncellenmez.
public enum UITypography {

    /// `Typography.numeric` karşılığı: sabit genişlikli rakamlarla gövde metni. (17pt)
    ///
    /// Telefon numarası, kalan menzil, varış saati gibi değişen sayılarda kullanılır.
    /// Sabit genişlikli rakamlar, sayı güncellenirken metnin yatayda zıplamasını önler.
    public static var numeric: UIFont {
        // 17pt, `body` metin stilinin varsayılan boyutu.
        let base = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base)
    }
}
#endif