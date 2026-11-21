/// Şarj istasyonlarının kaynağı. Harita için kutudaki tüm istasyonlar süzülmeden döner; yakındaki
/// istasyonlar listesi sorgunun süzgeçleriyle gelir.
public protocol StationRepository: Sendable {
    /// Kutunun içindeki istasyonlar (haritadaki özet).
    func stations(in box: GeoBoundingBox) async throws -> [Station]

    /// Bir istasyonun detayı. İstasyon yoksa `StationRepositoryError.stationNotFound`.
    func stationDetail(_ id: Station.ID) async throws -> StationDetail

    /// Sorgunun merkezine yakın istasyonlar: süzülmüş, sıralanmış ve `limit` ile sınırlanmış.
    func nearbyStations(_ query: StationQuery) async throws -> [StationListItem]
}
