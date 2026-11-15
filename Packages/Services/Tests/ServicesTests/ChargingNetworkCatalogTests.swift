import OnsarjDomain
import Testing

@testable import StationService

@Suite("FixtureChargingNetworkCatalog")
struct ChargingNetworkCatalogTests {
    private let catalog = FixtureChargingNetworkCatalog()

    @Test("Fixture JSON eşleme yolundan geçer ve yaklaşık 15 ağ içerir")
    func fixtureMaps() async throws {
        let all = try await catalog.networks(matching: "")
        #expect(all.count == 15)
        #expect(Set(all.map(\.id)).count == all.count)
    }

    @Test("Boş sorgu tüm listeyi Türkçe ad sırasıyla verir")
    func emptyQueryIsSorted() async throws {
        let names = try await catalog.networks(matching: "  ").map(\.name)
        #expect(names.first == "Aksa Şarj")
        #expect(names.last == "ZES")
        // Türkçe alfabede "E" < "En Yakıt" < "Eşarj": ş, s'den sonra gelir.
        let index = { (name: String) in names.firstIndex(of: name) ?? -1 }
        #expect(index("EDEKA") < index("En Yakıt"))
        #expect(index("En Yakıt") < index("Eşarj"))
        #expect(index("Sharz.net") < index("Tesla Supercharger"))
    }

    @Test("Arama büyük/küçük harf ve aksan duyarsız", arguments: ["eşarj", "ESARJ", "Esarj", "şarj"])
    func caseAndDiacriticInsensitive(query: String) async throws {
        let names = try await catalog.networks(matching: query).map(\.name)
        #expect(names.contains("Eşarj"))
    }

    @Test("Türkçe I/ı ve İ/i kuralları", arguments: ["YAKIT", "YAKİT", "yakıt", "yakit", "EN YAKIT"])
    func turkishDottedI(query: String) async throws {
        let names = try await catalog.networks(matching: query).map(\.name)
        #expect(names == ["En Yakıt"])
    }

    @Test("İçerir eşleşmesi: kelimenin ortası da bulunur")
    func containsMatch() async throws {
        let names = try await catalog.networks(matching: "charg").map(\.name)
        #expect(names == ["CHARGING TOGETHER SL", "Tesla Supercharger"])
    }

    @Test("withIDs verilen sırayı korur, bilinmeyeni atlar")
    func withIDsKeepsOrder() async throws {
        let ids = ["net_zes", "net_yok", "net_aksa", "net_trugo"].map(ChargingNetwork.ID.init)
        let names = try await catalog.networks(withIDs: ids).map(\.name)
        #expect(names == ["ZES", "Aksa Şarj", "Trugo"])
    }

    @Test("Eşleme: boş ad hata verir")
    func mapperRejectsEmptyName() {
        let list = ChargingNetworkListDTO(networks: [ChargingNetworkDTO(id: "x", name: "  ")])
        #expect(throws: ChargingNetworkMappingError.missingField(index: 0, field: "name")) {
            try ChargingNetworkMapper.networks(from: list)
        }
    }
}
