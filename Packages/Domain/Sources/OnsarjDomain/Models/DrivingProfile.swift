import Foundation

/// Aracın bir sürüş profili: menzil ve planlamanın kullandığı tüketim ve hız varsayımları.
///
/// Her aracın tam olarak bir standart profili vardır; standart profil silinemez ve adı değişmez.
/// Geçerlilik sınırları yalnızca burada tanımlıdır; ekranlar ve fixture bunları kullanır.
public struct DrivingProfile: Sendable, Equatable, Hashable, Identifiable {
    /// Profilin tip güvenli kimliği.
    public struct ID: Sendable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Ad doğrulamasının sonucu.
    public enum NameIssue: Sendable, Equatable {
        case empty
        case tooLong
        case duplicate
    }

    /// Referans tüketimin geçerli aralığı, kWh/100 km.
    public static let consumptionRange: ClosedRange<Double> = 5.0...50.0
    /// Tahmini en yüksek hızın geçerli aralığı, km/h.
    public static let maxSpeedRange: ClosedRange<Int> = 50...250
    /// Profil adının en fazla karakter sayısı.
    public static let nameMaxLength = 40

    public let id: ID
    public let name: String
    /// Referans tüketim, kWh/100 km; bir ondalık.
    public let consumptionKwhPer100Km: Double
    /// Sürücünün yolculukta çıktığı tahmini en yüksek hız, km/h.
    public let maxSpeedKmh: Int
    public let isStandard: Bool

    public init(id: ID, name: String, consumptionKwhPer100Km: Double, maxSpeedKmh: Int, isStandard: Bool) {
        self.id = id
        self.name = name
        self.consumptionKwhPer100Km = Self.roundedConsumption(consumptionKwhPer100Km)
        self.maxSpeedKmh = maxSpeedKmh
        self.isStandard = isStandard
    }

    /// Tüketimi bir ondalığa yuvarlar.
    public static func roundedConsumption(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    public static func isValidConsumption(_ value: Double) -> Bool {
        consumptionRange.contains(roundedConsumption(value))
    }

    public static func isValidMaxSpeed(_ value: Int) -> Bool {
        maxSpeedRange.contains(value)
    }

    /// Adın sorunu; geçerliyse `nil`. Ad kırpılarak denetlenir. Benzersizlik aynı aracın diğer
    /// profillerine göre, büyük/küçük harf duyarsız (Türkçe `I/ı`, `İ/i` dahil) denetlenir.
    /// - Parameter editing: Düzenlenen profilin kimliği; kendi adıyla çakışmaz.
    public static func nameIssue(_ name: String, among profiles: [DrivingProfile], editing: ID?) -> NameIssue? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.count > nameMaxLength { return .tooLong }
        let key = comparisonKey(trimmed)
        let taken = profiles.contains { $0.id != editing && comparisonKey($0.name) == key }
        return taken ? .duplicate : nil
    }

    private static func comparisonKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
    }
}
