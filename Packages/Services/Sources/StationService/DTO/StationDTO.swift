/// İstasyon listesi yanıtı: `{"stations": [ ... ]}`.
struct StationListDTO: Decodable {
    var stations: [StationDTO]
}

/// Backend'in istasyon kaydı, JSON'daki haliyle. Alanlar isteğe bağlı çözülür; eksik alan eşlemede
/// (`StationMapper`) yakalanır.
struct StationDTO: Decodable {
    let id: String?
    let name: String?
    var network: ChargingNetworkDTO?
    let coordinate: CoordinateDTO?
    /// `available | partial | unavailable | unknown`; tanınmayan değer `unknown` sayılır.
    let availability: String?
}

/// Enlem ve boylam, derece.
struct CoordinateDTO: Decodable {
    let latitude: Double?
    let longitude: Double?
}
