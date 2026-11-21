// Geçici (K-26): backend'in araç uç noktalarını bellekte taklit eder; backend bağlanınca silinir.
#if DEBUG
import Foundation
import OnsarjDomain

/// Araç uç noktalarının bellekteki taklidi (`Docs/Backend/vehicles.md`).
///
/// İstek DTO'larını alır, backend'in yapacağı gibi doğrular (sınırlar Domain'deki sabitlerdir),
/// bellekteki DTO'ya uygular ve güncel araç DTO'sunu döner. Hatalar `VehicleRepositoryError`'dır.
/// Bir referans tipidir; tek örneği `FixtureVehicleRepository` aktörünün içinde yaşar.
///
/// `vehicles` ekleme sırasındadır: son eleman en son eklenen araçtır (gerçek backend oluşturma zamanını
/// kullanır).
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
        if request.isDefault == false { throw VehicleRepositoryError.invalidValue(.isDefault) }
        if let profileID = request.activeProfileId {
            guard vehicles[index].drivingProfiles?.contains(where: { $0.id == profileID }) == true else {
                throw VehicleRepositoryError.profileNotFound
            }
        }
        apply(request, connectors: connectors, at: index)
        return vehicles[index]
    }

    /// Doğrulanmış güncellemeyi uygular; yalnızca dolu alanlar değişir.
    private func apply(_ request: UpdateVehicleRequestDTO, connectors: [ConnectorType]?, at index: Int) {
        if let profileID = request.activeProfileId { vehicles[index].activeProfileId = profileID }
        if let nickname = request.nickname {
            let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            vehicles[index].nickname = trimmed.isEmpty ? nil : trimmed
        }
        if let connectors { vehicles[index].connectors = connectors.map(\.rawValue) }
        if let health = request.batteryHealthPercent { vehicles[index].batteryHealthPercent = health }
        if let colorHex = request.colorHex { vehicles[index].colorHex = colorHex.uppercased() }
        if request.isDefault == true { makeDefault(at: index) }
    }

    /// `DELETE /vehicles/{id}`: silinen araç varsayılansa kalan araçlardan en son eklenen varsayılan olur.
    func deleteVehicle(_ id: String) throws {
        let removed = vehicles.remove(at: try vehicleIndex(id))
        if removed.isDefault == true, !vehicles.isEmpty {
            makeDefault(at: vehicles.count - 1)
        }
    }

    /// `POST /vehicles`: aracı katalogdaki varyanttan oluşturur. Standart profil varyantın referans
    /// tüketimi ve `DrivingProfile.defaultMaxSpeedKmh` ile gelir; boya beyaz, batarya sağlığı %100;
    /// yeni araç varsayılan olur.
    func postVehicle(_ request: CreateVehicleRequestDTO, catalog: FixtureVehicleCatalog.Tables) throws -> VehicleDTO {
        guard let variant = catalog.variants.first(where: { $0.id == request.variantId }),
            let model = catalog.models.first(where: { $0.id == variant.modelId }),
            let brand = catalog.brands.first(where: { $0.id == model.brandId })
        else { throw VehicleRepositoryError.variantNotFound }
        vehicles.append(Self.vehicle(from: variant, model: model, brand: brand))
        makeDefault(at: vehicles.count - 1)
        return vehicles[vehicles.count - 1]
    }

    /// Varyanttan oluşan araç kaydı; tek, standart ve etkin bir profille.
    private static func vehicle(
        from variant: VehicleVariantDTO,
        model: VehicleModelDTO,
        brand: VehicleBrandDTO
    ) -> VehicleDTO {
        let suffix = UUID().uuidString.lowercased()
        let profileID = "prof_\(suffix)"
        return VehicleDTO(
            id: "veh_\(suffix)",
            make: brand.name,
            model: model.name,
            variant: variant.name,
            modelYear: variant.modelYear,
            nickname: nil,
            batteryCapacityKwh: variant.batteryCapacityKwh,
            connectors: variant.connectors,
            maxAcPowerKw: variant.maxAcPowerKw,
            maxDcPowerKw: variant.maxDcPowerKw,
            colorHex: VehiclePaint.white.hex,
            bodyType: model.bodyType,
            imageUrl: variant.imageUrl,
            batteryHealthPercent: 100,
            isDefault: false,
            drivingProfiles: [
                DrivingProfileDTO(
                    id: profileID,
                    name: standardProfileName,
                    consumptionKwhPer100Km: variant.referenceConsumptionKwhPer100Km,
                    maxSpeedKmh: DrivingProfile.defaultMaxSpeedKmh,
                    isStandard: true
                )
            ],
            activeProfileId: profileID
        )
    }
    /// Backend'in yeni araçta standart profile verdiği ad (veri; istemci metni değil).
    private static let standardProfileName = "Standart"

    /// Aracı varsayılan yapar, diğerlerini varsayılan olmaktan çıkarır.
    private func makeDefault(at index: Int) {
        for other in vehicles.indices {
            vehicles[other].isDefault = other == index
        }
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
