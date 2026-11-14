import Foundation
import Observation
import OnsarjDomain

/// Ana sayfadaki araç kartının durumu: etkin araç ve kullanıcının girdiği batarya yüzdesi.
///
/// - Etkin araç `Vehicle.activeVehicle(in:)` ile seçilir.
/// - Yüzde: kayıtlı değer varsa o, yoksa `BatteryLevel.initial`. Başlangıç değeri depoya yazılmaz.
/// - Sürüklerken yalnızca ekrandaki değer değişir (`updateLevel`); depoya sürükleme bitince bir
///   kez yazılır (`commitLevel`).
@MainActor
@Observable
final class VehicleCardModel {
    enum State: Equatable {
        case loading
        case loaded(Vehicle, BatteryLevel)
        case empty
        case failed
    }

    private(set) var state: State = .loading

    @ObservationIgnored private let repository: any VehicleRepository
    @ObservationIgnored private let batteryStore: any BatteryLevelStoring
    @ObservationIgnored private let now: @Sendable () -> Date

    /// Ekrandaki yüzde son kayıttan farklı mı? Değişmemiş yüzde depoya yazılmaz.
    @ObservationIgnored private var hasUncommittedLevel = false

    /// - Parameter now: Kayıt zamanı; testler sabit bir an verir.
    init(
        repository: any VehicleRepository,
        batteryStore: any BatteryLevelStoring,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.repository = repository
        self.batteryStore = batteryStore
        self.now = now
    }

    /// İlk yükleme. Kart zaten yüklendiyse (ekran yeniden göründüğünde) tekrar yüklemez.
    func load() async {
        guard state == .loading else { return }
        await fetch()
    }

    /// Hata halindeki "Tekrar dene": durumu baştan yükler.
    func reload() async {
        state = .loading
        await fetch()
    }

    /// Sürükleme sırasında ekrandaki yüzde; 0–100 dışı sınıra çekilir. Depoya yazmaz.
    func updateLevel(_ percent: Int) {
        guard case .loaded(let vehicle, let current) = state else { return }
        let level = BatteryLevel(percent: percent)
        guard level != current else { return }
        state = .loaded(vehicle, level)
        hasUncommittedLevel = true
    }

    /// Sürükleme bitti: ekrandaki yüzde bir kez kaydedilir.
    func commitLevel() async {
        guard hasUncommittedLevel, case .loaded(let vehicle, let level) = state else { return }
        hasUncommittedLevel = false
        await batteryStore.save(level, for: vehicle.id, at: now())
    }

    private func fetch() async {
        do {
            let vehicles = try await repository.vehicles()
            guard let vehicle = Vehicle.activeVehicle(in: vehicles) else {
                state = .empty
                return
            }
            let stored = await batteryStore.storedLevel(for: vehicle.id)
            hasUncommittedLevel = false
            state = .loaded(vehicle, stored?.level ?? .initial)
        } catch {
            state = .failed
        }
    }
}
