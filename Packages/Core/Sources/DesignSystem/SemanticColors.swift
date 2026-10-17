import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Anlamsal renk token'ları (semantic layer).
///
/// Tasarım sisteminin ikinci katmanı. Her token bir **işlevi** adlandırır
/// (`actionPrimary`), rengi değil (`green500`). Ekranların kullandığı renk kaynağı budur.
///
/// Her token'ın açık ve koyu tema karşılığı birlikte tanımlanır. Tek temalı token
/// eklenmez — sonradan ikinci temayı eklemek tüm ekranları gezmek demektir.
///
/// Koyu tema değerleri `Palette.ink` merdiveninden gelir: saf siyahtan (`ink0`)
/// yukarı doğru, her katman bir basamak açılır. Mantık yükselmedir — bir öğe
/// kullanıcıya ne kadar yakınsa o kadar açıktır.
public enum Theme {

    // MARK: - Yüzeyler

    /// Ekranın ana arka planı.
    public static let backgroundPrimary = Color(light: .white, dark: Palette.ink0)

    /// Ana arka planın üzerinde yükselen yüzey: kartlar, alt sayfalar.
    public static let backgroundElevated = Color(light: .white, dark: Palette.ink1)

    /// Hafif vurgulu yüzey: giriş alanları, pasif çipler, gruplanmış liste blokları.
    public static let backgroundSubtle = Color(light: Palette.gray100, dark: Palette.ink1)

    /// İnce ayırıcı çizgiler ve kenarlıklar.
    public static let borderSubtle = Color(light: Palette.gray200, dark: Palette.ink3)

    /// Hatalı girdi taşıyan alanın kenarlığı.
    public static let borderError = Color(light: Palette.red500, dark: Palette.red400)

    // MARK: - Metin

    /// Başlıklar ve birincil metin.
    public static let textPrimary = Color(light: Palette.gray950, dark: .white)

    /// Açıklama satırları, ikincil bilgi.
    public static let textSecondary = Color(light: Palette.gray500, dark: Palette.ink5)

    /// Pasif veya devre dışı metin.
    public static let textDisabled = Color(light: Palette.gray400, dark: Palette.ink4)

    /// Hata mesajları.
    ///
    /// Koyu temada bir basamak açılır; koyu zemin üzerinde `red500` okunurluğunu kaybeder.
    public static let textError = Color(light: Palette.red600, dark: Palette.red400)

    /// Boş giriş alanlarındaki yer tutucu metin.
    ///
    /// `textSecondary`'den açıktır: yer tutucu gerçek içerik değil, doldurulacak
    /// alanın ipucudur ve okunduğunda girilmiş veriyle karışmamalıdır.
    public static let textPlaceholder = Color(light: Palette.gray400, dark: Palette.ink4)

    // MARK: - Eylem

    /// Birincil buton arka planı.
    ///
    /// Koyu temada açık renge döner: koyu zemin üzerinde koyu buton görünmez olurdu.
    public static let actionPrimary = Color(light: Palette.gray950, dark: .white)

    /// Birincil buton üzerindeki metin ve simgeler.
    public static let onActionPrimary = Color(light: Palette.gray50, dark: Palette.ink0)

    /// Basılı durumdaki birincil buton.
    public static let actionPrimaryPressed = Color(light: Palette.gray800, dark: Palette.gray200)

    /// Devre dışı birincil butonun üzerindeki metin.
    ///
    /// Ayrı bir token gerekiyor: koyu temada etkin buton beyaz zemin üzerine siyah
    /// metin taşır, devre dışı buton ise koyu zemine döner ve aynı siyah metin
    /// okunamaz hale gelir.
    public static let onActionPrimaryDisabled = Color(light: Palette.gray300, dark: Palette.ink5)

    /// Devre dışı birincil buton.
    ///
    /// Butonu gizlemez, yalnızca vurgusunu düşürür. Kullanıcı butonun orada olduğunu
    /// ve neyi tamamlayınca etkinleşeceğini görebilmelidir. Üzerindeki metin
    /// `onActionPrimaryDisabled` kullanır.
    public static let actionPrimaryDisabled = Color(light: Palette.gray700, dark: Palette.ink2)

    /// Marka vurgusu: seçili durumlar, aktif simgeler, logo eşliği.
    ///
    /// Koyu temada bir basamak açılır. Koyu zemin üzerinde aynı yeşil fazla parlak
    /// görünür ve gözü yorar.
    public static let brandPrimary = Color(light: Palette.green500, dark: Palette.green400)

    // MARK: - Sayfa göstergesi

    /// Aktif sayfa noktası.
    public static let indicatorActive = Color(light: Palette.gray950, dark: .white)

    /// Pasif sayfa noktaları.
    public static let indicatorInactive = Color(light: Palette.gray300, dark: Palette.ink3)
}

extension Color {

    /// Açık ve koyu tema için ayrı değer taşıyan renk üretir.
    ///
    /// Renk, görünümün o anki temasına göre çalışma zamanında çözülür. Bu sayede
    /// kullanıcı tema değiştirdiğinde ekranın yeniden çizilmesi gerekmez.
    ///
    /// Platform koruması, `swift build`'in ana makinede (macOS) çalışmaya devam etmesi
    /// içindir. UIKit orada bulunmadığı için koruma olmasa tüm `Core` paketi
    /// derlenmezdi ve her değişiklikte dakikalar süren `verify-ios.sh` beklenirdi.
    /// macOS dalı hiçbir zaman dağıtılmaz; yalnızca geliştirme döngüsünü hızlı tutar.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            }
        )
        #else
        self = light
        #endif
    }
}
