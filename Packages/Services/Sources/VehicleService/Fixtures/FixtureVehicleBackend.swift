// Geçici (K-26): backend'in araç uç noktalarını bellekte taklit eder; backend bağlanınca silinir.
#if DEBUG
import Foundation
import OnsarjDomain

/// Araç uç noktalarının bellekteki taklidi (`Docs/Backend/vehicles.md`).
///
/// İstek DTO'larını alır, backend'in yapacağı gibi doğrular (sınırlar Domain'deki sabitlerdir),
/// bellekteki DTO'ya uygular ve güncel araç DTO'sunu döner. Hatalar `VehicleRepositoryError`'dır.
/// Bir referans tipidir; tek örneği `FixtureVehicleRepository` aktörünün içinde yaşar.
final class FixtureVehicleBackend {
    private(set) var vehicles: [VehicleDTO]

    init(vehicles: [VehicleDTO]) {
        self.vehicles = vehicles
    }

    /// `PATCH /vehicles/{id}`
    func patchVehicle(_ id: String, _ request: UpdateVehicleRequestDTO) throws -> VehicleDTO {
        let index = try vehicleIndex(id)
        let connectors = request.connectors?.compactMap(ConnectorType.init(rawValue:))
        let update = VehicleUpdate(
            nickname: request.nickname,
            connectors: connectors,
            batteryHealthPercent: request.batteryHealthPercent,
            colorHex: request.colorHex
        )
        if let error = update.validationError() { throw error }
        if let profileID = request.activeProfileId {
            guard vehicles[index].drivingProfiles?.contains(where: { $0.id == profileID }) == true else {
                throw VehicleRepositoryError.profileNotFound
            }
            vehicles[index].activeProfileId = profileID
        }
        if let nickname = request.nickname {
            let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            vehicles[index].nickname = trimmed.isEmpty ? nil : trimmed
        }
        if let connectors { vehicles[index].connectors = connectors.map(\.rawValue) }
        if let health = request.batteryHealthPercent { vehicles[index].batteryHealthPercent = health }
        if let colorHex = request.colorHex { vehicles[index].colorHex = colorHex.uppercased() }
        return vehicles[index]
    }

    /// `DELETE /vehicles/{id}`
    func deleteVehicle(_ id: String) throws {
        vehicles.remove(at: try vehicleIndex(id))
    }

    /// `POST /vehicles/{id}/driving-profiles`: yeni kimlik üretir.
    func postProfile(_ vehicleID: String, _ request: DrivingProfileRequestDTO) throws -> VehicleDTO {
        let index = try vehicleIndex(vehicleID)
        try validate(request, profileID: nil, vehicleAt: index)
        let profile = DrivingProfileDTO(
            id: "prof_\(UUID().uuidString.lowercased())",
            name: request.name,
            consumptionKwhPer100Km: request.consumptionKwhPer100Km,
            maxSpeedKmh: request.maxSpeedKmh,
            isStandard: false
        )
        vehicles[index].drivingProfiles?.append(profile)
        return vehicles[index]
    }

    /// `PUT /vehicles/{id}/driving-profiles/{profileId}`
    func putProfile(_ vehicleID: String, profileID: String, _ request: DrivingProfileRequestDTO) throws -> VehicleDTO {
        let index = try vehicleIndex(vehicleID)
        try validate(request, profileID: profileID, vehicleAt: index)
        let profileIndex = try self.profileIndex(profileID, vehicleAt: index)
        vehicles[index].drivingProfiles?[profileIndex].name = request.name
        vehicles[index].drivingProfiles?[profileIndex].consumptionKwhPer100Km = request.consumptionKwhPer100Km
        vehicles[index].drivingProfiles?[profileIndex].maxSpeedKmh = request.maxSpeedKmh
        return vehicles[index]
    }

    /// `DELETE /vehicles/{id}/driving-profiles/{profileId}`: etkin profil silinirse standart etkin olur.
    func deleteProfile(_ vehicleID: String, profileID: String) throws -> VehicleDTO {
        let index = try vehicleIndex(vehicleID)
        let profileIndex = try self.profileIndex(profileID, vehicleAt: index)
        guard vehicles[index].drivingProfiles?[profileIndex].isStandard != true else {
            throw VehicleRepositoryError.cannotDeleteStandardProfile
        }
        vehicles[index].drivingProfiles?.remove(at: profileIndex)
        if vehicles[index].activeProfileId == profileID {
            vehicles[index].activeProfileId = vehicles[index].drivingProfiles?.first { $0.isStandard == true }?.id
        }
        return vehicles[index]
    }

    private func vehicleIndex(_ id: String) throws -> Int {
        guard let index = vehicles.firstIndex(where: { $0.id == id }) else {
            throw VehicleRepositoryError.vehicleNotFound
        }
        return index
    }

    private func profileIndex(_ id: String, vehicleAt index: Int) throws -> Int {
        guard let profileIndex = vehicles[index].drivingProfiles?.firstIndex(where: { $0.id == id }) else {
            throw VehicleRepositoryError.profileNotFound
        }
        return profileIndex
    }

    /// Doğrulama Domain'in kurallarıyla yapılır; bunun için mevcut kayıt eşlenir.
    private func validate(_ request: DrivingProfileRequestDTO, profileID: String?, vehicleAt index: Int) throws {
        let vehicle = try VehicleMapper.vehicle(from: vehicles[index], acceptsFileImageURLs: true)
        let draft = DrivingProfileDraft(
            id: profileID.map(DrivingProfile.ID.init),
            name: request.name,
            consumptionKwhPer100Km: request.consumptionKwhPer100Km,
            maxSpeedKmh: request.maxSpeedKmh
        )
        if let error = draft.validationError(among: vehicle.drivingProfiles) { throw error }
    }
}
#endif
