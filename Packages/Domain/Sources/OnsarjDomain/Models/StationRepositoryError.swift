/// İstasyon deposunun hataları.
public enum StationRepositoryError: Error, Sendable, Equatable {
    /// Kimliği verilen istasyon yok.
    case stationNotFound
}
