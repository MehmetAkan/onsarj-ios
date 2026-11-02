import Foundation

/// Bir ülkenin harita üzerindeki sınır kutusu, derece cinsinden.
///
/// Veri paketin içindeki `Resources/CountryBounds.json` dosyasından gelir (Natural Earth,
/// kamu malı; kaynak, sürüm ve hesaplama yöntemi dosyanın başında yazılıdır). İnternet
/// gerekmez (K-03). Kutu yalnızca ana karayı ve ona yakın büyük adaları kapsar; uzak
/// denizaşırı topraklar dışarıda kalır, çünkü amaç haritayı ülkenin üzerinde açmaktır.
///
/// Kutular 180. boylamı geçmez: her zaman `west <= east`.
public struct CountryBounds: Sendable, Equatable {
    public let west: Double
    public let south: Double
    public let east: Double
    public let north: Double

    /// Cihazın bölgesi belirlenemediğinde ya da tabloda bulunmadığında kullanılan ülke.
    ///
    /// Türkiye, uygulamanın ana pazarıdır. Ana pazar değişirse yalnızca bu satır değişir.
    /// Telefon numarası ekranındaki `PhoneNumberFormatter.fallbackRegionCode` ile aynı ülke
    /// olmalıdır; iki modül birbirine bağımlı olmadığı için değer iki yerde durur.
    public static let fallbackRegionCode = "TR"

    /// Cihazın bölge ayarındaki ülkenin kutusu; bulunamazsa `fallbackRegionCode` ülkesininki.
    ///
    /// `nil` yalnızca veri dosyası okunamazsa döner; bu durum testlerle korunur.
    public static func forRegion(of locale: Locale = .current) -> CountryBounds? {
        if let region = locale.region?.identifier, let bounds = forRegionCode(region) {
            return bounds
        }
        return forRegionCode(fallbackRegionCode)
    }

    /// ISO 3166-1 alfa-2 bölge kodunun (ör. `"TR"`) kutusu.
    public static func forRegionCode(_ regionCode: String) -> CountryBounds? {
        table[regionCode.uppercased()]
    }

    private static let table: [String: CountryBounds] = loadTable()

    private static func loadTable() -> [String: CountryBounds] {
        guard
            let url = Bundle.module.url(forResource: "CountryBounds", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(File.self, from: data)
        else {
            return [:]
        }
        return file.countries.compactMapValues { values in
            guard values.count == 4 else { return nil }
            return CountryBounds(west: values[0], south: values[1], east: values[2], north: values[3])
        }
    }

    /// Veri dosyasının biçimi. Kaynak bilgisi alanları yalnızca okuyan insan içindir.
    private struct File: Decodable {
        let countries: [String: [Double]]
    }
}
