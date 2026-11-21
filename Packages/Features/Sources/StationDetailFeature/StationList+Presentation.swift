import DesignSystem
import Foundation
import OnsarjDomain
import SwiftUI

/// Yakındaki istasyonlar listesindeki metinler ve biçimler.
enum StationListText {
    /// Metrenin yuvarlandığı basamak (850 m).
    static let meterRounding: Double = 10
    /// Bu uzaklığın altında kilometre bir ondalıkla, üstünde tam sayıyla yazılır.
    static let wholeKilometerThreshold: Double = 10

    /// "850 m", "1,2 km", "14 km"; `width: .wide` VoiceOver için ("1 kilometre"). Birim yerel ayarla değişmez.
    static func distance(
        _ kilometers: Double, width: Measurement<UnitLength>.FormatStyle.UnitWidth, locale: Locale
    )
        -> String
    {
        let meters = (kilometers * 1_000 / meterRounding).rounded() * meterRounding
        if meters < 1_000 {
            return Measurement(value: max(meters, meterRounding), unit: UnitLength.meters)
                .formatted(.measurement(width: width, usage: .asProvided).locale(locale))
        }
        let fraction = kilometers < wholeKilometerThreshold ? 0...1 : 0...0
        return Measurement(value: kilometers, unit: UnitLength.kilometers)
            .formatted(
                .measurement(
                    width: width, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(fraction))
                )
                .locale(locale))
    }

    /// Kartın VoiceOver etiketi: "Trugo, Kepez Moda Düğün Salonu, 1 kilometre, çok hızlı 160 kilovat, 4 soketin
    /// 4 tanesi müsait".
    static func cardAccessibility(_ item: StationListItem, locale: Locale) -> String {
        let power = Measurement(value: item.maxPowerKw, unit: UnitPower.kilowatts)
            .formatted(.measurement(width: .wide, usage: .asProvided).locale(locale))
        let speedPower = StationDetailText.format(
            "stationList.card.speedPower.accessibility",
            StationDetailText.localized(item.speed.nameKey).lowercased(with: locale), power)
        let ratio = StationDetailText.ratioAccessibility(available: item.availableCount, total: item.totalCount)
        guard let kilometers = item.distanceKm else {
            return StationDetailText.format(
                "stationList.card.accessibilityNoDistance", item.station.network.name, item.station.name, speedPower,
                ratio)
        }
        return StationDetailText.format(
            "stationList.card.accessibility", item.station.network.name, item.station.name,
            distance(kilometers, width: .wide, locale: locale), speedPower, ratio)
    }

    /// Çipin başlığı: varsayılanda adı ("Sırala"), değilse adı ve değeri ("Sırala: Güç").
    static func chipTitle(nameKey: String, selectedKey: String, value: String?) -> String {
        guard let value else { return StationDetailText.localized(nameKey) }
        return StationDetailText.format(selectedKey, value)
    }

    static func speedOption(_ speed: ChargingSpeed?) -> String {
        switch speed {
        case nil: StationDetailText.localized("common.all")
        case .normal?: StationDetailText.localized("stationDetail.speed.normal")
        case .fast?: StationDetailText.localized("stationList.speed.fastAndAbove")
        case .ultraFast?: StationDetailText.localized("stationList.speed.ultraFastOnly")
        }
    }

    static func stallOption(_ stalls: Int?) -> String {
        guard let stalls else { return StationDetailText.localized("common.all") }
        return StationDetailText.format("stationList.stalls.minimum", stalls)
    }
}

extension StationSort {
    var nameKey: String { "stationList.sort.\(rawValue)" }
}
