import Observation
import OnsarjDomain

/// Plan seçenekleri, şarj ağları ve ağ seçici sayfalarının paylaştığı durum.
///
/// Kaydet düğmesi yoktur: her değişiklik hemen `RoutePreferencesStoring.save` ile saklanır. Kayıtlar
/// sırayla yazılır; art arda iki değişiklikte depoya son yazılan her zaman son haldir.
///
/// Ağ adları kataloğdan çözülür ve burada tutulur; ağ seçicinin bulduğu ağların adları da eklenir.
/// Adı çözülemeyen kimlik listeden düşmez, `name(for:)` `nil` döner ve ekran "Bilinmeyen ağ" yazar.
@MainActor
@Observable
final class RoutePreferencesModel {
    private(set) var preferences = RoutePreferences.default
    /// Kayıtlı tercihler okundu mu. Okunmadan yapılan değişiklik kaydı ezeceği için sayfalar
    /// içeriği okumadan sonra gösterir.
    private(set) var isLoaded = false
    private var networkNames: [ChargingNetwork.ID: String] = [:]

    @ObservationIgnored private let store: any RoutePreferencesStoring
    @ObservationIgnored private let catalog: any ChargingNetworkCatalog
    @ObservationIgnored private var lastSave: Task<Void, Never>?

    init(store: any RoutePreferencesStoring, catalog: any ChargingNetworkCatalog) {
        self.store = store
        self.catalog = catalog
    }

    /// Kayıtlı tercihleri okur ve listelerdeki ağların adlarını çözer. Bir kez çalışır.
    func load() async {
        guard !isLoaded else { return }
        preferences = await store.load()
        isLoaded = true
        await resolveNames()
    }

    /// Ağın adı; katalogda bulunamadıysa `nil`.
    func name(for networkID: ChargingNetwork.ID) -> String? {
        networkNames[networkID]
    }

    /// Başka bir yerden (ağ seçici) öğrenilen ağ adlarını ekler.
    func remember(_ networks: [ChargingNetwork]) {
        for network in networks {
            networkNames[network.id] = network.name
        }
    }

    // MARK: - Değişiklikler

    func setChargeStops(_ strategy: ChargeStopStrategy) {
        update { $0.chargeStops = strategy }
    }

    func toggle(_ avoidance: RouteAvoidance) {
        update { $0.toggle(avoidance) }
    }

    func prefer(_ network: ChargingNetwork) {
        remember([network])
        update { $0.prefer(network.id) }
    }

    func avoid(_ network: ChargingNetwork) {
        remember([network])
        update { $0.avoid(network.id) }
    }

    func remove(_ networkID: ChargingNetwork.ID) {
        update { $0.remove(networkID) }
    }

    /// Bekleyen kayıtların bitmesini bekler.
    func waitForPendingSave() async {
        await lastSave?.value
    }

    /// Değişikliği uygular ve sonucu saklar. Sonuç değişmediyse (ör. listede olmayan ağı
    /// kaldırmak) kayıt yapılmaz.
    private func update(_ change: (inout RoutePreferences) -> Void) {
        var updated = preferences
        change(&updated)
        guard updated != preferences else { return }
        preferences = updated
        let previous = lastSave
        let store = store
        lastSave = Task {
            await previous?.value
            await store.save(updated)
        }
    }

    /// Ad çözümü başarısız olursa adlar boş kalır; satırlar "Bilinmeyen ağ" ile görünür ve
    /// kaldırılabilir.
    private func resolveNames() async {
        let ids = preferences.preferredNetworks + preferences.avoidedNetworks
        let missing = ids.filter { networkNames[$0] == nil }
        guard !missing.isEmpty, let networks = try? await catalog.networks(withIDs: missing) else { return }
        remember(networks)
    }
}
