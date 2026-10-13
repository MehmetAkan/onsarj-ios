/// Kullanıcının girdiği numaranın çözümlenmiş hali.
public struct ParsedPhoneNumber: Hashable, Sendable {
    /// Numaranın ait olduğu ülke. Girdi `+` ile başlayan uluslararası bir numaraysa
    /// (otomatik doldurma, yapıştırma) seçili ülkeden farklı olabilir.
    public let country: PhoneCountry

    /// Ülke kodu ve ulusal ön ek (`0`) hariç, yalnızca rakamlardan oluşan numara.
    public let nationalDigits: String

    /// Ekranda gösterilecek, ülkenin biçimine göre gruplanmış numara: `"553 735 93 94"`.
    public let formatted: String

    /// E.164 biçimi: `"+905537359394"`. Numara bu ülke için olası değilse `nil`.
    public let e164: String?

    /// Numara bu ülke için olası mı. Doğrulama bilerek gevşektir: uzunluk denetlenir,
    /// numaranın gerçekten kullanıldığı SMS koduyla anlaşılır.
    public var isValid: Bool {
        e164 != nil
    }
}
