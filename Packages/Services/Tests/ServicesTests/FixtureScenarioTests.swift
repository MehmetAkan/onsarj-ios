#if DEBUG
import Foundation
import OnsarjDomain
import Testing
import os

@testable import VehicleService

@Suite("FixtureVehicleRepository senaryoları")
struct FixtureScenarioTests {
    private static let imageFile = URL(fileURLWithPath: "/tmp/onsarj-fixture/vehicle-empty-state.png")

    @Test("noVehicles: boş liste")
    func noVehicles() async throws {
        #expect(try await FixtureVehicleRepository(scenario: .noVehicles).vehicles().isEmpty)
    }

    @Test("failure: hata fırlatır")
    func failure() async {
        await #expect(throws: FixtureScenarioFailure.self) {
            try await FixtureVehicleRepository(scenario: .failure).vehicles()
        }
    }

    @Test("noImage: araç görselsiz yüklenir, görsel aranmaz")
    func noImage() async throws {
        let lookups = LookupRecorder()
        let repository = FixtureVehicleRepository(scenario: .noImage) { name in
            lookups.record(name)
            return Self.imageFile
        }
        let vehicle = try #require(try await repository.vehicles().first)
        #expect(vehicle.imageURL == nil)
        #expect(lookups.names.isEmpty)
    }

    @Test("default: görsel adı çözülürse imageURL o file:// adresidir")
    func defaultWithImage() async throws {
        let lookups = LookupRecorder()
        let repository = FixtureVehicleRepository(scenario: .default) { name in
            lookups.record(name)
            return Self.imageFile
        }
        let vehicle = try #require(try await repository.vehicles().first)
        #expect(vehicle.imageURL == Self.imageFile)
        #expect(lookups.names == ["vehicle-empty-state"])
    }

    @Test("default: görsel çözülemezse araç görselsiz yüklenir")
    func defaultWithoutImage() async throws {
        let repository = FixtureVehicleRepository(scenario: .default) { _ in nil }
        let vehicle = try #require(try await repository.vehicles().first)
        #expect(vehicle.imageURL == nil)
        #expect(vehicle.displayName == "BYD Dolphin")
    }

    @Test(
        "Senaryo değeri çözülür; tanınmayan veya eksik değer default",
        arguments: [
            ("noImage", FixtureScenario.noImage), ("noVehicles", .noVehicles), ("failure", .failure),
            ("default", .default), ("bilinmeyen", .default), ("", .default),
        ])
    func parsesValue(value: String, expected: FixtureScenario) {
        #expect(FixtureScenario(value: value) == expected)
    }

    @Test("Argüman yoksa default")
    func missingValueIsDefault() {
        #expect(FixtureScenario(value: nil) == .default)
    }
}

/// Kapanışın hangi adlarla çağrıldığını kaydeder. Kapanış `@Sendable` olduğu için kilitlidir.
private final class LookupRecorder: Sendable {
    private let storage = OSAllocatedUnfairLock<[String]>(initialState: [])

    var names: [String] { storage.withLock { $0 } }

    func record(_ name: String) {
        storage.withLock { $0.append(name) }
    }
}
#endif
