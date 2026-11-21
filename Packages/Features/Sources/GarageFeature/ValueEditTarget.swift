import DesignSystem
import Foundation
import OnsarjDomain
import SwiftUI

/// Değer modalıyla düzenlenen alanlar.
enum ValueEditTarget: String, Identifiable, Hashable {
    /// Etkin profilin referans tüketimi.
    case consumption
    /// Etkin profilin en yüksek hızı.
    case maxSpeed
    /// Batarya bozulması (`100 − sağlık`).
    case batteryDegradation
    /// Takma ad; boş bırakmak kaldırır.
    case nickname

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .consumption: "vehicleSettings.consumption"
        case .maxSpeed: "vehicleSettings.maxSpeed"
        case .batteryDegradation: "vehicleSettings.batteryDegradation"
        case .nickname: "vehicleSettings.name"
        }
    }

    /// Alanın sağındaki birim; metinde yok.
    var unitKey: LocalizedStringKey? {
        switch self {
        case .consumption: "vehicleSettings.unit.consumption"
        case .maxSpeed: "vehicleSettings.unit.speed"
        case .batteryDegradation: "vehicleSettings.unit.percent"
        case .nickname: nil
        }
    }

    /// Düzenleyiciyi aracın güncel değeriyle kurar.
    func editor(for vehicle: Vehicle, locale: Locale) -> ValueEditor {
        switch self {
        case .consumption:
            ValueEditor.consumption(vehicle.activeProfile.consumptionKwhPer100Km, locale: locale)
        case .maxSpeed:
            ValueEditor.maxSpeed(vehicle.activeProfile.maxSpeedKmh, locale: locale)
        case .batteryDegradation:
            ValueEditor(
                kind: .integer(Vehicle.batteryDegradationRange),
                text: vehicle.batteryDegradationPercent.formatted(.number.locale(locale)),
                locale: locale
            )
        case .nickname:
            ValueEditor(kind: .text, text: vehicle.nickname ?? vehicle.displayName, locale: locale)
        }
    }
}

extension ValueEditor {
    static func consumption(_ value: Double, locale: Locale) -> ValueEditor {
        ValueEditor(
            kind: .decimal(DrivingProfile.consumptionRange),
            text: value.formatted(.number.precision(.fractionLength(1)).locale(locale)),
            locale: locale
        )
    }

    static func maxSpeed(_ value: Int, locale: Locale) -> ValueEditor {
        ValueEditor(
            kind: .integer(DrivingProfile.maxSpeedRange),
            text: value.formatted(.number.grouping(.never).locale(locale)),
            locale: locale
        )
    }
}
