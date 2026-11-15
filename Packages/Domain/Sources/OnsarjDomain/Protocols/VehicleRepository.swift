/// Kullanıcının araçlarının kaynağı.
public protocol VehicleRepository: Sendable {
    /// Kullanıcının araçları. Kayıtlardan biri eşlenemezse hata fırlatır.
    func vehicles() async throws -> [Vehicle]
}
