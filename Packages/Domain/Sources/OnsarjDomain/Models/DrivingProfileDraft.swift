import Foundation

/// Yeni veya düzenlenen sürüş profilinin istek hali.
public struct DrivingProfileDraft: Sendable, Equatable {
    /// Düzenlenen profil; yeni profilde `nil`.
    public let id: DrivingProfile.ID?
    public let name: String
    public let consumptionKwhPer100Km: Double
    public let maxSpeedKmh: Int

    /// Ad kırpılır, tüketim bir ondalığa yuvarlanır.
    public init(id: DrivingProfile.ID?, name: String, consumptionKwhPer100Km: Double, maxSpeedKmh: Int) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.consumptionKwhPer100Km = DrivingProfile.roundedConsumption(consumptionKwhPer100Km)
        self.maxSpeedKmh = maxSpeedKmh
    }

    /// Taslağın aracın profillerine göre ilk hatası; geçerliyse `nil`.
    ///
    /// Düzenlenen profil yoksa `profileNotFound`; standart profilin adı değiştirilemez.
    public func validationError(among profiles: [DrivingProfile]) -> VehicleRepositoryError? {
        if let id {
            guard let existing = profiles.first(where: { $0.id == id }) else { return .profileNotFound }
            if existing.isStandard && existing.name != name { return .invalidValue(.profileName) }
        }
        switch DrivingProfile.nameIssue(name, among: profiles, editing: id) {
        case .empty, .tooLong: return .invalidValue(.profileName)
        case .duplicate: return .duplicateProfileName
        case nil: break
        }
        if !DrivingProfile.isValidConsumption(consumptionKwhPer100Km) { return .invalidValue(.consumption) }
        if !DrivingProfile.isValidMaxSpeed(maxSpeedKmh) { return .invalidValue(.maxSpeed) }
        return nil
    }
}
