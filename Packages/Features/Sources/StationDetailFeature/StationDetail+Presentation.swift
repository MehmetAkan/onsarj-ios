import DesignSystem
import Foundation
import Localization
import OnsarjDomain
import SwiftUI

/// İstasyon detayındaki metinler ve biçimler. Sayılar, saatler ve fiyatlar verilen yerel ayarla biçimlenir.
enum StationDetailText {
    static func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .onsarj)
    }

    static func format(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: localized(key), locale: .current, arguments: arguments)
    }

    /// "160 kW"
    static func power(_ kilowatts: Double, locale: Locale) -> String {
        format("stationDetail.power", kilowatts.formatted(.number.precision(.fractionLength(0...1)).locale(locale)))
    }

    /// "Çok hızlı (160 kW)"
    static func speedAndPower(_ group: ConnectorGroup, locale: Locale) -> String {
        format(
            "stationDetail.connector.speedPower", localized(group.speed.nameKey),
            power(group.maxPowerKw, locale: locale))
    }

    /// "4/4" ya da canlı veri yoksa "–/4".
    static func ratio(available: Int?, total: Int) -> String {
        guard let available else { return format("stationDetail.availability.unknownRatio", total) }
        return format("stationDetail.availability.ratio", available, total)
    }

    /// "4 soketin 4 tanesi müsait"
    static func ratioAccessibility(available: Int?, total: Int) -> String {
        guard let available else { return format("stationDetail.availability.unknownAccessibility", total) }
        return format("stationDetail.availability.accessibility", available, total)
    }

    /// "₺14,98/kWh"
    static func price(_ amount: Decimal, currencyCode: String, perKey key: String, locale: Locale) -> String {
        format(key, amount.formatted(.currency(code: currencyCode).locale(locale)))
    }

    /// "24 saat açık", "Açık · Kapanış 22:00", "Kapalı · Açılış 08:00" ya da başka bir günse "Kapalı · Açılış
    /// Pzt 08:00". Saat istasyonun saat diliminde gösterilir.
    static func openingStatus(_ status: OpeningStatus, in hours: OpeningHours, now: Date, locale: Locale) -> String {
        switch status {
        case .alwaysOpen:
            return localized("stationDetail.hours.alwaysOpen")
        case .open(let closesAt):
            return format("stationDetail.hours.open", time(closesAt, hours: hours, now: now, locale: locale))
        case .closed(let opensAt?):
            return format("stationDetail.hours.closedOpens", time(opensAt, hours: hours, now: now, locale: locale))
        case .closed(nil):
            return localized("stationDetail.hours.closed")
        }
    }

    private static func time(_ date: Date, hours: OpeningHours, now: Date, locale: Locale) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = hours.timeZone
        var style = Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar)
        style.timeZone = hours.timeZone
        if calendar.isDate(date, inSameDayAs: now) || date.timeIntervalSince(now) < 12 * 3_600 {
            return date.formatted(style)
        }
        return date.formatted(style.weekday(.abbreviated))
    }

    /// "5 saat önce"
    static func relative(_ date: Date, now: Date, locale: Locale) -> String {
        date.formatted(.relative(presentation: .named, unitsStyle: .wide).locale(locale))
    }
}

extension ChargingSpeed {
    var nameKey: String {
        switch self {
        case .normal: "stationDetail.speed.normal"
        case .fast: "stationDetail.speed.fast"
        case .ultraFast: "stationDetail.speed.ultraFast"
        }
    }
}

extension StationAvailability {
    /// Haritadaki pinle aynı renk.
    var color: Color {
        switch self {
        case .available: Theme.availabilityAvailable
        case .partial: Theme.availabilityPartial
        case .unavailable: Theme.availabilityUnavailable
        case .unknown: Theme.availabilityUnknown
        }
    }
}

extension ConnectorType {
    /// Kısa ad ("CCS2", "Type 2"); çevrilmez.
    var nameKey: String { "common.connector.\(rawValue)" }

    var icon: AppIcon {
        switch self {
        case .type1: .connectorType1
        case .type2: .connectorType2
        case .ccs1: .connectorCCS1
        case .ccs2: .connectorCCS2
        case .chademo: .connectorCHAdeMO
        case .nacs: .connectorNACS
        }
    }
}

extension Amenity {
    var nameKey: String { "stationDetail.amenity.\(rawValue)" }

    var icon: AppIcon {
        switch self {
        case .food: .categoryRestaurant
        case .cafe: .categoryCafe
        case .restroom: .amenityRestroom
        case .wifi: .amenityWifi
        case .shopping: .categoryMarket
        case .parking: .amenityParking
        case .hotel: .categoryHotel
        case .playground: .amenityPlayground
        }
    }
}

extension PaymentMethod {
    var nameKey: String { "stationDetail.payment.\(rawValue)" }

    var icon: AppIcon {
        switch self {
        case .contactless: .paymentContactless
        case .card: .paymentCard
        case .app: .paymentApp
        case .rfid: .paymentRFID
        }
    }
}
