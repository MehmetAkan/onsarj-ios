#if DEBUG
import Foundation
import OnsarjDomain

/// Önizleme için araç deposu. Yalnızca SwiftUI önizlemelerinde kullanılır (CLAUDE.md 2.3).
struct PreviewVehicleRepository: VehicleRepository {
    enum Content: Sendable {
        case vehicle(Vehicle)
        case noVehicles
        case failure
        /// Hiç yanıt vermez; kart yükleniyor halinde kalır.
        case pending
    }

    private struct PreviewFailure: Error {}

    let content: Content

    func vehicles() async throws -> [Vehicle] {
        switch content {
        case .vehicle(let vehicle):
            return [vehicle]
        case .noVehicles:
            return []
        case .failure:
            throw PreviewFailure()
        case .pending:
            try await Task.sleep(for: .seconds(TimeInterval(Int32.max)))
            return []
        }
    }

    /// Görselsiz örnek araç (görsel adresi backend'den gelir, K-24).
    static let dolphin = Vehicle(
        id: Vehicle.ID("preview_dolphin"),
        make: "BYD",
        model: "Dolphin",
        variant: "Standart",
        modelYear: 2023,
        nickname: nil,
        batteryCapacityKwh: 60.5,
        connectors: [.type2, .ccs2],
        maxAcPowerKw: 11,
        maxDcPowerKw: 88,
        // `colorHex` aracın boya verisidir, arayüz rengi değildir.
        colorHex: "#F2F2F2",  // swiftlint:disable:this no_hardcoded_hex_color
        bodyType: .hatchback,
        imageURL: nil,
        batteryHealthPercent: 95,
        isDefault: true,
        drivingProfiles: [
            DrivingProfile(
                id: DrivingProfile.ID("preview_standard"),
                name: "Standart",
                consumptionKwhPer100Km: 17.8,
                maxSpeedKmh: 120,
                isStandard: true
            )
        ],
        activeProfileID: DrivingProfile.ID("preview_standard")
    )

    // Kart yazma işlemi yapmaz; önizlemede çağrılmazlar.
    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func deleteVehicle(_ id: Vehicle.ID) async throws {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func addVehicle(variantID: VehicleVariant.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.variantNotFound
    }

    func setDefaultVehicle(_ id: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }
}

/// Önizleme için batarya deposu: verilen yüzdeyi kayıtlıymış gibi döner, kaydetmez.
struct PreviewBatteryLevelStore: BatteryLevelStoring {
    let percent: Int?

    func storedLevel(for vehicleID: Vehicle.ID) async -> StoredBatteryLevel? {
        percent.map { StoredBatteryLevel(level: BatteryLevel(percent: $0), recordedAt: .now) }
    }

    func save(_ level: BatteryLevel, for vehicleID: Vehicle.ID, at date: Date) async {}
}
#endif
