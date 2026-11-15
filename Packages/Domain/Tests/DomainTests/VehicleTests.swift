import Testing

@testable import OnsarjDomain

@Suite("Vehicle")
struct VehicleTests {
    private static func vehicle(id: String, rangeKm: Int = 393, isDefault: Bool = false) -> Vehicle {
        Vehicle(
            id: Vehicle.ID(id),
            make: "BYD",
            model: "Dolphin",
            variant: "Standart",
            modelYear: 2023,
            nickname: "Beyaz",
            batteryCapacityKwh: 60.5,
            rangeKm: rangeKm,
            consumptionWhPerKm: 178,
            connectors: [.type2, .ccs2],
            maxAcPowerKw: 11,
            maxDcPowerKw: 88,
            colorHex: "#F2F2F2",
            bodyType: .hatchback,
            imageURL: nil,
            batteryHealthPercent: 95,
            isDefault: isDefault
        )
    }

    @Test("Görünen ad marka ve modeldir; takma ad karışmaz")
    func displayName() {
        #expect(Self.vehicle(id: "a").displayName == "BYD Dolphin")
    }

    @Test("Tahmini menzil en yakın tam sayıya yuvarlanır", arguments: [(30, 118), (0, 0), (100, 393)])
    func estimatedRange(percent: Int, expected: Int) {
        let vehicle = Self.vehicle(id: "a", rangeKm: 393)
        #expect(vehicle.estimatedRangeKm(at: BatteryLevel(percent: percent)) == expected)
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
