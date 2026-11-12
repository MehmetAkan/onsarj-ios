import CoreGraphics
import Foundation

/// Tek eksende, zamana bağlı hareket: duruş, yay, sade geçiş veya yavaşlama.
///
/// Değer her an kapalı formülle hesaplanır. Hareket sürerken sayfa yakalandığında o anki
/// değer bilinir; sayfa parmağın altında sıçramaz. SwiftUI animasyonlarının ara değeri
/// okunamadığı için bu yapı kullanıldı.
enum SheetMotion: Equatable {
    case resting(CGFloat)
    /// Kritik sönümlü yay: hedefi aşmadan, bırakma hızını koruyarak oturur.
    case spring(from: CGFloat, to: CGFloat, velocity: CGFloat, start: Date)
    /// "Hareketi Azalt" açıkken kullanılan kısa geçiş.
    case ease(from: CGFloat, to: CGFloat, start: Date)
    /// Kaydırma ataleti: üstel yavaşlama, aralığın kenarında durur.
    case decay(from: CGFloat, velocity: CGFloat, range: ClosedRange<CGFloat>, start: Date)

    /// Yayın tepki süresi (saniye).
    static let springResponse: Double = 0.35

    /// "Hareketi Azalt" açıkken geçiş süresi (saniye).
    static let reducedMotionDuration: Double = 0.2

    /// UIKit kaydırma görünümünün normal yavaşlama oranı (milisaniye başına).
    static let decelerationRate: Double = 0.998

    /// Hız (nokta/saniye) ile, o hızla bırakılan öğenin durana kadar alacağı yol arasındaki oran.
    static let decelerationDistancePerVelocity: CGFloat = decelerationRate / (1 - decelerationRate) / 1000

    /// Saniye başına üstel yavaşlama katsayısı.
    private static let decayCoefficient: Double = -log(decelerationRate) * 1000

    private static let springFrequency: Double = 2 * .pi / springResponse

    /// Hareketin bitmiş sayıldığı uzaklık (nokta) ve hız (nokta/saniye).
    private static let restDistance: CGFloat = 0.5
    private static let restVelocity: CGFloat = 4

    /// Hedefe oturma: yay ya da "Hareketi Azalt" açıksa sade geçiş.
    static func settle(
        from: CGFloat,
        to: CGFloat,
        velocity: CGFloat,
        start: Date,
        reduceMotion: Bool
    ) -> SheetMotion {
        reduceMotion
            ? .ease(from: from, to: to, start: start)
            : .spring(from: from, to: to, velocity: velocity, start: start)
    }

    /// Bırakılan içeriğin ataleti. Aralığın dışından bırakılırsa en yakın kenara oturur.
    static func momentum(
        from: CGFloat,
        velocity: CGFloat,
        range: ClosedRange<CGFloat>,
        start: Date,
        reduceMotion: Bool
    ) -> SheetMotion {
        guard range.contains(from) else {
            let edge = min(max(from, range.lowerBound), range.upperBound)
            return settle(from: from, to: edge, velocity: 0, start: start, reduceMotion: reduceMotion)
        }
        return .decay(from: from, velocity: velocity, range: range, start: start)
    }

    var isResting: Bool {
        if case .resting = self { return true }
        return false
    }

    func value(at date: Date) -> CGFloat {
        switch self {
        case .resting(let value):
            return value
        case .spring(let from, let to, let velocity, let start):
            let time = Self.elapsed(since: start, at: date)
            let omega = Self.springFrequency
            let offset = from - to
            return to + (offset + (velocity + omega * offset) * time) * exp(-omega * time)
        case .ease(let from, let to, let start):
            let progress = min(1, Self.elapsed(since: start, at: date) / Self.reducedMotionDuration)
            return from + (to - from) * (1 - pow(1 - progress, 3))
        case .decay(let from, let velocity, let range, let start):
            let time = Self.elapsed(since: start, at: date)
            let free = from + velocity / Self.decayCoefficient * (1 - exp(-Self.decayCoefficient * time))
            return min(max(free, range.lowerBound), range.upperBound)
        }
    }

    func velocity(at date: Date) -> CGFloat {
        switch self {
        case .resting:
            return 0
        case .spring(let from, let to, let velocity, let start):
            let time = Self.elapsed(since: start, at: date)
            let omega = Self.springFrequency
            return (velocity - omega * (velocity + omega * (from - to)) * time) * exp(-omega * time)
        case .ease(let from, let to, let start):
            let progress = min(1, Self.elapsed(since: start, at: date) / Self.reducedMotionDuration)
            return (to - from) * 3 * pow(1 - progress, 2) / Self.reducedMotionDuration
        case .decay(_, let velocity, _, let start):
            return velocity * exp(-Self.decayCoefficient * Self.elapsed(since: start, at: date))
        }
    }

    func isFinished(at date: Date) -> Bool {
        switch self {
        case .resting:
            return true
        case .spring(_, let to, _, _):
            return abs(value(at: date) - to) < Self.restDistance && abs(velocity(at: date)) < Self.restVelocity
        case .ease(_, _, let start):
            return Self.elapsed(since: start, at: date) >= Self.reducedMotionDuration
        case .decay(_, _, let range, _):
            let current = value(at: date)
            let atEdge = current <= range.lowerBound || current >= range.upperBound
            return atEdge || abs(velocity(at: date)) < Self.restVelocity
        }
    }

    private static func elapsed(since start: Date, at date: Date) -> Double {
        max(0, date.timeIntervalSince(start))
    }
}
