import Testing

@testable import OnsarjDomain

@Suite("Vehicle")
struct VehicleTests {
    static let standard = DrivingProfile(
        id: DrivingProfile.ID("std"),
        name: "Standart",
        consumptionKwhPer100Km: 17.8,
        maxSpeedKmh: 120,
        isStandard: true
    )
    static let highway = DrivingProfile(
        id: DrivingProfile.ID("hwy"),
        name: "Otoyol",
        consumptionKwhPer100Km: 20.5,
        maxSpeedKmh: 130,
        isStandard: false
    )

    static func vehicle(
        id: String = "a",
        health: Int = 95,
        isDefault: Bool = false,
        profiles: [DrivingProfile] = [standard, highway],
        active: DrivingProfile.ID = standard.id
    ) -> Vehicle {
        Vehicle(
            id: Vehicle.ID(id),
            make: "BYD",
            model: "Dolphin",
            variant: "Standart",
            modelYear: 2023,
            nickname: "Beyaz",
            batteryCapacityKwh: 60.5,
            connectors: [.type2, .ccs2],
            maxAcPowerKw: 11,
            maxDcPowerKw: 88,
            colorHex: "#F2F2F2",
            bodyType: .hatchback,
            imageURL: nil,
            batteryHealthPercent: health,
            isDefault: isDefault,
            drivingProfiles: profiles,
            activeProfileID: active
        )
    }

    @Test("Görünen ad marka ve modeldir; takma ad karışmaz")
    func displayName() {
        #expect(Self.vehicle().displayName == "BYD Dolphin")
    }

    @Test("Menzil: kapasite × sağlık × yüzde ÷ etkin tüketim", arguments: [(30, 97), (0, 0), (100, 323)])
    func estimatedRange(percent: Int, expected: Int) {
        #expect(Self.vehicle().estimatedRangeKm(at: BatteryLevel(percent: percent)) == expected)
    }

    @Test("Menzil sağlık ve etkin profil değişince değişir")
    func rangeDependsOnHealthAndProfile() {
        let level = BatteryLevel(percent: 30)
        // 60,5 × 1,00 × 0,30 ÷ 0,178 = 101,97
        #expect(Self.vehicle(health: 100).estimatedRangeKm(at: level) == 102)
        // 60,5 × 0,95 × 0,30 ÷ 0,205 = 84,11
        #expect(Self.vehicle(active: Self.highway.id).estimatedRangeKm(at: level) == 84)
    }

    @Test("Etkin profil kimliğiyle bulunur")
    func activeProfile() {
        #expect(Self.vehicle(active: Self.highway.id).activeProfile == Self.highway)
        #expect(Self.vehicle().standardProfile == Self.standard)
    }

    @Test("Etkin profil listede yoksa (silindiyse) standart profil etkindir")
    func missingActiveFallsBackToStandard() {
        let vehicle = Self.vehicle(profiles: [Self.standard], active: Self.highway.id)
        #expect(vehicle.activeProfileID == Self.standard.id)
        #expect(vehicle.activeProfile == Self.standard)
    }

    @Test("Batarya bozulması 100 − sağlık; sağlık aralığı bozulma aralığından türer")
    func degradation() {
        #expect(Self.vehicle(health: 95).batteryDegradationPercent == 5)
        #expect(Vehicle.batteryDegradationRange == 0...50)
        #expect(Vehicle.batteryHealthRange == 50...100)
    }

    @Test("Etkin araç: varsayılan olan öncelikli")
    func activeVehiclePrefersDefault() {
        let vehicles = [Self.vehicle(id: "a"), Self.vehicle(id: "b", isDefault: true)]
        #expect(Vehicle.activeVehicle(in: vehicles)?.id == Vehicle.ID("b"))
    }

    @Test("Etkin araç: varsayılan yoksa ilk araç")
    func activeVehicleFallsBackToFirst() {
        let vehicles = [Self.vehicle(id: "a"), Self.vehicle(id: "b")]
        #expect(Vehicle.activeVehicle(in: vehicles)?.id == Vehicle.ID("a"))
    }

    @Test("Etkin araç: boş listede nil")
    func activeVehicleEmpty() {
        #expect(Vehicle.activeVehicle(in: []) == nil)
    }
}
