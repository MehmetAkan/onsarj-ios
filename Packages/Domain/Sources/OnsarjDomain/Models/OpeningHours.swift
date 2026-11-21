import Foundation

/// İstasyonun çalışma saatleri. Saatler istasyonun yerel saatindedir (`timeZone`).
public struct OpeningHours: Sendable, Hashable {
    public enum Schedule: Sendable, Hashable {
        /// 24 saat açık.
        case alwaysOpen
        /// Haftalık aralıklar. Bir günde birden çok aralık olabilir; listede olmayan gün kapalıdır.
        case weekly([OpeningInterval])
    }

    public let schedule: Schedule
    /// İstasyonun saat dilimi (IANA).
    public let timeZone: TimeZone

    public init(schedule: Schedule, timeZone: TimeZone) {
        self.schedule = schedule
        self.timeZone = timeZone
    }

    /// Verilen andaki durum.
    public func status(at date: Date) -> OpeningStatus {
        guard case .weekly(let intervals) = schedule else { return .alwaysOpen }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: date)
        // Dünden başlanır: dün açılıp gece yarısını geçen aralık bugün sürüyor olabilir.
        var occurrences: [DateInterval] = []
        for offset in -1...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = Weekday(calendarWeekday: calendar.component(.weekday, from: day))
            for interval in intervals where interval.day == weekday {
                if let occurrence = interval.occurrence(on: day, calendar: calendar) {
                    occurrences.append(occurrence)
                }
            }
        }
        if let current = occurrences.filter({ $0.start <= date && date < $0.end }).max(by: { $0.end < $1.end }) {
            return .open(closesAt: current.end)
        }
        return .closed(opensAt: occurrences.map(\.start).filter { $0 > date }.min())
    }
}

/// Çalışma saatlerinin belli bir andaki durumu.
public enum OpeningStatus: Sendable, Hashable {
    case alwaysOpen
    /// Açık; kapanış anı.
    case open(closesAt: Date)
    /// Kapalı; bir sonraki açılış anı (önümüzdeki hafta içinde açılış yoksa `nil`).
    case closed(opensAt: Date?)

    public var isOpen: Bool {
        switch self {
        case .alwaysOpen, .open: true
        case .closed: false
        }
    }
}

/// Haftanın bir gününde açık olunan aralık. Kapanış açılıştan önceyse veya eşitse aralık gece yarısını geçer
/// (ör. 18:00–02:00). Kapanış `24:00` olabilir.
public struct OpeningInterval: Sendable, Hashable {
    public let day: Weekday
    public let opens: TimeOfDay
    public let closes: TimeOfDay

    public init(day: Weekday, opens: TimeOfDay, closes: TimeOfDay) {
        self.day = day
        self.opens = opens
        self.closes = closes
    }

    fileprivate func occurrence(on day: Date, calendar: Calendar) -> DateInterval? {
        guard let start = calendar.date(byAdding: .minute, value: opens.minutes, to: day),
            var end = calendar.date(byAdding: .minute, value: closes.minutes, to: day)
        else { return nil }
        if end <= start, let nextDay = calendar.date(byAdding: .day, value: 1, to: end) {
            end = nextDay
        }
        return DateInterval(start: start, end: end)
    }
}

/// Günün saati, dakika hassasiyetinde. `24:00` günün sonudur.
public struct TimeOfDay: Sendable, Hashable, Comparable {
    public let hour: Int
    public let minute: Int

    /// - Returns: Saat 0…24, dakika 0…59 değilse veya `24:xx` (xx > 0) ise `nil`.
    public init?(hour: Int, minute: Int) {
        guard (0...24).contains(hour), (0...59).contains(minute), hour < 24 || minute == 0 else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// Gün başından dakika.
    public var minutes: Int { hour * 60 + minute }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minutes < rhs.minutes
    }
}

/// Haftanın günü; ham değer backend sözleşmesindeki dizgedir.
public enum Weekday: String, Sendable, Hashable, CaseIterable {
    case monday = "mon"
    case tuesday = "tue"
    case wednesday = "wed"
    case thursday = "thu"
    case friday = "fri"
    case saturday = "sat"
    case sunday = "sun"

    /// `Calendar`'ın gün numarasından (1 = pazar … 7 = cumartesi).
    init(calendarWeekday: Int) {
        let ordered: [Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        self = ordered[(calendarWeekday - 1 + 7) % 7]
    }
}
