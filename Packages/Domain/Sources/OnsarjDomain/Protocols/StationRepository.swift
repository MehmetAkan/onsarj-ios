/// Şarj istasyonlarının kaynağı. Araç konnektörüne veya başka bir ölçüte göre süzme yapılmaz;
/// kutudaki tüm istasyonlar döner.
public protocol StationRepository: Sendable {
    /// Kutunun içindeki istasyonlar.
    func stations(in box: GeoBoundingBox) async throws -> [Station]
}
