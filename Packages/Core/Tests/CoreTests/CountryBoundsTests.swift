import Foundation
import LocationKit
import Testing

@Suite("CountryBounds")
struct CountryBoundsTests {
    @Test("Veri dosyası okunur ve yedek ülke tabloda bulunur")
    func fallbackCountryExists() {
        #expect(CountryBounds.forRegionCode(CountryBounds.fallbackRegionCode) != nil)
    }

    @Test("Cihazın bölgesindeki ülke seçilir")
    func usesLocaleRegion() {
        let bounds = CountryBounds.forRegion(of: Locale(identifier: "de_DE"))

        #expect(bounds == CountryBounds.forRegionCode("DE"))
    }

    @Test("Bölgesi olmayan veya tabloda bulunmayan bölge yedek ülkeye düşer", arguments: ["en", "en_150"])
    func fallsBackToTurkey(identifier: String) {
        let bounds = CountryBounds.forRegion(of: Locale(identifier: identifier))

        #expect(bounds == CountryBounds.forRegionCode("TR"))
    }

    @Test("Türkiye'nin kutusu Edirne'den Iğdır'a uzanır")
    func turkeyBoundsAreSensible() throws {
        let turkey = try #require(CountryBounds.forRegionCode("TR"))

        #expect(turkey.west < 26.6 && turkey.east > 44.7)
        #expect(turkey.south < 36 && turkey.north > 42)
    }

    @Test("Denizaşırı topraklar kutuya girmez: Fransa yalnızca Avrupa'dadır")
    func franceExcludesOverseasTerritories() throws {
        let france = try #require(CountryBounds.forRegionCode("FR"))

        #expect(france.west > -10 && france.south > 40)
    }

    @Test("Hiçbir kutu 180. boylamı geçmez")
    func noBoundsCrossAntimeridian() {
        let codes = ["RU", "FJ", "NZ", "US", "KI"]
        for code in codes {
            guard let bounds = CountryBounds.forRegionCode(code) else { continue }
            #expect(bounds.west <= bounds.east, "\(code)")
        }
    }
}
