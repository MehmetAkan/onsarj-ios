import Observation

/// Telefon numarası giriş ekranının durumu: girilen rakamlar, biçimlendirme ve geçerlilik.
///
/// Numara yalnızca rakam olarak saklanır; parantez ve boşluklar gösterim sırasında
/// ülkenin gruplama kalıbına göre eklenir.
@MainActor
@Observable
final class PhoneEntryModel {
    let country: PhoneCountry

    /// Ülke kodu hariç, yalnızca rakamlardan oluşan ulusal numara.
    private(set) var digits: String

    init(country: PhoneCountry, digits: String = "") {
        self.country = country
        self.digits = ""
        updateNumber(from: digits)
    }

    /// Alanda görünen, biçimlendirilmiş numara.
    ///
    /// Her yazımda kullanıcının girdisi rakamlara indirgenip yeniden biçimlendirilir.
    /// Atama değer değişmese de gözlemcileri uyarır; böylece alan, kabul edilmeyen bir
    /// karakteri (fazladan rakam, harf) ekranda bırakmaz.
    var formattedNumber: String {
        get { format(digits) }
        set { updateNumber(from: newValue) }
    }

    /// Numara gönderilebilir mi: basamak sayısı tam ve ilk rakam ülkenin kuralına uygun.
    var isValid: Bool {
        guard digits.count == country.digitCount else { return false }
        guard let leadingDigit = country.leadingDigit else { return true }
        return digits.first == leadingDigit
    }

    /// Ülke kodu dahil, yalnızca rakamlardan oluşan tam numara: `"905537359394"`.
    var fullNumber: String {
        country.dialCode + digits
    }

    /// Kullanıcının girdisini rakamlara indirger.
    ///
    /// Otomatik doldurma veya yapıştırma ile gelen biçimler de kabul edilir:
    /// başta ülke kodu (`+90 553 …`) veya ulusal ön ek `0` (`0553 …`) varsa atılır.
    func updateNumber(from input: String) {
        var newDigits = input.filter { $0.isASCII && $0.isNumber }
        if newDigits.count > country.digitCount, newDigits.hasPrefix(country.dialCode) {
            newDigits.removeFirst(country.dialCode.count)
        }
        while newDigits.first == "0" {
            newDigits.removeFirst()
        }
        digits = String(newDigits.prefix(country.digitCount))
    }

    /// Rakamları gruplama kalıbına yerleştirir. Kalıptaki ayraçlar yalnızca arkasından
    /// bir rakam geliyorsa eklenir: `"5537"` → `"(553) 7"`.
    private func format(_ digits: String) -> String {
        var result = ""
        var remaining = digits[...]
        for symbol in country.groupingPattern {
            guard let next = remaining.first else { break }
            if symbol == PhoneCountry.digitPlaceholder {
                result.append(next)
                remaining = remaining.dropFirst()
            } else {
                result.append(symbol)
            }
        }
        return result
    }
}
