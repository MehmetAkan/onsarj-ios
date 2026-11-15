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
    /// Aracın sürüş profilleri; boş değildir ve tam olarak biri standarttır.
    public let drivingProfiles: [DrivingProfile]
    /// Etkin profilin kimliği; her zaman `drivingProfiles` içindedir.
    public let activeProfileID: DrivingProfile.ID

    /// Batarya bozulmasının (100 − sağlık) geçerli aralığı, yüzde.
    public static let batteryDegradationRange = 0...50
    /// Batarya sağlığının geçerli aralığı, yüzde; bozulma aralığından türetilir.
    public static let batteryHealthRange =
        (100 - batteryDegradationRange.upperBound)...(100 - batteryDegradationRange.lowerBound)

    public init(
        id: ID,
        make: String,
        model: String,
        variant: String?,
        modelYear: Int,
        nickname: String?,
        batteryCapacityKwh: Double,
        connectors: [ConnectorType],
        maxAcPowerKw: Double?,
        maxDcPowerKw: Double?,
        colorHex: String,
        bodyType: BodyType,
        imageURL: URL?,
        batteryHealthPercent: Int,
        isDefault: Bool,
        drivingProfiles: [DrivingProfile],
        activeProfileID: DrivingProfile.ID
    ) {
        precondition(
            drivingProfiles.filter(\.isStandard).count == 1,
            "Aracın tam olarak bir standart profili olmalı; eşleme bunu denetler."
        )
        self.id = id
        self.make = make
        self.model = model
        self.variant = variant
        self.modelYear = modelYear
        self.nickname = nickname
        self.batteryCapacityKwh = batteryCapacityKwh
        self.connectors = connectors
        self.maxAcPowerKw = maxAcPowerKw
        self.maxDcPowerKw = maxDcPowerKw
        self.colorHex = colorHex
        self.bodyType = bodyType
        self.imageURL = imageURL
        self.batteryHealthPercent = batteryHealthPercent
        self.isDefault = isDefault
        self.drivingProfiles = drivingProfiles
        // Etkin profil bilinmiyorsa (ör. silindiyse) standart profil etkindir.
        self.activeProfileID =
            drivingProfiles.contains { $0.id == activeProfileID }
            ? activeProfileID : Self.standardProfile(in: drivingProfiles).id
    }

    /// Marka ve model, örneğin "BYD Dolphin".
    public var displayName: String {
        "\(make) \(model)"
    }

    /// Etkin sürüş profili.
    public var activeProfile: DrivingProfile {
        drivingProfiles.first { $0.id == activeProfileID } ?? standardProfile
    }

    /// Standart sürüş profili.
    public var standardProfile: DrivingProfile {
        Self.standardProfile(in: drivingProfiles)
    }

    /// Batarya bozulması, yüzde: `100 − sağlık`.
    public var batteryDegradationPercent: Int {
        100 - batteryHealthPercent
    }

    /// Verilen batarya yüzdesiyle tahmini menzil, en yakın tam sayıya yuvarlanmış:
    /// `kapasite × sağlık/100 × yüzde/100 ÷ (etkin profilin tüketimi / 100)`.
    ///
    /// Saf hesaptır; kart çevrimdışıyken de anında güncellenir. Backend ileride sonucu kendisi
    /// verirse yalnızca bu işlev değişir.
    public func estimatedRangeKm(at level: BatteryLevel) -> Int {
        let usableKwh = batteryCapacityKwh * Double(batteryHealthPercent) / 100 * Double(level.percent) / 100
        let kwhPerKm = activeProfile.consumptionKwhPer100Km / 100
        guard kwhPerKm > 0 else { return 0 }
        return Int((usableKwh / kwhPerKm).rounded())
    }

    private static func standardProfile(in profiles: [DrivingProfile]) -> DrivingProfile {
        // `init` tam olarak bir standart profil olduğunu garanti eder.
        profiles.first(where: \.isStandard) ?? profiles[0]
    }

    /// Etkin araç: varsayılan olarak işaretlenen; yoksa listenin ilki; liste boşsa `nil`.
    public static func activeVehicle(in vehicles: [Vehicle]) -> Vehicle? {
        vehicles.first(where: \.isDefault) ?? vehicles.first
    }
}
