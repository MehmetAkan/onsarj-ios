/// Araçta değiştirilecek alanlar. Yalnızca dolu (`nil` olmayan) alanlar değişir.
public struct VehicleUpdate: Sendable, Equatable {
    /// Takma ad; boş dizge takma adı kaldırır.
    public var nickname: String?
    public var connectors: [ConnectorType]?
    public var batteryHealthPercent: Int?
    /// `#RRGGBB`.
    public var colorHex: String?

    public init(
        nickname: String? = nil,
        connectors: [ConnectorType]? = nil,
        batteryHealthPercent: Int? = nil,
        colorHex: String? = nil
    ) {
        self.nickname = nickname
        self.connectors = connectors
        self.batteryHealthPercent = batteryHealthPercent
        self.colorHex = colorHex
    }

    /// Güncellemenin ilk hatası; geçerliyse `nil`.
    public func validationError() -> VehicleRepositoryError? {
        if let connectors, connectors.isEmpty { return .atLeastOneConnectorRequired }
        if let batteryHealthPercent, !Vehicle.batteryHealthRange.contains(batteryHealthPercent) {
            return .invalidValue(.batteryHealth)
        }
        if let colorHex, !VehiclePaint.isValidHex(colorHex) { return .invalidValue(.colorHex) }
        return nil
    }
}
