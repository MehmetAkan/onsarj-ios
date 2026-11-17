/// Şarj ağı listesi yanıtı: `{"networks": [ ... ]}`.
struct ChargingNetworkListDTO: Decodable {
    let networks: [ChargingNetworkDTO]
}

/// Backend'in şarj ağı kaydı, JSON'daki haliyle. Alanlar isteğe bağlı çözülür; eksik alan
/// eşlemede (`ChargingNetworkMapper`) yakalanır.
struct ChargingNetworkDTO: Decodable {
    let id: String?
    let name: String?
    /// Logo adresi (`https`); yoksa `null`.
    let logoUrl: String?
}
