import DesignSystem
import Foundation
import Localization
import OnsarjDomain
import SwiftUI

/// Araç ayarlarındaki değerlerin yerel biçimli metinleri.
enum GarageText {
    /// "17,8 kWh/100 km"
    static func consumption(_ value: Double, locale: Locale) -> String {
        let number = value.formatted(.number.precision(.fractionLength(1)).locale(locale))
        return String.localizedStringWithFormat(
            String(localized: "vehicleSettings.consumptionValue", bundle: .onsarj), number)
    }

    /// "120 km/h"
    static func speed(_ value: Int, locale: Locale) -> String {
        let number = value.formatted(.number.grouping(.never).locale(locale))
        return String.localizedStringWithFormat(
            String(localized: "vehicleSettings.speedValue", bundle: .onsarj), number)
    }

    /// "%5,0"
    static func degradation(_ percent: Int, locale: Locale) -> String {
        (Double(percent) / 100).formatted(.percent.precision(.fractionLength(1)).locale(locale))
    }

    /// "17,8 kWh/100 km · 120 km/h"
    static func profileSummary(_ profile: DrivingProfile, locale: Locale) -> String {
        String.localizedStringWithFormat(
            String(localized: "drivingProfile.summary", bundle: .onsarj),
            consumption(profile.consumptionKwhPer100Km, locale: locale),
            speed(profile.maxSpeedKmh, locale: locale)
        )
    }

    /// "BYD Dolphin 2023 Standart": marka, model, yıl ve varsa donanım paketi.
    static func vehicleDescription(_ vehicle: Vehicle) -> String {
        [vehicle.make, vehicle.model, String(vehicle.modelYear), vehicle.variant]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    /// "Type 2, CCS2"
    static func connectors(_ connectors: [ConnectorType]) -> String {
        connectors.map(\.name).joined(separator: ", ")
    }

    /// Katalogdan, anahtarı çalışma zamanında belli olan metin.
    static func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .onsarj)
    }

    /// Hata satırı: "5 ile 50 arasında bir değer gir".
    static func rangeError(_ editor: ValueEditor) -> String? {
        guard editor.isOutOfRange, let bounds = editor.rangeBounds else { return nil }
        let format = String(localized: "vehicleSettings.error.range", bundle: .onsarj)
        return String.localizedStringWithFormat(format, bounds.lower, bounds.upper)
    }
}

extension ConnectorType {
    /// Kısa adın katalog anahtarı ("Type 2", "CCS2").
    var nameKey: String {
        "vehicleSettings.connector.\(rawValue)"
    }

    var name: String {
        GarageText.localized(nameKey)
    }
}

extension VehiclePaint {
    /// VoiceOver'ın okuduğu renk adı.
    var nameKey: LocalizedStringKey {
        switch self {
        case .black: "vehicleSettings.paint.black"
        case .gray: "vehicleSettings.paint.gray"
        case .white: "vehicleSettings.paint.white"
        case .blue: "vehicleSettings.paint.blue"
        case .red: "vehicleSettings.paint.red"
        case .orange: "vehicleSettings.paint.orange"
        case .yellow: "vehicleSettings.paint.yellow"
        case .green: "vehicleSettings.paint.green"
        }
    }

    /// Boyanın rengi. Hex aracın boya **verisidir** (Domain), arayüz rengi değildir; bu yüzden
    /// tasarım token'ı değil, veriden üretilen renktir.
    var color: Color {
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        let channel = { (shift: UInt32) in Double((value >> shift) & 0xFF) / 255 }
        return Color(red: channel(16), green: channel(8), blue: channel(0))
    }
}
