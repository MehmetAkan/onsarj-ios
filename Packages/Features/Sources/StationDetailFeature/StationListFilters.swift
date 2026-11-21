import OnsarjDomain

/// Yakındaki istasyonlar listesinin süzgeçleri. Uygulama katmanı oturum boyunca bellekte tutar (kalıcı
/// saklanmaz); liste yeniden açılınca aynı süzgeçlerle başlar.
public struct StationListFilters: Sendable, Equatable {
    /// "Hız" çipindeki seçenekler: tümü, hızlı ve üstü, yalnızca çok hızlı.
    static let speedOptions: [ChargingSpeed?] = [nil, .fast, .ultraFast]
    /// "Soket" çipindeki seçenekler: tümü, 2+, 4+, 6+.
    static let stallOptions: [Int?] = [nil, 2, 4, 6]

    public var sort: StationSort = .distance
    /// En düşük hız sınıfı; `nil` ise tümü.
    public var minimumSpeed: ChargingSpeed?
    /// En az soket sayısı; `nil` ise tümü.
    public var minimumStalls: Int?
    /// Seçili ağlar; boşsa tümü.
    public var networkIDs: Set<ChargingNetwork.ID> = []
    /// Ek filtre: yalnızca boş soketi olanlar.
    public var onlyAvailable = false
    /// Ek filtre: yalnızca etkin aracın konnektörlerinden birine sahip olanlar.
    public var matchesVehicle = false

    public init() {}

    /// Ek filtrelerden (soldaki düğmenin sayfası) biri açık mı; düğmede nokta işareti çıkar.
    var hasExtraFilters: Bool { onlyAvailable || matchesVehicle }

    /// Süzgeçlerin sorgusu. `vehicleConnectors` etkin aracın konnektörleridir; araç yoksa (`nil`) "Aracımla
    /// uyumlu" açık olsa da konnektör süzgeci uygulanmaz.
    func query(origin: GeoCoordinate, vehicleConnectors: [ConnectorType]?) -> StationQuery {
        StationQuery(
            origin: origin,
            sort: sort,
            minimumSpeed: minimumSpeed,
            minimumStalls: minimumStalls,
            networkIDs: networkIDs,
            onlyAvailable: onlyAvailable,
            connectorTypes: matchesVehicle ? Set(vehicleConnectors ?? []) : []
        )
    }
}

/// Listenin merkezi: kullanıcının konumu ya da (konum yoksa) harita merkezi.
public enum StationListOrigin: Sendable, Equatable {
    case userLocation(GeoCoordinate)
    case mapCenter(GeoCoordinate)

    var coordinate: GeoCoordinate {
        switch self {
        case .userLocation(let coordinate), .mapCenter(let coordinate): coordinate
        }
    }

    /// Konum kapalı; listenin üstünde not gösterilir.
    var isMapCenter: Bool {
        if case .mapCenter = self { true } else { false }
    }
}
