/// Kullanıcının rota planlama tercihleri. Araca değil kullanıcıya aittir.
///
/// **Değişmez:** bir ağ aynı anda hem tercih edilen hem kaçınılan olamaz ve hiçbir listede iki kez
/// bulunmaz. Ağ listeleri yalnızca bu tipin yöntemleriyle değişir; yöntemler değişmezi korur.
///
/// Saklama biçimi servis katmanındadır; tip bilerek `Codable` değildir.
public struct RoutePreferences: Sendable, Equatable {
    /// Hiçbir tercih yapılmamış hal.
    public static let `default` = RoutePreferences()

    public var chargeStops: ChargeStopStrategy
    public private(set) var avoid: Set<RouteAvoidance>
    /// Ekleme sırasıyla.
    public private(set) var preferredNetworks: [ChargingNetwork.ID]
    /// Ekleme sırasıyla.
    public private(set) var avoidedNetworks: [ChargingNetwork.ID]

    /// Listeler değişmeze göre düzeltilir: tekrar eden kayıtlardan ilki kalır; iki listede birden
    /// geçen ağ yalnızca tercih edilenlerde kalır.
    public init(
        chargeStops: ChargeStopStrategy = .optimal,
        avoid: Set<RouteAvoidance> = [],
        preferredNetworks: [ChargingNetwork.ID] = [],
        avoidedNetworks: [ChargingNetwork.ID] = []
    ) {
        self.chargeStops = chargeStops
        self.avoid = avoid
        var seen = Set<ChargingNetwork.ID>()
        self.preferredNetworks = preferredNetworks.filter { seen.insert($0).inserted }
        self.avoidedNetworks = avoidedNetworks.filter { seen.insert($0).inserted }
    }

    /// Ağı tercih edilenlerin sonuna ekler ve kaçınılanlardan çıkarır. Zaten tercih ediliyorsa
    /// değişiklik yapmaz.
    public mutating func prefer(_ networkID: ChargingNetwork.ID) {
        guard !isPreferred(networkID) else { return }
        avoidedNetworks.removeAll { $0 == networkID }
        preferredNetworks.append(networkID)
    }

    /// Ağı kaçınılanların sonuna ekler ve tercih edilenlerden çıkarır. Zaten kaçınılıyorsa
    /// değişiklik yapmaz.
    public mutating func avoid(_ networkID: ChargingNetwork.ID) {
        guard !isAvoided(networkID) else { return }
        preferredNetworks.removeAll { $0 == networkID }
        avoidedNetworks.append(networkID)
    }

    /// Ağı hangi listedeyse oradan çıkarır.
    public mutating func remove(_ networkID: ChargingNetwork.ID) {
        preferredNetworks.removeAll { $0 == networkID }
        avoidedNetworks.removeAll { $0 == networkID }
    }

    /// Yol türünden kaçınmayı açar veya kapatır.
    public mutating func toggle(_ avoidance: RouteAvoidance) {
        if avoid.contains(avoidance) {
            avoid.remove(avoidance)
        } else {
            avoid.insert(avoidance)
        }
    }

    public func isPreferred(_ networkID: ChargingNetwork.ID) -> Bool {
        preferredNetworks.contains(networkID)
    }

    public func isAvoided(_ networkID: ChargingNetwork.ID) -> Bool {
        avoidedNetworks.contains(networkID)
    }
}
