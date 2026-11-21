/// Haritada dikdörtgen bir bölge: güneybatı ve kuzeydoğu köşeleri.
///
/// 180. boylamı geçen kutu desteklenmez (`southWest.longitude <= northEast.longitude`); uygulamanın
/// hizmet bölgesi bu sınırdan uzaktır.
public struct GeoBoundingBox: Sendable, Hashable {
    public let southWest: GeoCoordinate
    public let northEast: GeoCoordinate

    public init(southWest: GeoCoordinate, northEast: GeoCoordinate) {
        self.southWest = southWest
        self.northEast = northEast
    }

    /// Kutunun boylam genişliği, derece.
    public var longitudeSpan: Double {
        northEast.longitude - southWest.longitude
    }

    /// Kutunun enlem yüksekliği, derece.
    public var latitudeSpan: Double {
        northEast.latitude - southWest.latitude
    }

    /// Nokta kutunun içinde veya sınırında mı. Köşeleri ters verilmiş (geçersiz) kutu hiçbir noktayı
    /// içermez; aralık kurulmadığı için çökmez.
    public func contains(_ coordinate: GeoCoordinate) -> Bool {
        southWest.latitude <= coordinate.latitude && coordinate.latitude <= northEast.latitude
            && southWest.longitude <= coordinate.longitude && coordinate.longitude <= northEast.longitude
    }

    /// Diğer kutu tamamen bu kutunun içinde mi.
    public func contains(_ other: GeoBoundingBox) -> Bool {
        contains(other.southWest) && contains(other.northEast)
    }

    /// Merkezi aynı kalarak her kenarı `factor` katına büyütülmüş kutu; enlem ±90, boylam ±180 ile sınırlanır.
    public func scaled(by factor: Double) -> GeoBoundingBox {
        let halfLatitude = latitudeSpan * factor / 2
        let halfLongitude = longitudeSpan * factor / 2
        let centerLatitude = (southWest.latitude + northEast.latitude) / 2
        let centerLongitude = (southWest.longitude + northEast.longitude) / 2
        return GeoBoundingBox(
            southWest: GeoCoordinate(
                latitude: max(-90, centerLatitude - halfLatitude),
                longitude: max(-180, centerLongitude - halfLongitude)
            ),
            northEast: GeoCoordinate(
                latitude: min(90, centerLatitude + halfLatitude),
                longitude: min(180, centerLongitude + halfLongitude)
            )
        )
    }
}
