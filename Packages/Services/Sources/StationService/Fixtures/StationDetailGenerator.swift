// Geçici veri (K-23): elle yazılmamış istasyonların detayı. Yalnızca Debug derlemesinde var.
#if DEBUG
import Foundation

/// Elle detayı yazılmamış istasyonlar (`dense` dahil) için detay alanlarını üretir. Tohum istasyon kimliğinden
/// türetilir: aynı istasyon her açılışta aynı detayı verir. Değerler örnektir. Çıktı, backend yanıtının detay
/// alanlarıyla aynı biçimde bir JSON nesnesidir; müsait soket sayısı istasyonun özetteki müsaitliğiyle uyumludur.
enum StationDetailGenerator {
    private static let powers: [Double] = [11, 22, 60, 120, 180, 300]
    private static let fastTypes = ["ccs2", "chademo", "nacs"]
    private static let amenities = ["food", "cafe", "restroom", "wifi", "shopping", "parking", "hotel", "playground"]
    private static let methods = ["contactless", "card", "app", "rfid"]

    /// - Parameters:
    ///   - station: İstasyonun özeti; kimlik tohum, müsaitlik soket sayıları için kullanılır.
    ///   - now: Şimdiki an; son başarılı şarj bundan üretilen dakika kadar öncedir.
    static func detailFields(for station: StationDTO, now: Date) -> [String: Any] {
        var random = SplitMix64(seeding: station.id ?? "")
        return [
            "address": "Örnek Sokak No: \(1 + random.next(below: 150)), Antalya",
            "timeZone": "Europe/Istanbul",
            "openingHours": openingHours(&random),
            "access": random.next(below: 6) == 0
                ? ["type": "restricted", "note": "Yalnızca müşterilere"] : ["type": "public"],
            "lastSuccessfulChargeAt": lastCharge(&random, now: now),
            "connectors": connectors(&random, availability: station.availability),
            "tariffs": tariffs(&random),
            "amenities": amenities.filter { _ in random.next(below: 3) == 0 },
            "rating": random.next(below: 3) == 0
                ? NSNull()
                : ["average": 3 + Double(random.next(below: 21)) / 10, "count": 1 + random.next(below: 60)],
        ]
    }

    private static func openingHours(_ random: inout SplitMix64) -> [String: Any] {
        guard random.next(below: 3) == 0 else { return ["alwaysOpen": true] }
        let days = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
        return [
            "alwaysOpen": false,
            "weekly": days.map { ["day": $0, "opens": "07:00", "closes": "23:00"] },
        ]
    }

    private static func lastCharge(_ random: inout SplitMix64, now: Date) -> Any {
        guard random.next(below: 4) != 0 else { return NSNull() }
        let minutes = 10 + random.next(below: 2_000)
        return now.addingTimeInterval(-Double(minutes) * 60).formatted(.iso8601)
    }

    private struct GeneratedGroup {
        let type: String
        let power: Double
        let total: Int
    }

    private static func connectors(_ random: inout SplitMix64, availability: String?) -> [[String: Any]] {
        let fastPower = powers[2 + random.next(below: 4)]
        // Kısmen dolu istasyonda ilk grupta en az iki soket olur: biri boş, biri dolu.
        let minimumTotal = availability == "partial" ? 2 : 1
        var groups = [
            GeneratedGroup(
                type: fastTypes[random.next(below: fastTypes.count)], power: fastPower,
                total: minimumTotal + random.next(below: 4))
        ]
        if random.next(below: 2) == 0 {
            groups.append(
                GeneratedGroup(type: "type2", power: powers[random.next(below: 2)], total: 1 + random.next(below: 4)))
        }
        return groups.enumerated()
            .map { index, group in
                [
                    "type": group.type, "maxPowerKw": group.power, "total": group.total,
                    "available": available(total: group.total, isFirst: index == 0, availability: availability),
                ]
            }
    }

    /// Özetteki müsaitlikle uyumlu boş soket sayısı. Kısmen dolu istasyonda ilk grup boş, diğerleri dolu.
    private static func available(total: Int, isFirst: Bool, availability: String?) -> Any {
        switch availability {
        case "available": total
        case "partial": isFirst ? max(1, total - 1) : 0
        case "unavailable": 0
        default: NSNull()
        }
    }

    private static func tariffs(_ random: inout SplitMix64) -> [[String: Any]] {
        guard random.next(below: 5) != 0 else { return [] }
        let price = 8 + random.next(below: 9)
        let cents = random.next(below: 100)
        return [
            [
                "name": "Doğrudan ödeme",
                "paymentMethods": methods.filter { _ in random.next(below: 2) == 0 },
                "pricePerKwh": String(format: "%d.%02d", price, cents),
                "pricePerMinute": NSNull(),
                "currency": "TRY",
            ]
        ]
    }
}
#endif
