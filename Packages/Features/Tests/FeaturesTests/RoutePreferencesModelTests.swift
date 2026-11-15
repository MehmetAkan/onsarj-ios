import OnsarjDomain
import Testing

@testable import RoutePlanningFeature

/// Kayıtları sayan tercih deposu.
actor SpyPreferencesStore: RoutePreferencesStoring {
    private let initial: RoutePreferences
    private(set) var saved: [RoutePreferences] = []

    init(initial: RoutePreferences = .default) {
        self.initial = initial
    }

    func load() async -> RoutePreferences { initial }
    func save(_ preferences: RoutePreferences) async { saved.append(preferences) }
}

/// Sonucu ayarlanabilen ağ kataloğu.
actor FakeNetworkCatalog: ChargingNetworkCatalog {
    struct Failure: Error {}

    static let zes = ChargingNetwork(id: ChargingNetwork.ID("zes"), name: "ZES")
    static let trugo = ChargingNetwork(id: ChargingNetwork.ID("trugo"), name: "Trugo")

    var fails: Bool
    private(set) var queries: [String] = []

    init(fails: Bool = false) {
        self.fails = fails
    }

    func setFails(_ value: Bool) { fails = value }

    func networks(matching query: String) async throws -> [ChargingNetwork] {
        queries.append(query)
        if fails { throw Failure() }
        return [Self.trugo, Self.zes]
    }

    func networks(withIDs ids: [ChargingNetwork.ID]) async throws -> [ChargingNetwork] {
        if fails { throw Failure() }
        return ids.compactMap { id in [Self.trugo, Self.zes].first { $0.id == id } }
    }
}

@MainActor
@Suite("RoutePreferencesModel")
struct RoutePreferencesModelTests {
    private let store = SpyPreferencesStore()
    private let catalog = FakeNetworkCatalog()

    private func loadedModel() async -> RoutePreferencesModel {
        let model = RoutePreferencesModel(store: store, catalog: catalog)
        await model.load()
        return model
    }

    @Test("Her değişiklik save'i bir kez çağırır, son kayıt son haldir")
    func eachChangeSavesOnce() async {
        let model = await loadedModel()

        model.setChargeStops(.fewest)
        model.toggle(.tolls)
        model.prefer(FakeNetworkCatalog.zes)
        model.avoid(FakeNetworkCatalog.trugo)
        model.remove(FakeNetworkCatalog.trugo.id)
        await model.waitForPendingSave()

        let saved = await store.saved
        #expect(saved.count == 5)
        #expect(saved.last == model.preferences)
    }

    @Test("Sonucu değiştirmeyen işlem kaydetmez")
    func noOpDoesNotSave() async {
        let model = await loadedModel()

        model.setChargeStops(.optimal)
        model.remove(FakeNetworkCatalog.zes.id)
        model.prefer(FakeNetworkCatalog.zes)
        await model.waitForPendingSave()
        let afterFirstAdd = await store.saved.count
        model.prefer(FakeNetworkCatalog.zes)
        await model.waitForPendingSave()

        #expect(afterFirstAdd == 1)
        #expect(await store.saved.count == 1)
    }

    @Test("Kayıtlı ağların adları çözülür; çözülemeyen nil kalır")
    func resolvesNames() async {
        let store = SpyPreferencesStore(
            initial: RoutePreferences(
                preferredNetworks: [FakeNetworkCatalog.zes.id],
                avoidedNetworks: [ChargingNetwork.ID("yok")]
            )
        )
        let model = RoutePreferencesModel(store: store, catalog: catalog)
        await model.load()

        #expect(model.name(for: FakeNetworkCatalog.zes.id) == "ZES")
        #expect(model.name(for: ChargingNetwork.ID("yok")) == nil)
        #expect(model.preferences.avoidedNetworks == [ChargingNetwork.ID("yok")])
    }
}

@MainActor
@Suite("NetworkPickerModel")
struct NetworkPickerModelTests {
    private let store = SpyPreferencesStore()

    private func makePicker(
        mode: NetworkPickerMode,
        catalog: FakeNetworkCatalog = FakeNetworkCatalog()
    ) async -> (NetworkPickerModel, RoutePreferencesModel) {
        let preferences = RoutePreferencesModel(store: store, catalog: catalog)
        await preferences.load()
        let picker = NetworkPickerModel(mode: mode, preferences: preferences, catalog: catalog, debounce: .zero)
        return (picker, preferences)
    }

    @Test("Diğer listedeki ağ pasif ve dokunmak bir şey yapmaz")
    func otherListIsDisabled() async {
        let (picker, preferences) = await makePicker(mode: .prefer)
        preferences.avoid(FakeNetworkCatalog.zes)

        #expect(picker.status(of: FakeNetworkCatalog.zes) == .inOtherList)
        picker.toggle(FakeNetworkCatalog.zes)
        #expect(preferences.preferences.avoidedNetworks == [FakeNetworkCatalog.zes.id])
        #expect(preferences.preferences.preferredNetworks.isEmpty)
    }

    @Test("Ekle, eklenen ağa tekrar dokunmak geri alır", arguments: [NetworkPickerMode.prefer, .avoid])
    func toggleAddsAndUndoes(mode: NetworkPickerMode) async {
        let (picker, preferences) = await makePicker(mode: mode)

        #expect(picker.status(of: FakeNetworkCatalog.zes) == .available)
        picker.toggle(FakeNetworkCatalog.zes)
        picker.toggle(FakeNetworkCatalog.trugo)
        #expect(picker.status(of: FakeNetworkCatalog.zes) == .added)
        let ids = mode == .prefer ? preferences.preferences.preferredNetworks : preferences.preferences.avoidedNetworks
        #expect(ids == [FakeNetworkCatalog.zes.id, FakeNetworkCatalog.trugo.id])

        picker.toggle(FakeNetworkCatalog.zes)
        #expect(picker.status(of: FakeNetworkCatalog.zes) == .available)
        #expect(preferences.preferences == RoutePreferences.default.adding(FakeNetworkCatalog.trugo.id, mode: mode))
    }

    @Test("Arama hatası hata haline düşer; retry sonrası düzelir")
    func failureThenRetry() async {
        let catalog = FakeNetworkCatalog(fails: true)
        let (picker, _) = await makePicker(mode: .prefer, catalog: catalog)

        await picker.search()
        #expect(picker.phase == .failed)

        await catalog.setFails(false)
        let before = picker.request
        picker.retry()
        #expect(picker.phase == .loading)
        #expect(picker.request != before)
        await picker.search()
        #expect(picker.phase == .loaded([FakeNetworkCatalog.trugo, FakeNetworkCatalog.zes]))
    }

    @Test("Bulunan ağların adları paylaşılan modele eklenir")
    func searchRemembersNames() async {
        let (picker, preferences) = await makePicker(mode: .avoid)
        picker.query = "z"
        await picker.search()
        #expect(preferences.name(for: FakeNetworkCatalog.trugo.id) == "Trugo")
    }
}

extension RoutePreferences {
    fileprivate func adding(_ id: ChargingNetwork.ID, mode: NetworkPickerMode) -> RoutePreferences {
        var copy = self
        switch mode {
        case .prefer: copy.prefer(id)
        case .avoid: copy.avoid(id)
        }
        return copy
    }
}
