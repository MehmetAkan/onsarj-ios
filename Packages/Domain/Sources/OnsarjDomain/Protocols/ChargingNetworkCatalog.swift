/// Şarj ağlarının kataloğu.
public protocol ChargingNetworkCatalog: Sendable {
    /// Adı sorguyu içeren ağlar, ada göre sıralı. Boş sorgu tüm ağları verir.
    func networks(matching query: String) async throws -> [ChargingNetwork]

    /// Kimlikleri verilen ağlar, verilen sırayla. Katalogda bulunmayan kimlikler atlanır.
    func networks(withIDs ids: [ChargingNetwork.ID]) async throws -> [ChargingNetwork]
}
