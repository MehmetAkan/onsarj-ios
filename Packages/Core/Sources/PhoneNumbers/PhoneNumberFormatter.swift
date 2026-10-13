import Foundation
import PhoneNumberKit

/// Telefon numarası kurallarına tek erişim noktası.
///
/// PhoneNumberKit yalnızca bu dosyada import edilir (CLAUDE.md 5.3 kural 11, K-21).
/// Başka hiçbir modül kütüphanenin tiplerini görmez; `PhoneCountry` ve
/// `ParsedPhoneNumber` kullanır.
///
/// Kütüphanenin metadata'sı ağırdır; uygulama boyunca tek örnek oluşturulup paylaşılır.
/// Kütüphane tipleri `Sendable` olmadığı için sınıf ana aktöre bağlıdır.
@MainActor
public final class PhoneNumberFormatter {
    /// Cihazın bölgesi belirlenemediğinde kullanılan ülke.
    public static let fallbackRegionCode = "TR"

    private let utility = PhoneNumberUtility()

    /// Seçilebilir bütün ülkeler, verilen dildeki ada göre sıralı.
    public private(set) lazy var countries: [PhoneCountry] = makeCountries()

    public init() {}

    /// Bölge koduna karşılık gelen ülke. Kod tanınmıyorsa `nil`.
    public func country(forRegionCode regionCode: String) -> PhoneCountry? {
        let code = regionCode.uppercased()
        guard let dialCode = utility.countryCode(for: code) else { return nil }
        return PhoneCountry(regionCode: code, dialCode: String(dialCode))
    }

    /// Cihazın bölge ayarındaki ülke; belirlenemezse `fallbackRegionCode`.
    public func defaultCountry(for locale: Locale = .current) -> PhoneCountry {
        if let region = locale.region?.identifier, let country = country(forRegionCode: region) {
            return country
        }
        return PhoneCountry(
            regionCode: Self.fallbackRegionCode,
            dialCode: String(utility.countryCode(for: Self.fallbackRegionCode) ?? 0)
        )
    }

    /// Ulusal numaranın alabileceği en fazla basamak sayısı (cep telefonu).
    public func maximumLength(for country: PhoneCountry) -> Int {
        let lengths = utility.possiblePhoneNumberLengths(
            forCountry: country.regionCode,
            phoneNumberType: .mobile,
            lengthType: .national
        )
        return lengths.max() ?? Self.maximumE164Digits - country.dialCode.count
    }

    /// Kullanıcının girdisini çözümler.
    ///
    /// - Rakam dışı karakterler atılır.
    /// - Ulusal ön ek (Türkiye'de baştaki `0`) atılır.
    /// - Ülkenin izin verdiğinden uzun kısım atılır.
    /// - Girdi `+` ile başlıyorsa uluslararası numara olarak okunur; ülke koddan belirlenir.
    public func parse(_ input: String, for country: PhoneCountry) -> ParsedPhoneNumber {
        if let international = parseInternational(input) {
            return international
        }
        let digits = input.filter { $0.isASCII && $0.isNumber }
        let nationalDigits = partialFormatter(for: country).nationalNumber(from: digits)
        return makeParsedNumber(nationalDigits: nationalDigits, country: country)
    }

    /// Ülkenin örnek cep telefonu numarası, ekrandaki biçimiyle: `"501 234 56 78"`.
    public func exampleNumber(for country: PhoneCountry) -> String? {
        guard let example = utility.getExampleNumber(forCountry: country.regionCode, ofType: .mobile) else {
            return nil
        }
        let digits = (example.leadingZero ? "0" : "") + String(example.nationalNumber)
        return partialFormatter(for: country).formatPartial(digits)
    }

    // MARK: - Yardımcılar

    /// E.164 bir numaranın en fazla basamak sayısı, ülke kodu dahil.
    private static let maximumE164Digits = 15

    private func makeCountries() -> [PhoneCountry] {
        utility.allCountries()
            .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
            .compactMap(country(forRegionCode:))
            .sorted { $0.localizedName().localizedStandardCompare($1.localizedName()) == .orderedAscending }
    }

    /// Kütüphanenin kısmi biçimleyicisi iç durum taşır; her çağrıda yenisi oluşturulur.
    /// Ağır metadata `utility` içinde paylaşılır, oluşturma maliyeti düşüktür.
    private func partialFormatter(for country: PhoneCountry) -> PartialFormatter {
        PartialFormatter(
            utility: utility,
            defaultRegion: country.regionCode,
            withPrefix: false,
            maxDigits: maximumLength(for: country)
        )
    }

    private func parseInternational(_ input: String) -> ParsedPhoneNumber? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("+"),
            let number = try? utility.parse(trimmed, ignoreType: true, ignorePrefixValidation: true),
            let regionCode = utility.getRegionCode(of: number) ?? utility.mainCountry(forCode: number.countryCode),
            let country = country(forRegionCode: regionCode)
        else { return nil }
        let digits = (number.leadingZero ? "0" : "") + String(number.nationalNumber)
        return makeParsedNumber(nationalDigits: digits, country: country)
    }

    private func makeParsedNumber(nationalDigits: String, country: PhoneCountry) -> ParsedPhoneNumber {
        ParsedPhoneNumber(
            country: country,
            nationalDigits: nationalDigits,
            formatted: partialFormatter(for: country).formatPartial(nationalDigits),
            e164: e164(nationalDigits: nationalDigits, country: country)
        )
    }

    private func e164(nationalDigits: String, country: PhoneCountry) -> String? {
        guard !nationalDigits.isEmpty,
            let number = try? utility.parse(
                nationalDigits,
                withRegion: country.regionCode,
                ignoreType: true,
                ignorePrefixValidation: true
            )
        else { return nil }
        return utility.format(number, toType: .e164)
    }
}
