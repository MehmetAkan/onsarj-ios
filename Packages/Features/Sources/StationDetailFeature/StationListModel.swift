import Foundation
import Observation
import OnsarjDomain

/// Yakındaki istasyonlar listesinin durumu: süzgeçler, sonuçlar ve listeden itilen detay.
///
/// - Açılışta etkin araç ve ağ kataloğu alınır, ardından liste beklemeden istenir.
/// - Süzgeç değişince `filterDebounce` beklenir; arada yeni değişiklik olursa önceki istek iptal edilir,
///   yalnızca sonuncusu gider.
/// - Karta dokununca detay itilir (`path`) ve seçim dışarı bildirilir (harita o pine gider); geri dönülünce
///   seçim kalkar.
@MainActor
@Observable
final class StationListModel {
    enum State: Equatable {
        case loading
        case loaded([StationListItem])
        case failed
    }

    /// Süzgeç değiştikten sonra istekten önceki bekleme.
    static let filterDebounce: Duration = .milliseconds(300)

    let origin: StationListOrigin
    private(set) var state: State = .loading
    /// Katalogdaki ağlar ("Ağlar" çipinin seçenekleri).
    private(set) var networks: [ChargingNetwork] = []
    /// Etkin aracın konnektörleri; etkin araç yoksa `nil`.
    private(set) var vehicleConnectors: [ConnectorType]?

    var filters: StationListFilters {
        didSet {
            guard filters != oldValue else { return }
            onFiltersChange(filters)
            scheduleLoad(after: debounce)
        }
    }

    /// Listeden itilen detaylar; en üstteki haritada seçilidir.
    var path: [Station] = [] {
        didSet {
            if path.last != oldValue.last { onSelectionChange(path.last) }
        }
    }

    @ObservationIgnored private let repository: any StationRepository
    @ObservationIgnored private let vehicleRepository: any VehicleRepository
    @ObservationIgnored private let networkCatalog: any ChargingNetworkCatalog
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private let onFiltersChange: (StationListFilters) -> Void
    @ObservationIgnored private let onSelectionChange: (Station?) -> Void
    /// Bekleyen istek; testler sonucunu bekleyebilsin diye görünür.
    @ObservationIgnored private(set) var pendingLoad: Task<Void, Never>?

    init(
        origin: StationListOrigin,
        filters: StationListFilters,
        repository: any StationRepository,
        vehicleRepository: any VehicleRepository,
        networkCatalog: any ChargingNetworkCatalog,
        debounce: Duration = StationListModel.filterDebounce,
        onFiltersChange: @escaping (StationListFilters) -> Void = { _ in },
        onSelectionChange: @escaping (Station?) -> Void = { _ in }
    ) {
        self.origin = origin
        self.filters = filters
        self.repository = repository
        self.vehicleRepository = vehicleRepository
        self.networkCatalog = networkCatalog
        self.debounce = debounce
        self.onFiltersChange = onFiltersChange
        self.onSelectionChange = onSelectionChange
    }

    /// "Aracımla uyumlu" kullanılabilir mi: etkin araç var ve konnektörü biliniyor.
    var isVehicleFilterAvailable: Bool { !(vehicleConnectors ?? []).isEmpty }

    /// Açılış: etkin araç ve ağlar, ardından liste.
    func start() async {
        async let vehicles = try? vehicleRepository.vehicles()
        async let networks = try? networkCatalog.networks(matching: "")
        vehicleConnectors = await vehicles.flatMap(Vehicle.activeVehicle(in:))?.connectors
        self.networks = await networks ?? []
        scheduleLoad(after: nil)
        await pendingLoad?.value
    }

    /// Hatadan sonra "Tekrar dene": beklemeden yeniden ister.
    func retry() {
        scheduleLoad(after: nil)
    }

    /// Boş durumdaki "Filtreleri temizle": tüm süzgeçler (ek filtreler dahil) varsayılana döner.
    func clearFilters() {
        filters = StationListFilters()
    }

    /// Karta dokunuldu: detay itilir.
    func select(_ item: StationListItem) {
        path.append(item.station)
    }

    /// Ağ seçili mi; "Tümü" seçiliyken (boş küme) hiçbiri seçili sayılmaz.
    func isNetworkSelected(_ id: ChargingNetwork.ID) -> Bool {
        filters.networkIDs.contains(id)
    }

    func setNetwork(_ id: ChargingNetwork.ID, selected: Bool) {
        if selected {
            filters.networkIDs.insert(id)
        } else {
            filters.networkIDs.remove(id)
        }
    }

    private func scheduleLoad(after delay: Duration?) {
        pendingLoad?.cancel()
        state = .loading
        let query = filters.query(origin: origin.coordinate, vehicleConnectors: vehicleConnectors)
        pendingLoad = Task { [weak self, repository] in
            do {
                if let delay { try await Task.sleep(for: delay) }
                let items = try await repository.nearbyStations(query)
                try Task.checkCancellation()
                self?.state = .loaded(items)
            } catch is CancellationError {
                return
            } catch {
                self?.state = .failed
            }
        }
    }
}
