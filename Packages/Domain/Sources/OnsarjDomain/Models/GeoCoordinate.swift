/// Haritada bir nokta, derece cinsinden (WGS 84). CoreLocation'a bağlı değildir; Domain saf Swift kalır.
public struct GeoCoordinate: Sendable, Hashable {
    /// Enlem, -90...90.
    public let latitude: Double
    /// Boylam, -180...180.
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Enlem ve boylam geçerli aralıkta mı.
    public var isValid: Bool {
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
}
