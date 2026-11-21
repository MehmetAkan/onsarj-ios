import Foundation
import OnsarjDomain
import Testing

@testable import StationDetailFeature

@MainActor
@Suite("StationListModel")
struct StationListModelTests {
    private static let origin = GeoCoordinate(latitude: 36.94, longitude: 30.71)
    private static let item = StationListItem(
        station: Station(
            id: Station.ID("st_001"), name: "Kepez",
            network: ChargingNetwork(id: ChargingNetwork.ID("net_trugo"), name: "Trugo"),
            coordinate: origin, availability: .available),
        maxPowerKw: 160, availableCount: 4, totalCount: 4, amenities: [], photoURL: nil, distanceKm: 1)

    private func model(
        repository: NearbyRecordingRepository,
        vehicles: FakeVehicleRepository = FakeVehicleRepository(result: .success([])),
        filters: StationListFilters = StationListFilters(),
        onFiltersChange: @escaping (StationListFilters) -> Void = { _ in },
        onSelectionChange: @escaping (Station?) -> Void = { _ in }
    ) -> StationListModel {
        StationListModel(
            origin: .userLocation(Self.origin), filters: filters, repository: repository, vehicleRepository: vehicles,
            networkCatalog: EmptyNetworkCatalog(), debounce: .milliseconds(50), onFiltersChange: onFiltersChange,
            onSelectionChange: onSelectionChange)
    }

    @Test("Açılışta bekleme olmadan tek istek; sorgu süzgeçlerden ve merkezden kurulur")
    func initialLoad() async {
        let repository = NearbyRecordingRepository(items: [Self.item])
        var filters = StationListFilters()
        filters.sort = .power
        let model = model(repository: repository, filters: filters)
        await model.start()
        #expect(model.state == .loaded([Self.item]))
        let queries = await repository.queries
        #expect(queries.count == 1)
        #expect(queries.first?.origin == Self.origin)
        #expect(queries.first?.sort == .power)
    }

    @Test("Süzgeç peş peşe değişince beklemeyle yalnızca son süzgeçlerle tek istek gider")
    func debouncedSingleRequest() async {
        let repository = NearbyRecordingRepository(items: [Self.item])
        var reported: [StationListFilters] = []
        let model = model(repository: repository, onFiltersChange: { reported.append($0) })
        await model.start()

        model.filters.sort = .power
        model.filters.minimumSpeed = .fast
        model.filters.minimumStalls = 4
        #expect(model.state == .loading)
        await model.pendingLoad?.value

        let queries = await repository.queries
        #expect(queries.count == 2, "Açılış + süzgeçlerin tek isteği")
        #expect(queries.last?.sort == .power)
        #expect(queries.last?.minimumSpeed == .fast)
        #expect(queries.last?.minimumStalls == 4)
        #expect(reported.count == 3, "Her değişiklik uygulama katmanına bildirilir (oturum belleği)")
        #expect(model.state == .loaded([Self.item]))
    }

    @Test("Boş halde 'Filtreleri temizle' ek filtreler dahil varsayılana döner ve yeniden ister")
    func clearFilters() async {
        let repository = NearbyRecordingRepository(items: [])
        var filters = StationListFilters()
        filters.sort = .availability
        filters.networkIDs = [ChargingNetwork.ID("net_zes")]
        filters.onlyAvailable = true
        let model = model(repository: repository, filters: filters)
        await model.start()
        #expect(model.state == .loaded([]))

        model.clearFilters()
        #expect(model.filters == StationListFilters())
        #expect(!model.filters.hasExtraFilters)
        await model.pendingLoad?.value
        let last = await repository.queries.last
        #expect(last?.networkIDs.isEmpty == true)
        #expect(last?.onlyAvailable == false)
        #expect(last?.sort == .distance)
    }

    @Test("Etkin araç yokken 'Aracımla uyumlu' pasif ve konnektör süzgeci uygulanmaz")
    func vehicleFilterWithoutVehicle() async {
        let repository = NearbyRecordingRepository(items: [])
        var filters = StationListFilters()
        filters.matchesVehicle = true
        let model = model(repository: repository, filters: filters)
        await model.start()
        #expect(!model.isVehicleFilterAvailable)
        #expect(await repository.queries.last?.connectorTypes.isEmpty == true)
    }

