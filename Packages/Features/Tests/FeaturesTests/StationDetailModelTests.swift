import Foundation
import OnsarjDomain
import Testing

@testable import StationDetailFeature

@MainActor
@Suite("StationDetailModel")
struct StationDetailModelTests {
    private let station = Station(
        id: Station.ID("st_001"),
        name: "Kepez Moda & Düğün Salonu",
        network: ChargingNetwork(id: ChargingNetwork.ID("net_trugo"), name: "Trugo"),
        coordinate: GeoCoordinate(latitude: 36.94, longitude: 30.71),
        availability: .available
    )

    private func detail(address: String = "2571. Sokak 4/2, Kepez") -> StationDetail {
        StationDetail(
            station: station, address: address,
            openingHours: OpeningHours(schedule: .alwaysOpen, timeZone: .gmt), access: .public,
            lastSuccessfulChargeAt: nil,
            connectorGroups: [ConnectorGroup(type: .ccs2, maxPowerKw: 160, total: 4, available: 4)],
            tariffs: [], amenities: [], rating: nil)
    }

    @Test("Yükleniyor halinde başlık pinden bilinen özetle hemen hazır; yükleme bitince detay gelir")
    func loadingShowsStationImmediately() async {
        let repository = ScriptedStationRepository(results: [.success(detail())])
        let model = StationDetailModel(station: station, repository: repository, copyToPasteboard: { _ in })
        #expect(model.state == .loading)
        #expect(model.station.network.name == "Trugo")
        #expect(model.station.name == "Kepez Moda & Düğün Salonu")

        await model.load()
        #expect(model.state == .loaded(detail()))
    }

    @Test("Hata halinden tekrar denemeyle detay yüklenir")
    func failureThenRetry() async {
        let repository = ScriptedStationRepository(results: [.failure, .success(detail())])
        let model = StationDetailModel(station: station, repository: repository, copyToPasteboard: { _ in })
        await model.load()
        #expect(model.state == .failed)
        await model.load()
        #expect(model.state == .loaded(detail()))
        #expect(await repository.requestedIDs == [station.id, station.id])
    }

    @Test("Adres kopyalama panoya yazar ve geri bildirimi gösterir")
    func copyAddress() async {
        var pasteboard: [String] = []
        let repository = ScriptedStationRepository(results: [.success(detail())])
        let model = StationDetailModel(
            station: station, repository: repository, copyToPasteboard: { pasteboard.append($0) })

        model.copyAddress()
        #expect(pasteboard.isEmpty, "Detay yüklenmeden adres yok")

        await model.load()
        model.copyAddress()
        #expect(pasteboard == ["2571. Sokak 4/2, Kepez"])
        #expect(model.isAddressCopied)
        #expect(model.copyCount == 1)
    }

    @Test("Paylaşım metni: ad, ağ, adres ve kodlanmış Apple Haritalar bağlantısı")
    func shareText() async {
        let repository = ScriptedStationRepository(results: [.success(detail())])
        let model = StationDetailModel(station: station, repository: repository, copyToPasteboard: { _ in })
        let link = "https://maps.apple.com/?ll=36.94,30.71&q=Kepez%20Moda%20%26%20D%C3%BC%C4%9F%C3%BCn%20Salonu"
        #expect(model.shareText == ["Kepez Moda & Düğün Salonu", "Trugo", link].joined(separator: "\n"))

        await model.load()
        let lines = model.shareText.split(separator: "\n").map(String.init)
        #expect(lines == ["Kepez Moda & Düğün Salonu", "Trugo", "2571. Sokak 4/2, Kepez", link])
        #expect(StationShareText.mapsURL(for: station)?.query?.contains("&q=") == true)
    }
}

/// Sırayla verilen sonuçları dönen depo.
actor ScriptedStationRepository: StationRepository {
    enum Result {
        case success(StationDetail)
        case failure
    }

    private var results: [Result]
    private(set) var requestedIDs: [Station.ID] = []

    init(results: [Result]) {
        self.results = results
    }

    func stations(in box: GeoBoundingBox) async throws -> [Station] { [] }

    func stationDetail(_ id: Station.ID) async throws -> StationDetail {
        requestedIDs.append(id)
        switch results.isEmpty ? .failure : results.removeFirst() {
        case .success(let detail): return detail
        case .failure: throw StationRepositoryError.stationNotFound
        }
    }
    func nearbyStations(_ query: StationQuery) async throws -> [StationListItem] { [] }
}
