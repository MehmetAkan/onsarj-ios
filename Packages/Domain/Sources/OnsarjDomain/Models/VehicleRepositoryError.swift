/// Araç deposunun yazma işlemlerinin hataları. Backend'in hata yanıtları bunlara eşlenir.
public enum VehicleRepositoryError: Error, Sendable, Equatable {
    /// Geçersiz değer taşıyan alan.
    public enum Field: Sendable, Equatable {
        case profileName
        case consumption
        case maxSpeed
        case batteryHealth
        case colorHex
    }

    case vehicleNotFound
    case profileNotFound
    case invalidValue(Field)
    case duplicateProfileName
    case cannotDeleteStandardProfile
    case atLeastOneConnectorRequired
}
