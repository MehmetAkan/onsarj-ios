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
///
/// **Detay.** Özet alanları (`StationDTO`) ile detay alanları tek JSON nesnesinde birleştirilir ve gerçek yanıt
/// gibi `StationDetailDTO` → `StationDetailMapper` yolundan geçer. Detay alanları elle yazılmış beş istasyon için
/// `FixtureStationDetailJSON`'dan, diğerleri için `StationDetailGenerator`'dan gelir.
public actor FixtureStationRepository: StationRepository {
    private let scenario: FixtureStationScenario
    private let resourceLookup: @Sendable (String) -> URL?
    private let now: @Sendable () -> Date
    private var loaded: [Station]?
    private var summaries: [String: StationDTO] = [:]

    /// - Parameters:
    ///   - scenario: Denenecek yoğunluk.
    ///   - resourceLookup: Logo adını yerel dosya adresine çevirir; çözemezse `nil`.
    ///   - now: Şimdiki an; fixture tarihleri buna göre kaydırılır.
    public init(
        scenario: FixtureStationScenario = .default,
        resourceLookup: @escaping @Sendable (String) -> URL? = { _ in nil },
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.scenario = scenario
        self.resourceLookup = resourceLookup
        self.now = now
    }

    public func stations(in box: GeoBoundingBox) async throws -> [Station] {
        try all().filter { box.contains($0.coordinate) }
    }

    /// Tüm istasyonlar; ilk istekte bir kez çözülür.
    func all() throws -> [Station] {
        if let loaded { return loaded }
        var list = try response()
        list.stations = list.stations.map(resolvingLogo)
        summaries = Dictionary(list.stations.compactMap { dto in dto.id.map { ($0, dto) } }) { first, _ in first }
        let stations = try StationMapper.stations(from: list, acceptsFileLogoURLs: true)
        loaded = stations
        return stations
    }

    public func stationDetail(_ id: Station.ID) async throws -> StationDetail {
        _ = try all()
        guard let summary = summaries[id.rawValue] else { throw StationRepositoryError.stationNotFound }
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(summary)) as? [String: Any] ?? [:]
        object.merge(try detailFields(for: summary)) { _, detail in detail }
        let data = try JSONSerialization.data(withJSONObject: object)
        let dto = try JSONDecoder().decode(StationDetailDTO.self, from: data)
        return try StationDetailMapper.detail(from: dto, acceptsFileLogoURLs: true)
    }

    /// Elle yazılmış detay varsa o (tarihleri şimdiye kaydırılmış), yoksa üretilen detay.
    private func detailFields(for summary: StationDTO) throws -> [String: Any] {
        let handwritten = try JSONSerialization.jsonObject(with: Data(FixtureStationDetailJSON.details.utf8))
        guard let id = summary.id, var fields = (handwritten as? [String: Any])?[id] as? [String: Any] else {
            return StationDetailGenerator.detailFields(for: summary, now: now())
        }
        if let stored = fields["lastSuccessfulChargeAt"] as? String {
            fields["lastSuccessfulChargeAt"] = shifted(stored)
        }
        return fields
    }

    /// Bağlantı anına (`anchor`) göre yazılmış tarihi, aradaki fark korunarak şimdiye taşır.
    private func shifted(_ stored: String) -> String {
        guard let date = try? Date(stored, strategy: .iso8601),
            let anchor = try? Date(FixtureStationDetailJSON.anchor, strategy: .iso8601)
        else { return stored }
        return now().addingTimeInterval(date.timeIntervalSince(anchor)).formatted(.iso8601)
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
