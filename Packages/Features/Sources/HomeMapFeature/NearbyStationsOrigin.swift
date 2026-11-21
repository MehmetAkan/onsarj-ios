import OnsarjDomain

/// Şimşek düğmesine dokunulduğu andaki konum bilgisi: yakındaki istasyonlar bunun etrafında aranır.
public struct NearbyStationsOrigin: Sendable, Equatable {
    /// Kullanıcının konumu; izin yoksa veya konum henüz bilinmiyorsa `nil`.
    public let userLocation: GeoCoordinate?
    /// Haritada görünen bölgenin merkezi.
    public let mapCenter: GeoCoordinate

    public init(userLocation: GeoCoordinate?, mapCenter: GeoCoordinate) {
        self.userLocation = userLocation
        self.mapCenter = mapCenter
    }
}
