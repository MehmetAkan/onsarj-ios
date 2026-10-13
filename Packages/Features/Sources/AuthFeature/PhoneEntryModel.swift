import Localization
import Observation
import PhoneNumbers

/// Telefon numarası giriş ekranının durumu: seçili ülke ve çözümlenmiş numara.
///
/// Numara kuralları (biçim, uzunluk, geçerlilik) `PhoneNumberFormatter`'dan gelir;
/// model elle kural yazmaz.
@MainActor
@Observable
final class PhoneEntryModel {
    @ObservationIgnored let formatter: PhoneNumberFormatter

    /// Girilen numara. Ülke de bunun içindedir: `+` ile başlayan bir numara
    /// yapıştırıldığında ülke numaradan belirlenir.
    var number: ParsedPhoneNumber

    var isCountryPickerPresented = false

    /// - Parameters:
    ///   - country: Başlangıç ülkesi; verilmezse cihazın bölgesinden alınır.
    ///   - input: Başlangıç numarası.
    init(formatter: PhoneNumberFormatter, country: PhoneCountry? = nil, input: String = "") {
        self.formatter = formatter
        number = formatter.parse(input, for: country ?? formatter.defaultCountry())
    }

    var country: PhoneCountry {
        number.country
    }

    /// Alanın yer tutucusu: seçili ülkenin örnek numarası, yoksa genel metin.
    var placeholder: String {
        formatter.exampleNumber(for: country) ?? String(localized: "signup.phone.placeholder", bundle: .onsarj)
    }

    /// Ülke değişince girilen rakamlar yeni ülkenin biçimine göre yeniden biçimlenir.
    func select(_ country: PhoneCountry) {
        number = formatter.parse(number.nationalDigits, for: country)
    }
}
