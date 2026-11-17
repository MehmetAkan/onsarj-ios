import OnsarjDomain

/// Haritaya eklenen istasyon görsellerinin adları. Ad, görseli yeniden çizmek için gereken her şeyi taşır;
/// harita eksik bir görsel istediğinde (`StationImageFactory`) addan çözülür.
enum StationImageKey: Hashable {
    case pin(network: ChargingNetwork.ID, availability: StationAvailability, isSelected: Bool)
    case cluster(label: String)

    private static let pinPrefix = "onsarj-pin"
    /// Küme görsel adlarının ön eki; küme katmanı adı bu ön ek ve sayı yazısıyla kurar.
    static let clusterPrefix = "onsarj-cluster."
    private static let separator: Character = "|"

    var name: String {
        switch self {
        case .pin(let network, let availability, let isSelected):
            [Self.pinPrefix, network.rawValue, availability.rawValue, isSelected ? "1" : "0"]
                .joined(separator: String(Self.separator))
        case .cluster(let label):
            Self.clusterPrefix + label
        }
    }

    init?(name: String) {
        if name.hasPrefix(Self.clusterPrefix) {
            self = .cluster(label: String(name.dropFirst(Self.clusterPrefix.count)))
            return
        }
        let parts = name.split(separator: Self.separator, omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4, parts[0] == Self.pinPrefix,
            let availability = StationAvailability(rawValue: parts[2])
        else { return nil }
        self = .pin(network: ChargingNetwork.ID(parts[1]), availability: availability, isSelected: parts[3] == "1")
    }
}
