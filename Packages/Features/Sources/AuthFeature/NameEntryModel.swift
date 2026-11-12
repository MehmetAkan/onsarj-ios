import Foundation
import Observation

/// Ad ve soyad ekranının durumu: girilen iki alan ve geçerlilikleri.
///
/// Doğrulama bilerek gevşektir. Karakter süzülmez: isimlerde kesme işareti, tire ve boşluk
/// bulunabilir; katı bir kural geçerli isimleri reddeder.
@MainActor
@Observable
final class NameEntryModel {
    /// Bir alanın, boşluklar kırpıldıktan sonraki en az uzunluğu.
    static let minLength = 2

    /// Bir alanın en fazla uzunluğu. Fazlası alana girmez.
    static let maxLength = 50

    /// Girilen ad, yazıldığı gibi; en fazla `maxLength` karakter.
    private(set) var firstName: String

    /// Girilen soyad, yazıldığı gibi; en fazla `maxLength` karakter.
    private(set) var lastName: String

    init(firstName: String = "", lastName: String = "") {
        self.firstName = Self.limited(firstName)
        self.lastName = Self.limited(lastName)
    }

    func updateFirstName(_ value: String) {
        firstName = Self.limited(value)
    }

    func updateLastName(_ value: String) {
        lastName = Self.limited(value)
    }

    /// İki alan da geçerliyse kırpılmış değerler; değilse `nil`.
    var validName: (firstName: String, lastName: String)? {
        let first = Self.trimmed(firstName)
        let last = Self.trimmed(lastName)
        guard Self.isValid(first), Self.isValid(last) else { return nil }
        return (first, last)
    }

    var canContinue: Bool {
        validName != nil
    }

    private static func limited(_ value: String) -> String {
        String(value.prefix(maxLength))
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Kırpılmış değer en az `minLength` karakterdir ve en az bir harf içerir.
    private static func isValid(_ trimmed: String) -> Bool {
        trimmed.count >= minLength && trimmed.contains(where: \.isLetter)
    }
}
