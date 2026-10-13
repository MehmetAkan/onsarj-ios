import Foundation
import Testing

@testable import PhoneNumbers

@MainActor
@Suite("PhoneNumberFormatter")
struct PhoneNumberFormatterTests {
    private let formatter = PhoneNumberFormatter()

    private func country(_ regionCode: String) throws -> PhoneCountry {
        try #require(formatter.country(forRegionCode: regionCode))
    }

    @Test("Türkiye: baştaki 0 yok sayılır, iki giriş aynı E.164 sonucunu verir")
    func turkeyNationalPrefixIsIgnored() throws {
        let turkey = try country("TR")

        let withoutPrefix = formatter.parse("5537359394", for: turkey)
        let withPrefix = formatter.parse("05537359394", for: turkey)

        #expect(withoutPrefix.e164 == "+905537359394")
        #expect(withPrefix.e164 == "+905537359394")
        #expect(withPrefix.nationalDigits == "5537359394")
        #expect(withPrefix.formatted == "553 735 93 94")
    }

    @Test("Eksik numara geçersizdir")
    func incompleteNumberIsInvalid() throws {
        let parsed = formatter.parse("553735939", for: try country("TR"))

        #expect(!parsed.isValid)
        #expect(parsed.e164 == nil)
        #expect(parsed.formatted == "553 735 93 9")
    }

    @Test("Rakam dışı karakterler süzülür")
    func nonDigitCharactersAreFiltered() throws {
        let parsed = formatter.parse("(553) 735-93*94#abc", for: try country("TR"))

        #expect(parsed.nationalDigits == "5537359394")
        #expect(parsed.e164 == "+905537359394")
    }

    @Test("Ülkenin izin verdiğinden uzun kısım atılır")
    func excessDigitsAreDropped() throws {
        let parsed = formatter.parse("55373593941234", for: try country("TR"))

        #expect(parsed.nationalDigits == "5537359394")
    }

    @Test(
        "Ülkeye göre biçimlendirme",
        arguments: [
            ("DE", "015123456789", "1512 3456789", "+4915123456789"),
            ("GB", "07400123456", "7400 123456", "+447400123456"),
            ("US", "2015550123", "(201) 555-0123", "+12015550123"),
        ]
    )
    func formatsPerCountry(regionCode: String, input: String, formatted: String, e164: String) throws {
        let parsed = formatter.parse(input, for: try country(regionCode))

        #expect(parsed.formatted == formatted)
        #expect(parsed.e164 == e164)
    }

    @Test("Uluslararası girişte ülke koddan belirlenir")
    func internationalInputDeterminesCountry() throws {
        let parsed = formatter.parse("+44 7400 123456", for: try country("TR"))

        #expect(parsed.country.regionCode == "GB")
        #expect(parsed.e164 == "+447400123456")
    }

    @Test("Geçersiz bölge kodu çökme yaratmaz")
    func unknownRegionCodeIsHandled() {
        #expect(formatter.country(forRegionCode: "XX") == nil)
        #expect(formatter.country(forRegionCode: "") == nil)
    }

    @Test("Varsayılan ülke cihaz bölgesinden gelir, bölge yoksa Türkiye'dir")
    func defaultCountryFollowsLocale() {
        #expect(formatter.defaultCountry(for: Locale(identifier: "de_DE")).regionCode == "DE")
        #expect(formatter.defaultCountry(for: Locale(identifier: "en")).regionCode == "TR")
    }

    @Test("Ülke listesi dolu ve tekrarsız")
    func countryListIsComplete() {
        let codes = formatter.countries.map(\.regionCode)

        #expect(codes.count > 200)
        #expect(Set(codes).count == codes.count)
        #expect(codes.contains("TR"))
    }

    @Test("Bayrak bölge kodundan üretilir")
    func flagIsDerivedFromRegionCode() throws {
        #expect(try country("TR").flag == "🇹🇷")
        #expect(try country("TR").displayDialCode == "+90")
    }
}
