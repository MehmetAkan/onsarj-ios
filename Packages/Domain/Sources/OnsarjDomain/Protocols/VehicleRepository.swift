/// Kullanıcının araçlarının kaynağı.
///
/// Yazma işlemleri değişmiş aracın tamamını döner; ekran durumunu bununla günceller.
/// Hatalar `VehicleRepositoryError`'dır; ağ hataları ayrıca fırlatılabilir.
public protocol VehicleRepository: Sendable {
    /// Kullanıcının araçları. Kayıtlardan biri eşlenemezse hata fırlatır.
    func vehicles() async throws -> [Vehicle]

    /// Aracın dolu alanlarını değiştirir.
    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle

    /// Aracı siler. Silinen araç varsayılansa yeni varsayılanı backend seçer: kalan araçlardan en son
    /// eklenen. İstemci karar vermez.
    func deleteVehicle(_ id: Vehicle.ID) async throws

    /// Varyanttan yeni araç oluşturur. Standart profil varyantın referans tüketimi ve 120 km/h ile gelir,
    /// boya beyazdır; yeni araç varsayılan (etkin) olur. Aynı varyant birden çok kez eklenebilir.
    func addVehicle(variantID: VehicleVariant.ID) async throws -> Vehicle

    /// Aracı varsayılan (etkin) yapar; diğer araçlar varsayılan olmaktan çıkar.
    func setDefaultVehicle(_ id: Vehicle.ID) async throws -> Vehicle

    /// Taslağın kimliği yoksa yeni profil ekler, varsa o profili değiştirir.
    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle

    /// Standart olmayan profili siler; etkin profil silinirse standart profil etkin olur.
    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle

    /// Profili etkin yapar.
    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle
}
