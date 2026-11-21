// Geçici veri (K-23): backend hazır olana kadar şarj ağları bu dosyadan gelir; backend
// bağlanınca dosya silinir. JSON, K-23 ek notu gereği kaynak dosyası değil dizge sabitidir.
#if DEBUG
import Foundation
import OnsarjCore
import OnsarjDomain

/// Şarj ağlarını gömülü JSON'dan veren katalog. Gerçek yanıtla aynı yoldan geçer:
/// `JSONDecoder` → `ChargingNetworkListDTO` → `ChargingNetworkMapper`.
///
/// Arama büyük/küçük harf ve aksan duyarsız, Türkçe kurallarıyla "içerir" eşleşmesidir
/// (`SearchText`, OnsarjCore). Sonuçlar Türkçe alfabe sırasıyla ada göre sıralanır.
public struct FixtureChargingNetworkCatalog: ChargingNetworkCatalog {
    public init() {}

    public func networks(matching query: String) async throws -> [ChargingNetwork] {
        let matches = try Self.all().filter { SearchText.matches($0.name, query: query) }
        let turkish = Locale(identifier: "tr_TR")
        return matches.sorted {
            $0.name.compare($1.name, options: [.caseInsensitive], locale: turkish) == .orderedAscending
        }
    }

    public func networks(withIDs ids: [ChargingNetwork.ID]) async throws -> [ChargingNetwork] {
        let byID = Dictionary(try Self.all().map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }

    private static func all() throws -> [ChargingNetwork] {
        let list = try JSONDecoder().decode(ChargingNetworkListDTO.self, from: Data(json.utf8))
        return try ChargingNetworkMapper.networks(from: list)
    }

    static let json = """
        {
          "networks": [
            { "id": "net_zes", "name": "ZES" },
            { "id": "net_trugo", "name": "Trugo" },
            { "id": "net_shell", "name": "Shell Recharge" },
            { "id": "net_esarj", "name": "Eşarj" },
            { "id": "net_voltrun", "name": "Voltrun" },
            { "id": "net_sharz", "name": "Sharz.net" },
            { "id": "net_astor", "name": "Astor Şarj" },
            { "id": "net_beefull", "name": "Beefull" },
            { "id": "net_tesla", "name": "Tesla Supercharger" },
            { "id": "net_enyakit", "name": "En Yakıt" },
            { "id": "net_otojet", "name": "Otojet" },
            { "id": "net_aksa", "name": "Aksa Şarj" },
            { "id": "net_totalenergies", "name": "TotalEnergies" },
            { "id": "net_charging_together", "name": "CHARGING TOGETHER SL" },
            { "id": "net_wccc", "name": "WCCC Edgbaston" },
            { "id": "net_edeka", "name": "EDEKA" }
          ]
        }
        """
}
#endif
