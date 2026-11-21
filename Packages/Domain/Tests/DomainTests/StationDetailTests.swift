import Foundation
import Testing

@testable import OnsarjDomain

@Suite("İstasyon detayı")
struct StationDetailTests {
    @Test(
        "Hız sınıfı eşikleri",
        arguments: [
            (49.9, ChargingSpeed.normal), (50, .fast), (149, .fast), (149.9, .fast), (150, .ultraFast), (22, .normal),
        ])
    func speedThresholds(power: Double, expected: ChargingSpeed) {
        #expect(ChargingSpeed(powerKw: power) == expected)
    }

    @Test(
        "Grup müsaitliği pin kuralıyla aynı",
        arguments: [
            (4, StationAvailability.available), (1, .partial), (0, .unavailable), (nil, .unknown),
        ] as [(Int?, StationAvailability)])
    func groupAvailability(available: Int?, expected: StationAvailability) {
        #expect(ConnectorGroup(type: .ccs2, maxPowerKw: 160, total: 4, available: available).availability == expected)
    }

    @Test("İstasyon toplamları, en yüksek güç ve hız")
    func totals() {
        let detail = Self.detail(groups: [
            ConnectorGroup(type: .ccs2, maxPowerKw: 160, total: 4, available: 3),
            ConnectorGroup(type: .type2, maxPowerKw: 22, total: 2, available: 0),
        ])
        #expect(detail.totalCount == 6)
        #expect(detail.availableCount == 3)
        #expect(detail.availability == .partial)
        #expect(detail.maxPowerKw == 160)
        #expect(detail.speed == .ultraFast)
    }

    @Test("Bir grubun canlı verisi yoksa toplam bilinmiyor")
    func unknownTotals() {
        let detail = Self.detail(groups: [
            ConnectorGroup(type: .ccs2, maxPowerKw: 60, total: 2, available: 2),
            ConnectorGroup(type: .chademo, maxPowerKw: 50, total: 1, available: nil),
        ])
        #expect(detail.availableCount == nil)
        #expect(detail.availability == .unknown)
    }

    static func detail(groups: [ConnectorGroup]) -> StationDetail {
        StationDetail(
            station: Station(
                id: Station.ID("st"), name: "S", network: ChargingNetwork(id: ChargingNetwork.ID("n"), name: "N"),
                coordinate: GeoCoordinate(latitude: 0, longitude: 0), availability: .unknown),
            address: "A",
            openingHours: OpeningHours(schedule: .alwaysOpen, timeZone: .gmt),
            access: .public,
            lastSuccessfulChargeAt: nil,
            connectorGroups: groups,
            tariffs: [],
            amenities: [],
            rating: nil
        )
    }
}

@Suite("Çalışma saatleri")
struct OpeningHoursTests {
    private let istanbul = TimeZone(identifier: "Europe/Istanbul") ?? .gmt

    /// İstanbul saatiyle bir an; 2026-11-16 pazartesidir.
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = istanbul
        let components = DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? .distantPast
    }

    private func time(_ hour: Int, _ minute: Int = 0) -> TimeOfDay {
        guard let time = TimeOfDay(hour: hour, minute: minute) else {
            preconditionFailure("Testteki saat geçersiz: \(hour):\(minute)")
        }
        return time
    }

    private func hours(_ intervals: [OpeningInterval]) -> OpeningHours {
        OpeningHours(schedule: .weekly(intervals), timeZone: istanbul)
    }

    @Test("24 saat açık")
    func alwaysOpen() {
        let hours = OpeningHours(schedule: .alwaysOpen, timeZone: istanbul)
        #expect(hours.status(at: date(16, 3)) == .alwaysOpen)
    }

    @Test("Gün içi aralık: açık, kapanmadan önce ve sonra")
    func daytime() {
        let weekdays = Weekday.allCases.map { OpeningInterval(day: $0, opens: time(8), closes: time(22)) }
        let hours = hours(weekdays)
        #expect(hours.status(at: date(16, 12)) == .open(closesAt: date(16, 22)))
        #expect(hours.status(at: date(16, 7, 59)) == .closed(opensAt: date(16, 8)))
        #expect(hours.status(at: date(16, 22)) == .closed(opensAt: date(17, 8)))
    }

    @Test("Gece yarısını geçen aralık: ertesi gün sabaha kadar açık")
    func overnight() {
        let hours = hours([OpeningInterval(day: .monday, opens: time(18), closes: time(2))])
        #expect(hours.status(at: date(16, 23)) == .open(closesAt: date(17, 2)))
        #expect(hours.status(at: date(17, 1, 30)) == .open(closesAt: date(17, 2)))
        #expect(hours.status(at: date(17, 3)) == .closed(opensAt: date(23, 18)))
    }

    @Test("Kapalı gün: bir sonraki açık güne kadar kapalı")
    func closedDay() {
        let hours = hours([
            OpeningInterval(day: .saturday, opens: time(9), closes: time(17)),
            OpeningInterval(day: .monday, opens: time(9), closes: time(17)),
        ])
        // 2026-11-22 pazar.
        #expect(hours.status(at: date(22, 12)) == .closed(opensAt: date(23, 9)))
        #expect(!hours.status(at: date(22, 12)).isOpen)
    }

    @Test("24:00 kapanış günün sonudur; geçersiz saat reddedilir")
    func timeOfDayBounds() {
        #expect(TimeOfDay(hour: 24, minute: 0)?.minutes == 1440)
        #expect(TimeOfDay(hour: 24, minute: 1) == nil)
        #expect(TimeOfDay(hour: 12, minute: 60) == nil)
        let hours = hours([OpeningInterval(day: .monday, opens: time(0), closes: time(24))])
        #expect(hours.status(at: date(16, 23, 59)) == .open(closesAt: date(17, 0)))
    }
}
