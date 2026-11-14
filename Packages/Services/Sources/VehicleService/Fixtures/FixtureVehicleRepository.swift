// Geçici veri (K-23): backend hazır olana kadar araç listesi bu dosyadan gelir; backend
// bağlanınca dosya silinir. JSON, K-23 ek notu gereği kaynak dosyası değil dizge sabitidir.
#if DEBUG
import Foundation
import OnsarjDomain

/// Araç listesini gömülü JSON'dan veren depo. Gerçek yanıtla aynı yoldan geçer:
/// `JSONDecoder` → `VehicleDTO` → `VehicleMapper`.
///
/// **Görsel.** JSON'daki `imageUrl` bir adres değil, görsel adıdır. Depo adı `resourceLookup` ile
/// yerel dosya adresine (`file://`) çevirir ve eşlemeden **önce** DTO'ya yazar; eşleme `file`
/// şemasını yalnızca buradan gelen çağrıda kabul eder (`acceptsFileImageURLs`). Ad çözülemezse
/// görsel `nil` olur ve araç görselsiz yüklenir.
///
/// **Senaryo.** `FixtureScenario` kartın hallerini kodu değiştirmeden denemeyi sağlar.
public struct FixtureVehicleRepository: VehicleRepository {
    private let scenario: FixtureScenario
    private let resourceLookup: @Sendable (String) -> URL?

    /// - Parameters:
    ///   - scenario: Denenecek hal.
    ///   - resourceLookup: Görsel adını yerel dosya adresine çevirir; çözemezse `nil`.
    public init(
        scenario: FixtureScenario = .default,
        resourceLookup: @escaping @Sendable (String) -> URL? = { _ in nil }
    ) {
        self.scenario = scenario
        self.resourceLookup = resourceLookup
    }

    public func vehicles() async throws -> [Vehicle] {
        switch scenario {
        case .noVehicles:
            return []
        case .failure:
            throw FixtureScenarioFailure()
        case .default, .noImage:
            var list = try JSONDecoder().decode(VehicleListDTO.self, from: Data(Self.json.utf8))
            for index in list.vehicles.indices {
                list.vehicles[index].imageUrl = imageAddress(for: list.vehicles[index].imageUrl)
            }
            return try VehicleMapper.vehicles(from: list, acceptsFileImageURLs: true)
        }
    }

    /// Görsel adını yerel dosya adresine çevirir; `noImage` senaryosunda görsel yoktur.
    private func imageAddress(for name: String?) -> String? {
        guard scenario != .noImage, let name else { return nil }
        return resourceLookup(name)?.absoluteString
    }

    // `colorHex` aracın boya verisidir, arayüz rengi değildir.
    // swiftlint:disable no_hardcoded_hex_color
    static let json = """
        {
          "vehicles": [
            {
              "id": "veh_fixture_01",
              "make": "BYD",
              "model": "Dolphin",
              "variant": "Standart",
              "modelYear": 2023,
              "nickname": null,
              "batteryCapacityKwh": 60.5,
              "rangeKm": 393,
              "consumptionWhPerKm": 178,
              "connectors": ["type2", "ccs2"],
              "maxAcPowerKw": 11,
              "maxDcPowerKw": 88,
              "colorHex": "#F2F2F2",
              "bodyType": "hatchback",
              "imageUrl": "vehicle-empty-state",
              "batteryHealthPercent": 95,
              "isDefault": true
            }
          ]
        }
        """
    // swiftlint:enable no_hardcoded_hex_color
}

/// `failure` senaryosunun bilerek fırlattığı hata: kartın hata halini denemek için.
struct FixtureScenarioFailure: Error {}
#endif
