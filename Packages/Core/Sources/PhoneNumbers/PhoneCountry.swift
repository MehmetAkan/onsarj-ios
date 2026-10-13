import Foundation

/// Telefon numarası girişinde seçilebilen bir ülke.
///
/// Ülke listesi ve kuralları `PhoneNumberFormatter`'dan gelir; bu tip yalnızca ülkeyi
/// tanımlar. Ekranlar ülke verisi tutmaz, bu tipin örneklerini kullanır.
public struct PhoneCountry: Hashable, Sendable, Identifiable {
    /// ISO 3166 bölge kodu: `"TR"`.
    public let regionCode: String

    /// Ülke telefon kodu, `+` işareti olmadan: `"90"`.
    public let dialCode: String

    public var id: String { regionCode }

    /// Ekranda gösterilen ülke kodu: `"+90"`.
    public var displayDialCode: String {
        "+" + dialCode
    }

    /// Ülke bayrağı. Bölge kodunun harflerinden Unicode bölge göstergesi olarak üretilir.
    public var flag: String {
        let base = UnicodeScalar("🇦").value - UnicodeScalar("A").value
        let scalars = regionCode.unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }
        return String(String.UnicodeScalarView(scalars))
    }

    /// Ülkenin verilen dildeki adı. Ad cihaz dilinden gelir, koda gömülmez.
    public func localizedName(in locale: Locale = .current) -> String {
        locale.localizedString(forRegionCode: regionCode) ?? regionCode
    }

    init(regionCode: String, dialCode: String) {
        self.regionCode = regionCode
        self.dialCode = dialCode
    }
}