    @Test("Etkin araç varken 'Aracımla uyumlu' aracın konnektörleriyle süzer")
    func vehicleFilterWithVehicle() async {
        let repository = NearbyRecordingRepository(items: [])
        let vehicle = TestVehicles.dolphin()
        var filters = StationListFilters()
        filters.matchesVehicle = true
        let model = model(
            repository: repository, vehicles: FakeVehicleRepository(result: .success([vehicle])), filters: filters)
        await model.start()
        #expect(model.isVehicleFilterAvailable)
        #expect(await repository.queries.last?.connectorTypes == Set(vehicle.connectors))
    }

    @Test("Karta dokununca detay itilir ve seçim bildirilir; geri dönünce seçim kalkar")
    func selectPushesDetail() async {
        var selections: [Station?] = []
        let model = model(
            repository: NearbyRecordingRepository(items: [Self.item]), onSelectionChange: { selections.append($0) })
        await model.start()
        model.select(Self.item)
        #expect(model.path == [Self.item.station])
        model.path.removeLast()
        #expect(selections == [Self.item.station, nil])
    }

    @Test("Hata halinden 'Tekrar dene' beklemeden yeniden ister")
    func retryAfterFailure() async {
        let repository = NearbyRecordingRepository(items: [Self.item], failsFirst: true)
        let model = model(repository: repository)
        await model.start()
        #expect(model.state == .failed)
        model.retry()
        await model.pendingLoad?.value
        #expect(model.state == .loaded([Self.item]))
    }

    @Test("Ağ seçimi: seçilenler sorguya girer; 'Tümü' (boş küme) hepsidir")
    func networks() async {
        let model = model(repository: NearbyRecordingRepository(items: []))
        let zes = ChargingNetwork.ID("net_zes")
        model.setNetwork(zes, selected: true)
        #expect(model.isNetworkSelected(zes))
        #expect(model.filters.query(origin: Self.origin, vehicleConnectors: nil).networkIDs == [zes])
        model.setNetwork(zes, selected: false)
        #expect(model.filters.networkIDs.isEmpty)
    }

    @Test("Uzaklık biçimi: metre 10'a yuvarlanır, 10 km altı bir ondalık, üstü tam sayı")
    func distanceFormat() {
        let locale = Locale(identifier: "en_US")
        #expect(StationListText.distance(0.853, width: .abbreviated, locale: locale) == "850 m")
        #expect(StationListText.distance(0.001, width: .abbreviated, locale: locale) == "10 m")
        #expect(StationListText.distance(1, width: .abbreviated, locale: locale) == "1 km")
        #expect(StationListText.distance(1.24, width: .abbreviated, locale: locale) == "1.2 km")
        #expect(StationListText.distance(14.6, width: .abbreviated, locale: locale) == "15 km")
        #expect(StationListText.distance(0.9999, width: .abbreviated, locale: locale) == "1 km")
    }
}

/// Yakındaki istasyon isteklerini kaydeden depo.
actor NearbyRecordingRepository: StationRepository {
    struct Failure: Error {}

    private let items: [StationListItem]
    private var failsNext: Bool
    private(set) var queries: [StationQuery] = []

    init(items: [StationListItem], failsFirst: Bool = false) {
        self.items = items
        failsNext = failsFirst
    }

    func stations(in box: GeoBoundingBox) async throws -> [Station] { [] }

    func stationDetail(_ id: Station.ID) async throws -> StationDetail {
        throw StationRepositoryError.stationNotFound
    }

    func nearbyStations(_ query: StationQuery) async throws -> [StationListItem] {
        queries.append(query)
        if failsNext {
            failsNext = false
            throw Failure()
        }
        return items
    }
}

/// Boş ağ kataloğu.
struct EmptyNetworkCatalog: ChargingNetworkCatalog {
    func networks(matching query: String) async throws -> [ChargingNetwork] { [] }
    func networks(withIDs ids: [ChargingNetwork.ID]) async throws -> [ChargingNetwork] { [] }
}
