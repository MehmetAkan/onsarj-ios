import Foundation

/// Araç kataloğundaki bir marka.
public struct VehicleBrand: Sendable, Equatable, Hashable, Identifiable {
    public struct ID: Sendable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let name: String
    /// Marka logosu; backend'den gelir, yoksa `nil`.
    public let logoURL: URL?
    /// Markanın katalogdaki model sayısı.
    public let modelCount: Int

    public init(id: ID, name: String, logoURL: URL?, modelCount: Int) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
        self.modelCount = modelCount
    }
}

/// Bir markanın modeli, örneğin "Dolphin".
public struct VehicleModel: Sendable, Equatable, Hashable, Identifiable {
    public struct ID: Sendable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let brandID: VehicleBrand.ID
    public let name: String
    public let bodyType: BodyType

    public init(id: ID, brandID: VehicleBrand.ID, name: String, bodyType: BodyType) {
        self.id = id
        self.brandID = brandID
        self.name = name
        self.bodyType = bodyType
    }
}

/// Bir modelin donanım paketi ve teknik değerleri; araç bundan oluşturulur.
public struct VehicleVariant: Sendable, Equatable, Hashable, Identifiable {
    public struct ID: Sendable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let modelID: VehicleModel.ID
    /// Donanım paketi adı, örneğin "Comfort".
    public let name: String
    public let modelYear: Int
    public let batteryCapacityKwh: Double
    public let connectors: [ConnectorType]
    public let maxAcPowerKw: Double?
    public let maxDcPowerKw: Double?
    /// Yeni aracın standart profilinin tüketimi, kWh/100 km.
    public let referenceConsumptionKwhPer100Km: Double
    public let imageURL: URL?

    public init(
        id: ID,
        modelID: VehicleModel.ID,
        name: String,
        modelYear: Int,
        batteryCapacityKwh: Double,
        connectors: [ConnectorType],
        maxAcPowerKw: Double?,
        maxDcPowerKw: Double?,
        referenceConsumptionKwhPer100Km: Double,
        imageURL: URL?
    ) {
        self.id = id
        self.modelID = modelID
        self.name = name
        self.modelYear = modelYear
        self.batteryCapacityKwh = batteryCapacityKwh
        self.connectors = connectors
        self.maxAcPowerKw = maxAcPowerKw
        self.maxDcPowerKw = maxDcPowerKw
        self.referenceConsumptionKwhPer100Km = referenceConsumptionKwhPer100Km
        self.imageURL = imageURL
    }
}
