/// Şarj istasyonlarının kaynağı. Araç konnektörüne veya başka bir ölçüte göre süzme yapılmaz;
/// kutudaki tüm istasyonlar döner.
public protocol StationRepository: Sendable {
    /// Kutunun içindeki istasyonlar (haritadaki özet).
    func stations(in box: GeoBoundingBox) async throws -> [Station]

    /// Bir istasyonun detayı. İstasyon yoksa `StationRepositoryError.stationNotFound`.
    func stationDetail(_ id: Station.ID) async throws -> StationDetail
}
