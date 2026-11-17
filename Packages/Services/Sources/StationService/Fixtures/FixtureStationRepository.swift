// Geçici veri (K-23, K-26): backend hazır olana kadar istasyonlar bu dosyadan gelir; backend
// bağlanınca dosya silinir.
#if DEBUG
import Foundation
import OnsarjDomain

/// İstasyonları gömülü JSON'dan veren depo. Gerçek yanıtla aynı yoldan geçer:
/// `JSONDecoder` → `StationListDTO` → `StationMapper`. Kutu dışındaki istasyonlar döndürülmez.
///
/// **Logo.** JSON'daki `logoUrl` bir adres değil, görsel adıdır; eşlemeden önce `resourceLookup` ile
/// yerel dosya adresine (`file://`) çevrilir. Çözülemeyen ad `null` olur ve pin şimşek gösterir.
///
/// **Senaryo.** `FixtureStationScenario.dense` kümeleme ve performans için 1000 istasyon üretir.
public actor FixtureStationRepository: StationRepository {
    private let scenario: FixtureStationScenario
    private let resourceLookup: @Sendable (String) -> URL?
    private var loaded: [Station]?

    /// - Parameters:
    ///   - scenario: Denenecek yoğunluk.
    ///   - resourceLookup: Logo adını yerel dosya adresine çevirir; çözemezse `nil`.
    public init(
        scenario: FixtureStationScenario = .default,
        resourceLookup: @escaping @Sendable (String) -> URL? = { _ in nil }
    ) {
        self.scenario = scenario
        self.resourceLookup = resourceLookup
    }

    public func stations(in box: GeoBoundingBox) async throws -> [Station] {
        try all().filter { box.contains($0.coordinate) }
    }

    /// Tüm istasyonlar; ilk istekte bir kez çözülür.
    func all() throws -> [Station] {
        if let loaded { return loaded }
        var list = try response()
        list.stations = list.stations.map(resolvingLogo)
        let stations = try StationMapper.stations(from: list, acceptsFileLogoURLs: true)
        loaded = stations
        return stations
    }

    private func response() throws -> StationListDTO {
        switch scenario {
        case .default:
            try JSONDecoder().decode(StationListDTO.self, from: Data(Self.handwrittenJSON.utf8))
        case .dense:
            DenseStationGenerator.response()
        }
    }

    private func resolvingLogo(_ station: StationDTO) -> StationDTO {
        guard let network = station.network else { return station }
        var resolved = station
        resolved.network = ChargingNetworkDTO(
            id: network.id,
            name: network.name,
            logoUrl: network.logoUrl.flatMap(resourceLookup)?.absoluteString
        )
        return resolved
    }
}
#endif
