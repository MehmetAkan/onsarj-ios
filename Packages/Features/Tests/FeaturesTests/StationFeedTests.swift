import OnsarjDomain
import Testing

@testable import HomeMapFeature

@MainActor
@Suite("StationFeed ve istasyon seçimi")
struct StationFeedTests {
    /// Antalya merkezinde, eşiğin altında bir görünüm.
    private let antalya = box(south: 36.85, west: 30.65, north: 36.95, east: 30.75)

    @Test("Kamera durunca istek beklemeyle atılır; art arda durmalarda yalnızca sonuncusu gider")
    func debouncesAndKeepsLast() async {
        let repository = RecordingStationRepository(stations: [station("a", 36.9, 30.7)])
        let feed = StationFeed(repository: repository, debounce: .milliseconds(50))
        let first = box(south: 36.0, west: 29.0, north: 36.1, east: 29.1)

        feed.cameraDidIdle(first)
        feed.cameraDidIdle(antalya)
        #expect(await repository.requests.isEmpty)
        await feed.pendingLoad?.value

        #expect(await repository.requests == [antalya.scaled(by: StationFeed.requestScale)])
        #expect(feed.stations.map(\.id.rawValue) == ["a"])
    }

    @Test("Alınmış bölgenin içindeki görünüm için yeniden istenmez")
    func remembersFetchedRegions() async {
        let repository = RecordingStationRepository()
        let feed = StationFeed(repository: repository, debounce: .zero)

        feed.cameraDidIdle(antalya)
        await feed.pendingLoad?.value
        feed.cameraDidIdle(box(south: 36.86, west: 30.66, north: 36.94, east: 30.74))
        await feed.pendingLoad?.value

        #expect(await repository.requests.count == 1)
        #expect(feed.pendingLoad == nil)
    }

    @Test("Eşikten geniş görünümde istek atılmaz, eldeki istasyonlar kalır")
    func skipsWideViews() async {
        let repository = RecordingStationRepository(stations: [station("a", 36.9, 30.7)])
        let feed = StationFeed(repository: repository, debounce: .zero)
        feed.cameraDidIdle(antalya)
        await feed.pendingLoad?.value

        let span = StationFeed.maximumRequestSpanDegrees + 1
        feed.cameraDidIdle(box(south: 36, west: 28, north: 39, east: 28 + span))
        await feed.pendingLoad?.value

        #expect(await repository.requests.count == 1)
        #expect(feed.stations.count == 1)
    }

    @Test("İstasyonlar kimliğe göre birleşir, hata kullanıcıya taşınmaz ve bölge yeniden denenir")
    func mergesAndRetriesAfterFailure() async {
        let repository = RecordingStationRepository(stations: [station("a", 36.9, 30.7)], failsFirst: true)
        let feed = StationFeed(repository: repository, debounce: .zero)

        feed.cameraDidIdle(antalya)
        await feed.pendingLoad?.value
        #expect(feed.stations.isEmpty)

        feed.cameraDidIdle(antalya)
        await feed.pendingLoad?.value
        feed.cameraDidIdle(box(south: 36.80, west: 30.60, north: 37.00, east: 30.80))
        await feed.pendingLoad?.value

        #expect(await repository.requests.count == 3)
        #expect(feed.stations.map(\.id.rawValue) == ["a"])
    }
}

private func box(south: Double, west: Double, north: Double, east: Double) -> GeoBoundingBox {
    GeoBoundingBox(
        southWest: GeoCoordinate(latitude: south, longitude: west),
        northEast: GeoCoordinate(latitude: north, longitude: east)
    )
}

func station(_ id: String, _ latitude: Double, _ longitude: Double) -> Station {
    Station(
        id: Station.ID(id),
        name: id,
        network: ChargingNetwork(id: ChargingNetwork.ID("net_zes"), name: "ZES"),
        coordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
        availability: .available
    )
}

/// İstekleri kaydeden depo; kutudaki istasyonları döner. İstenirse ilk istekte hata verir.
actor RecordingStationRepository: StationRepository {
    struct Failure: Error {}

    private let stations: [Station]
    private var failsNext: Bool
    private(set) var requests: [GeoBoundingBox] = []

    init(stations: [Station] = [], failsFirst: Bool = false) {
        self.stations = stations
        failsNext = failsFirst
    }

    func stations(in box: GeoBoundingBox) async throws -> [Station] {
        requests.append(box)
        if failsNext {
            failsNext = false
            throw Failure()
        }
        return stations.filter { box.contains($0.coordinate) }
    }
}
