/// Telefon numarası girişinde kullanılan ülke bilgisi.
///
/// Numara alanı ülkeyi dışarıdan alır; biçimlendirme ve geçerlilik kuralları buradan
/// okunur. Ülke seçimi eklendiğinde liste bu tipin örneklerinden oluşur.
struct PhoneCountry: Hashable, Sendable {
    /// Gruplama kalıbında bir rakamın yerini tutan karakter.
    static let digitPlaceholder: Character = "#"

    /// Ülke telefon kodu, `+` işareti olmadan: `"90"`.
    let dialCode: String

    /// Ülke bayrağı (emoji).
    let flag: String

    /// Ülke kodu hariç ulusal numaranın basamak sayısı.
    let digitCount: Int

    /// Numaranın ekranda gösterim kalıbı. Her `#` bir rakamdır, diğer karakterler
    /// rakamların arasına eklenir.
    let groupingPattern: String

    /// Geçerli bir numaranın başlaması gereken rakam. `nil` ise kısıt yoktur.
    let leadingDigit: Character?

    /// Ekranda gösterilen ülke kodu: `"+90"`.
    var displayDialCode: String {
        "+" + dialCode
    }

    /// Türkiye cep telefonu: `(5XX) XXX XX XX`.
    static let turkey = PhoneCountry(
        dialCode: "90",
        flag: "🇹🇷",
        digitCount: 10,
        groupingPattern: "(###) ### ## ##",
        leadingDigit: "5"
    )
}
