/// Yakındaki istasyonlar sorgusu: merkez, yarıçap, sıralama ve süzgeçler. Boş küme "hepsi" demektir.
public struct StationQuery: Sendable, Hashable {
    /// Varsayılan arama yarıçapı (km).
    public static let defaultRadiusKm: Double = 25
    /// Varsayılan en çok sonuç sayısı.
    public static let defaultLimit = 50

    /// Uzaklıkların ölçüldüğü merkez (kullanıcının konumu veya harita merkezi).
    public var origin: GeoCoordinate
    public var radiusKm: Double
    public var limit: Int
    public var sort: StationSort
    /// En düşük hız sınıfı; `nil` ise hepsi.
    public var minimumSpeed: ChargingSpeed?
    /// En az toplam soket sayısı; `nil` ise hepsi.
    public var minimumStalls: Int?
    /// Yalnızca bu ağlar; boşsa hepsi.
    public var networkIDs: Set<ChargingNetwork.ID>
    /// Yalnızca en az bir boş soketi olanlar.
    public var onlyAvailable: Bool
    /// Yalnızca bu türlerden en az bir soketi olanlar; boşsa hepsi.
    public var connectorTypes: Set<ConnectorType>

    public init(
        origin: GeoCoordinate,
        radiusKm: Double = Self.defaultRadiusKm,
        limit: Int = Self.defaultLimit,
        sort: StationSort = .distance,
        minimumSpeed: ChargingSpeed? = nil,
        minimumStalls: Int? = nil,
        networkIDs: Set<ChargingNetwork.ID> = [],
        onlyAvailable: Bool = false,
        connectorTypes: Set<ConnectorType> = []
    ) {
        self.origin = origin
        self.radiusKm = radiusKm
        self.limit = limit
        self.sort = sort
        self.minimumSpeed = minimumSpeed
        self.minimumStalls = minimumStalls
        self.networkIDs = networkIDs
        self.onlyAvailable = onlyAvailable
        self.connectorTypes = connectorTypes
    }

    /// İstasyon detayı sorgunun süzgeçlerinden ve yarıçapından geçiyor mu. Backend'in kuralıdır; fixture ve
    /// testler bunu kullanır.
    public func matches(_ detail: StationDetail, distanceKm: Double) -> Bool {
        guard distanceKm <= radiusKm, let speed = detail.speed else { return false }
        if let minimumSpeed, speed < minimumSpeed { return false }
        if let minimumStalls, detail.totalCount < minimumStalls { return false }
        if !networkIDs.isEmpty, !networkIDs.contains(detail.station.network.id) { return false }
        if onlyAvailable, (detail.availableCount ?? 0) == 0 { return false }
        if !connectorTypes.isEmpty, !detail.connectorGroups.contains(where: { connectorTypes.contains($0.type) }) {
            return false
        }
        return true
    }

    /// Öğeleri sorgunun sıralamasıyla dizer ve `limit` kadarını döner.
    public func arranged(_ items: [StationListItem]) -> [StationListItem] {
        Array(items.sorted(by: sort.areInIncreasingOrder).prefix(max(0, limit)))
    }
}
