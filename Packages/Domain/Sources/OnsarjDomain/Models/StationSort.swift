/// Yakındaki istasyonlar listesinin sıralaması. Ham değer backend sözleşmesindeki dizgedir (`sort`).
public enum StationSort: String, Sendable, Hashable, CaseIterable {
    /// Yakından uzağa (varsayılan).
    case distance
    /// Güçlüden zayıfa; eşitlikte yakından uzağa.
    case power
    /// Boş soketi olanlar önce; her grup kendi içinde yakından uzağa.
    case availability

    /// `lhs`'in `rhs`'ten önce gelip gelmediği. Tüm ölçütler eşitse kimliğe göre sıralanır; sonuç her
    /// çağrıda aynıdır.
    public func areInIncreasingOrder(_ lhs: StationListItem, _ rhs: StationListItem) -> Bool {
        switch self {
        case .distance:
            break
        case .power:
            if lhs.maxPowerKw != rhs.maxPowerKw { return lhs.maxPowerKw > rhs.maxPowerKw }
        case .availability:
            let lhsFree = Self.hasFreeStall(lhs)
            let rhsFree = Self.hasFreeStall(rhs)
            if lhsFree != rhsFree { return lhsFree }
        }
        let lhsDistance = lhs.distanceKm ?? .infinity
        let rhsDistance = rhs.distanceKm ?? .infinity
        if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
        return lhs.id.rawValue < rhs.id.rawValue
    }

    private static func hasFreeStall(_ item: StationListItem) -> Bool {
        (item.availableCount ?? 0) > 0
    }
}
