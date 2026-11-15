import Observation
import OnsarjDomain

/// Ağ seçicinin kipi: hangi listeye ağ eklendiği.
enum NetworkPickerMode: Hashable, Sendable {
    case prefer
    case avoid
}

/// Ağ seçicinin durumu: sorgu, sonuçlar ve her satırın hali.
///
/// Seçim doğrudan paylaşılan `RoutePreferencesModel`'e yazılır; sayfadan çıkmadan birden fazla ağ
/// eklenebilir, eklenmiş ağa tekrar dokunmak geri alır. Diğer listede olan ağ pasiftir: değişmez
/// (bir ağ iki listede birden olamaz) arayüzde de korunur.
@MainActor
@Observable
final class NetworkPickerModel {
    enum Phase: Equatable {
        case loading
        case loaded([ChargingNetwork])
        case failed
    }

    enum RowStatus: Equatable {
        /// Eklenebilir.
        case available
        /// Bu kipin listesinde; dokunmak geri alır.
        case added
        /// Diğer listede; pasif.
        case inOtherList
    }

    /// Aramayı tetikleyen her şey: sorgu ve "Tekrar dene" sayacı. Ekran `task(id:)` ile izler;
    /// değişince eski istek iptal edilir.
    struct Request: Equatable {
        let query: String
        let attempt: Int
    }

    let mode: NetworkPickerMode
    var query = ""
    private(set) var phase = Phase.loading
    private var attempt = 0

    @ObservationIgnored private let preferences: RoutePreferencesModel
    @ObservationIgnored private let catalog: any ChargingNetworkCatalog
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private var hasSearched = false

    /// - Parameter debounce: Yazım ile arama arasındaki bekleme; ilk arama beklemeden yapılır.
    init(
        mode: NetworkPickerMode,
        preferences: RoutePreferencesModel,
        catalog: any ChargingNetworkCatalog,
        debounce: Duration = .milliseconds(300)
    ) {
        self.mode = mode
        self.preferences = preferences
        self.catalog = catalog
        self.debounce = debounce
    }

    var request: Request {
        Request(query: query, attempt: attempt)
    }

    /// Sorguya göre arar. Görev iptal edilirse (yeni yazım) sonuç yazılmaz.
    func search() async {
        if hasSearched {
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return
            }
        }
        hasSearched = true
        do {
            let networks = try await catalog.networks(matching: query)
            guard !Task.isCancelled else { return }
            preferences.remember(networks)
            phase = .loaded(networks)
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failed
        }
    }

    /// "Tekrar dene": yükleniyor haline döner ve aramayı yeniden tetikler.
    func retry() {
        phase = .loading
        attempt += 1
    }

    func status(of network: ChargingNetwork) -> RowStatus {
        let current = preferences.preferences
        switch mode {
        case .prefer:
            if current.isPreferred(network.id) { return .added }
            return current.isAvoided(network.id) ? .inOtherList : .available
        case .avoid:
            if current.isAvoided(network.id) { return .added }
            return current.isPreferred(network.id) ? .inOtherList : .available
        }
    }

    /// Satıra dokunuldu: eklenebilirse ekler, eklenmişse geri alır, pasifse bir şey yapmaz.
    func toggle(_ network: ChargingNetwork) {
        switch (status(of: network), mode) {
        case (.available, .prefer): preferences.prefer(network)
        case (.available, .avoid): preferences.avoid(network)
        case (.added, _): preferences.remove(network.id)
        case (.inOtherList, _): break
        }
    }
}
