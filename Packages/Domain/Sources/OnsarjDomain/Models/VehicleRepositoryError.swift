/// Araç deposunun yazma işlemlerinin hataları. Backend'in hata yanıtları bunlara eşlenir.
public enum VehicleRepositoryError: Error, Sendable, Equatable {
    /// Geçersiz değer taşıyan alan.
    public enum Field: Sendable, Equatable {
        case profileName
        case consumption
        case maxSpeed
        case batteryHealth
        case colorHex
        /// Varsayılan araç isteği yalnızca `true` alır.
        case isDefault
    }

    case vehicleNotFound
    /// Eklenmek istenen varyant katalogda yok.
    case variantNotFound
    case profileNotFound
    case invalidValue(Field)
    case duplicateProfileName
    case cannotDeleteStandardProfile
    case atLeastOneConnectorRequired
}
