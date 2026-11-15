import Foundation
import OnsarjDomain

/// Testlerin ortak araç verisi.
enum TestVehicles {
    static let standard = DrivingProfile(
        id: DrivingProfile.ID("std"), name: "Standart", consumptionKwhPer100Km: 17.8, maxSpeedKmh: 120, isStandard: true
    )
    static let highway = DrivingProfile(
        id: DrivingProfile.ID("hwy"), name: "Otoyol", consumptionKwhPer100Km: 20.5, maxSpeedKmh: 130, isStandard: false)

    static func dolphin(id: String = "veh_1", isDefault: Bool = true) -> Vehicle {
        Vehicle(
            id: Vehicle.ID(id),
            make: "BYD",
            model: "Dolphin",
            variant: "Standart",
            modelYear: 2023,
            nickname: nil,
            batteryCapacityKwh: 60.5,
            connectors: [.type2, .ccs2],
            maxAcPowerKw: 11,
            maxDcPowerKw: 88,
            colorHex: VehiclePaint.white.hex,
            bodyType: .hatchback,
            imageURL: nil,
            batteryHealthPercent: 95,
            isDefault: isDefault,
            drivingProfiles: [standard, highway],
            activeProfileID: standard.id
        )
    }
}

extension Vehicle {
    /// Aynı araç, verilen alanlar değişmiş.
    func with(
        nickname: String?? = nil,
        connectors: [ConnectorType]? = nil,
        colorHex: String? = nil,
        batteryHealthPercent: Int? = nil,
        drivingProfiles: [DrivingProfile]? = nil,
        activeProfileID: DrivingProfile.ID? = nil
    ) -> Vehicle {
        Vehicle(
            id: id,
            make: make,
            model: model,
            variant: variant,
            modelYear: modelYear,
            nickname: nickname ?? self.nickname,
            batteryCapacityKwh: batteryCapacityKwh,
            connectors: connectors ?? self.connectors,
            maxAcPowerKw: maxAcPowerKw,
            maxDcPowerKw: maxDcPowerKw,
            colorHex: colorHex ?? self.colorHex,
            bodyType: bodyType,
            imageURL: imageURL,
            batteryHealthPercent: batteryHealthPercent ?? self.batteryHealthPercent,
            isDefault: isDefault,
            drivingProfiles: drivingProfiles ?? self.drivingProfiles,
            activeProfileID: activeProfileID ?? self.activeProfileID
        )
    }
}

/// Bellekte çalışan araç deposu. Okuma sonucu ayarlanabilir; yazma işlemleri isteğe bağlı başarısız olur.
actor FakeVehicleRepository: VehicleRepository {
    enum Result {
        case success([Vehicle])
        case failure
    }

    struct Failure: Error {}

    private var result: Result
    private var failsWrites = false
    private(set) var callCount = 0
    private(set) var lastUpdate: VehicleUpdate?
    private(set) var lastDraft: DrivingProfileDraft?

    init(result: Result) {
        self.result = result
    }

    func setResult(_ result: Result) {
        self.result = result
    }

    func setFailsWrites(_ value: Bool) {
        failsWrites = value
    }

    func vehicles() async throws -> [Vehicle] {
        callCount += 1
        switch result {
        case .success(let vehicles): return vehicles
        case .failure: throw Failure()
        }
    }

    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle {
        lastUpdate = update
        return try replace(id) {
            $0.with(
                nickname: update.nickname.map { $0.isEmpty ? nil : $0 },
                connectors: update.connectors,
                colorHex: update.colorHex,
                batteryHealthPercent: update.batteryHealthPercent
            )
        }
    }

    func deleteVehicle(_ id: Vehicle.ID) async throws {
        if failsWrites { throw Failure() }
        guard case .success(let vehicles) = result else { throw Failure() }
        result = .success(vehicles.filter { $0.id != id })
    }

    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        lastDraft = draft
        return try replace(vehicleID) { vehicle in
            let profile = DrivingProfile(
                id: draft.id ?? DrivingProfile.ID("new_\(vehicle.drivingProfiles.count)"),
                name: draft.name,
                consumptionKwhPer100Km: draft.consumptionKwhPer100Km,
                maxSpeedKmh: draft.maxSpeedKmh,
                isStandard: vehicle.drivingProfiles.first { $0.id == draft.id }?.isStandard ?? false
            )
            let others = vehicle.drivingProfiles.filter { $0.id != profile.id }
            let profiles =
                draft.id == nil
                ? others + [profile] : vehicle.drivingProfiles.map { $0.id == profile.id ? profile : $0 }
            return vehicle.with(drivingProfiles: profiles)
        }
    }

    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        try replace(vehicleID) { $0.with(drivingProfiles: $0.drivingProfiles.filter { $0.id != id }) }
    }

    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        try replace(vehicleID) { $0.with(activeProfileID: id) }
    }

    private func replace(_ id: Vehicle.ID, _ change: (Vehicle) -> Vehicle) throws -> Vehicle {
        if failsWrites { throw Failure() }
        guard case .success(var vehicles) = result, let index = vehicles.firstIndex(where: { $0.id == id }) else {
            throw VehicleRepositoryError.vehicleNotFound
        }
        vehicles[index] = change(vehicles[index])
        result = .success(vehicles)
        return vehicles[index]
    }
}
