/// Bir şarj istasyonu: haritada pin olarak görünen en küçük birim.
///
/// Şimdilik haritanın ihtiyacı kadar alan taşır. Konnektörler, güç ve fiyat istasyon detayı
/// ekranıyla birlikte eklenecek.
public struct Station: Sendable, Hashable, Identifiable {
    /// İstasyonun tip güvenli kimliği.
    public struct ID: Sendable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    /// Kullanıcıya gösterilen ad.
    public let name: String
    /// İstasyonu işleten şarj ağı.
    public let network: ChargingNetwork
    public let coordinate: GeoCoordinate
    public let availability: StationAvailability

    public init(
        id: ID,
        name: String,
        network: ChargingNetwork,
        coordinate: GeoCoordinate,
        availability: StationAvailability
    ) {
        self.id = id
        self.name = name
        self.network = network
        self.coordinate = coordinate
        self.availability = availability
    }
}
