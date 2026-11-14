import Foundation

/// Kullanıcının garajındaki bir elektrikli araç.
///
/// Araç kaydı ve görsel adresi backend'den gelir (K-24). `nickname` kullanıcının verdiği
/// addır ve `displayName`'e karışmaz.
public struct Vehicle: Sendable, Equatable, Hashable, Identifiable {
    /// Aracın tip güvenli kimliği.
    public struct ID: Sendable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    /// Marka, örneğin "BYD".
    public let make: String
    /// Model, örneğin "Dolphin".
    public let model: String
    /// Donanım paketi, örneğin "Standart".
    public let variant: String?
    public let modelYear: Int
    /// Kullanıcının araca verdiği ad.
    public let nickname: String?
    public let batteryCapacityKwh: Double
    /// %100 şarjda gerçekçi menzil.
    public let rangeKm: Int
    /// Referans tüketim.
    public let consumptionWhPerKm: Int
    public let connectors: [ConnectorType]
    public let maxAcPowerKw: Double?
    public let maxDcPowerKw: Double?
    /// Boya rengi, `#RRGGBB` biçiminde.
    public let colorHex: String
    public let bodyType: BodyType
    /// Aracın görseli; yoksa `nil`.
    public let imageURL: URL?
    /// Batarya sağlığı, 0…100.
    public let batteryHealthPercent: Int
    /// Kullanıcının varsayılan aracı mı.
    public let isDefault: Bool

    public init(
        id: ID,
        make: String,
        model: String,
        variant: String?,
        modelYear: Int,
        nickname: String?,
        batteryCapacityKwh: Double,
        rangeKm: Int,
        consumptionWhPerKm: Int,
        connectors: [ConnectorType],
        maxAcPowerKw: Double?,
        maxDcPowerKw: Double?,
        colorHex: String,
        bodyType: BodyType,
        imageURL: URL?,
        batteryHealthPercent: Int,
        isDefault: Bool
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.variant = variant
        self.modelYear = modelYear
        self.nickname = nickname
        self.batteryCapacityKwh = batteryCapacityKwh
        self.rangeKm = rangeKm
        self.consumptionWhPerKm = consumptionWhPerKm
        self.connectors = connectors
        self.maxAcPowerKw = maxAcPowerKw
        self.maxDcPowerKw = maxDcPowerKw
        self.colorHex = colorHex
        self.bodyType = bodyType
        self.imageURL = imageURL
        self.batteryHealthPercent = batteryHealthPercent
        self.isDefault = isDefault
    }

    /// Marka ve model, örneğin "BYD Dolphin".
    public var displayName: String {
        "\(make) \(model)"
    }

    /// Verilen batarya yüzdesiyle tahmini menzil: %100 menzilin o yüzdesi, en yakın tam
    /// sayıya yuvarlanmış.
    public func estimatedRangeKm(at level: BatteryLevel) -> Int {
        Int((Double(rangeKm) * Double(level.percent) / 100).rounded())
    }

    /// Etkin araç: varsayılan olarak işaretlenen; yoksa listenin ilki; liste boşsa `nil`.
    public static func activeVehicle(in vehicles: [Vehicle]) -> Vehicle? {
        vehicles.first(where: \.isDefault) ?? vehicles.first
    }
}
