import SwiftUI

/// Ham renk paleti (primitive layer).
///
/// Bu katman tasarım sisteminin birinci katmanıdır: sabit, temadan bağımsız renk
/// basamakları. Açık ve koyu temada aynı değerleri taşır.
///
/// Ekranlar renk ihtiyacını normalde ikinci katmandan, yani anlamsal token'lardan
/// karşılar (`backgroundPrimary`, `actionPrimary` gibi). Ham basamağa doğrudan
/// başvurmak istisnadır; tekrar eden bir kullanım görürseniz o renk anlamsal
/// bir token olmayı hak ediyor demektir.
///
/// Ölçek Tailwind'in 50–950 basamaklandırmasını izler ve OKLCH uzayında
/// algısal olarak eşit aralıklıdır.
public enum Palette {

    // MARK: - Gray

    /// Gray — soğuk gri (H≈286). 100, 200, 300 ve 950 marka tarafından verildi,
    /// ara basamaklar OKLCH uzayında türetildi.
    public static let gray50 = Color(hex: 0xFAFAFB)
    public static let gray100 = Color(hex: 0xF5F5F6)
    public static let gray200 = Color(hex: 0xE6E6EA)
    public static let gray300 = Color(hex: 0xC3C3CD)
    public static let gray400 = Color(hex: 0xA4A4B0)
    public static let gray500 = Color(hex: 0x838491)
    public static let gray600 = Color(hex: 0x646573)
    public static let gray700 = Color(hex: 0x464857)
    public static let gray800 = Color(hex: 0x2A2D3C)
    public static let gray900 = Color(hex: 0x141726)
    public static let gray950 = Color(hex: 0x050715)

    // MARK: - Green

    /// Green — marka rengi. 500 basamağı logo yeşilidir (#4BBC17).
    public static let green50 = Color(hex: 0xEBF8E8)
    public static let green100 = Color(hex: 0xD5F1CD)
    public static let green200 = Color(hex: 0xB3E6A4)
    public static let green300 = Color(hex: 0x8AD773)
    public static let green400 = Color(hex: 0x69CB48)
    public static let green500 = Color(hex: 0x4BBC17)
    public static let green600 = Color(hex: 0x34A000)
    public static let green700 = Color(hex: 0x258000)
    public static let green800 = Color(hex: 0x196400)
    public static let green900 = Color(hex: 0x125000)
    public static let green950 = Color(hex: 0x053000)

    // MARK: - Red

    /// Red — Tailwind v4 (OKLCH tanımlarından çevrildi).
    public static let red50 = Color(hex: 0xFEF2F2)
    public static let red100 = Color(hex: 0xFFE2E2)
    public static let red200 = Color(hex: 0xFFC9C9)
    public static let red300 = Color(hex: 0xFFA2A2)
    public static let red400 = Color(hex: 0xFF6467)
    public static let red500 = Color(hex: 0xFB2C36)
    public static let red600 = Color(hex: 0xE7000B)
    public static let red700 = Color(hex: 0xC10007)
    public static let red800 = Color(hex: 0x9F0712)
    public static let red900 = Color(hex: 0x82181A)
    public static let red950 = Color(hex: 0x460809)

    // MARK: - Blue

    /// Blue — Tailwind v4.
    public static let blue50 = Color(hex: 0xEFF6FF)
    public static let blue100 = Color(hex: 0xDBEAFE)
    public static let blue200 = Color(hex: 0xBEDBFF)
    public static let blue300 = Color(hex: 0x8EC5FF)
    public static let blue400 = Color(hex: 0x51A2FF)
    public static let blue500 = Color(hex: 0x2B7FFF)
    public static let blue600 = Color(hex: 0x155DFC)
    public static let blue700 = Color(hex: 0x1447E6)
    public static let blue800 = Color(hex: 0x193CB8)
    public static let blue900 = Color(hex: 0x1C398E)
    public static let blue950 = Color(hex: 0x162456)

    // MARK: - Indigo

    /// Indigo — Tailwind v4.
    public static let indigo50 = Color(hex: 0xEEF2FF)
    public static let indigo100 = Color(hex: 0xE0E7FF)
    public static let indigo200 = Color(hex: 0xC6D2FF)
    public static let indigo300 = Color(hex: 0xA3B3FF)
    public static let indigo400 = Color(hex: 0x7C86FF)
    public static let indigo500 = Color(hex: 0x615FFF)
    public static let indigo600 = Color(hex: 0x4F39F6)
    public static let indigo700 = Color(hex: 0x432DD7)
    public static let indigo800 = Color(hex: 0x372AAC)
    public static let indigo900 = Color(hex: 0x312C85)
    public static let indigo950 = Color(hex: 0x1E1A4D)

    // MARK: - Violet

    /// Violet — Tailwind v4.
    public static let violet50 = Color(hex: 0xF5F3FF)
    public static let violet100 = Color(hex: 0xEDE9FE)
    public static let violet200 = Color(hex: 0xDDD6FF)
    public static let violet300 = Color(hex: 0xC4B4FF)
    public static let violet400 = Color(hex: 0xA684FF)
    public static let violet500 = Color(hex: 0x8E51FF)
    public static let violet600 = Color(hex: 0x7F22FE)
    public static let violet700 = Color(hex: 0x7008E7)
    public static let violet800 = Color(hex: 0x5D0EC0)
    public static let violet900 = Color(hex: 0x4D179A)
    public static let violet950 = Color(hex: 0x2F0D68)

    // MARK: - Purple

    /// Purple — Tailwind v4.
    public static let purple50 = Color(hex: 0xFAF5FF)
    public static let purple100 = Color(hex: 0xF3E8FF)
    public static let purple200 = Color(hex: 0xE9D4FF)
    public static let purple300 = Color(hex: 0xDAB2FF)
    public static let purple400 = Color(hex: 0xC27AFF)
    public static let purple500 = Color(hex: 0xAD46FF)
    public static let purple600 = Color(hex: 0x9810FA)
    public static let purple700 = Color(hex: 0x8200DB)
    public static let purple800 = Color(hex: 0x6E11B0)
    public static let purple900 = Color(hex: 0x59168B)
    public static let purple950 = Color(hex: 0x3C0366)
}

extension Color {

    /// 0xRRGGBB biçiminde bir tam sayıdan renk üretir.
    ///
    /// `Palette` içinden kullanılır; bu yüzden `internal` bırakıldı.
    /// Ekranlarda sabit renk kodu yazmak CLAUDE.md 6.1 ile yasaktır ve
    /// SwiftLint tarafından denetlenir.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
