/// Kullanıcının araçlarının kaynağı.
///
/// Yazma işlemleri değişmiş aracın tamamını döner; ekran durumunu bununla günceller.
/// Hatalar `VehicleRepositoryError`'dır; ağ hataları ayrıca fırlatılabilir.
public protocol VehicleRepository: Sendable {
    /// Kullanıcının araçları. Kayıtlardan biri eşlenemezse hata fırlatır.
    func vehicles() async throws -> [Vehicle]

    /// Aracın dolu alanlarını değiştirir.
    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle

    /// Aracı siler.
    func deleteVehicle(_ id: Vehicle.ID) async throws

    /// Taslağın kimliği yoksa yeni profil ekler, varsa o profili değiştirir.
    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle

    /// Standart olmayan profili siler; etkin profil silinirse standart profil etkin olur.
    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle

    /// Profili etkin yapar.
    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle
}
