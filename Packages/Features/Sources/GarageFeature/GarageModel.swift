import Foundation
import Observation
import OnsarjDomain

/// "Araçlarınız" sayfasının durumu: kullanıcının araçları ve etkin araç.
///
/// Bir araca dokunmak onu varsayılan (etkin) yapar; etkin araca dokunmak yalnızca kapatır.
@MainActor
@Observable
final class GarageModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed
    }

    private(set) var phase = Phase.loading
    private(set) var vehicles: [Vehicle] = []
    /// Varsayılan yapılmakta olan araç; işlem sürerken diğer kartlar pasif.
    private(set) var selectingID: Vehicle.ID?
    private(set) var notice: GarageNotice?

    @ObservationIgnored private let repository: any VehicleRepository

    init(repository: any VehicleRepository) {
        self.repository = repository
    }

    /// Etkin araç: varsayılan olarak işaretlenen, yoksa ilk araç.
    var activeVehicleID: Vehicle.ID? {
        Vehicle.activeVehicle(in: vehicles)?.id
    }

    func load() async {
        phase = .loading
        do {
            vehicles = try await repository.vehicles()
            phase = .loaded
        } catch {
            phase = .failed
        }
    }

    /// Aracı etkin yapar. Modal kapanmalıysa (seçim kaydedildi veya araç zaten etkindi) `true`;
    /// kayıt başarısızsa `false` ve "Değişiklik kaydedilemedi".
    func select(_ id: Vehicle.ID) async -> Bool {
        guard selectingID == nil else { return false }
        guard id != activeVehicleID else { return true }
        selectingID = id
        defer { selectingID = nil }
        do {
            _ = try await repository.setDefaultVehicle(id)
            return true
        } catch {
            notice = GarageNotice(kind: .saveFailed)
            return false
        }
    }

    func dismissNotice() {
        notice = nil
    }
}
