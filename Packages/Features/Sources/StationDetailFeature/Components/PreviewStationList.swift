#if DEBUG
import DesignSystem
import Foundation
import OnsarjDomain
import SwiftUI

/// Önizleme verisi: dolu liste (biri fotoğraflı), boş, hata ve yükleniyor halleri. Değerler örnektir.
/// Fotoğraf önizlemeye özel, yerelde çizilen bir görseldir (gerçek fotoğraf kullanılmaz).
enum PreviewStationList {
    enum Content {
        case full
        case empty
        case failure
        case loading
    }

    static let origin = GeoCoordinate(latitude: 36.94, longitude: 30.71)

    @MainActor
    static var items: [StationListItem] {
        [
            item(
                Sample(id: "p1", network: "Trugo", name: "Kepez Moda Düğün Salonu", power: 160, available: 4, total: 4),
                km: 1),
            item(
                Sample(
                    id: "p2", network: "WAT Mobilite", name: "Opet Acente Muratpaşa", power: 160, available: 2, total: 2
                ),
                km: 2),
            item(
                Sample(id: "p3", network: "Trugo", name: "Dünyagöz Antalya", power: 120, available: 1, total: 2),
                km: 2.4, photo: photoURL),
            item(
                Sample(id: "p4", network: "ZES", name: "Kaleiçi Katlı Otopark", power: 22, available: nil, total: 6),
                km: 0.85),
        ]
    }

    /// Örnek istasyonun değerleri.
    private struct Sample {
        let id: String
        let network: String
        let name: String
        let power: Double
        let available: Int?
        let total: Int
    }

    private static func item(_ sample: Sample, km: Double, photo: URL? = nil) -> StationListItem {
        StationListItem(
            station: Station(
                id: Station.ID(sample.id), name: sample.name,
                network: ChargingNetwork(
                    id: ChargingNetwork.ID("net_\(sample.network.lowercased())"), name: sample.network),
                coordinate: origin,
                availability: StationAvailability(available: sample.available, total: sample.total)),
            maxPowerKw: sample.power, availableCount: sample.available, totalCount: sample.total,
            amenities: [.food, .cafe, .wifi], photoURL: photo, distanceKm: km)
    }

    /// Önizleme fotoğrafı: geçici klasöre bir kez çizilen 16:9 degrade görsel.
    @MainActor
    static let photoURL: URL? = {
        guard let data = ImageRenderer(content: PreviewPhoto()).uiImage?.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("onsarj-preview-station.png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }()
}

/// Önizleme fotoğrafının içeriği; boyutu yalnızca çizilen görselin çözünürlüğüdür.
private struct PreviewPhoto: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.availabilityAvailable, Theme.actionPrimary], startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(width: 320, height: 180)
    }
}

/// Önizleme ağ kataloğu.
struct PreviewNetworkCatalog: ChargingNetworkCatalog {
    private static let networks = ["Eşarj", "Shell Recharge", "Trugo", "WAT Mobilite", "ZES"]
        .map {
            ChargingNetwork(id: ChargingNetwork.ID("net_\($0.lowercased())"), name: $0)
        }

    func networks(matching query: String) async throws -> [ChargingNetwork] { Self.networks }

    func networks(withIDs ids: [ChargingNetwork.ID]) async throws -> [ChargingNetwork] {
        Self.networks.filter { ids.contains($0.id) }
    }
}

/// Önizleme araç deposu: araç yok ("Aracımla uyumlu" pasif). Yazma işlemleri önizlemede kullanılmaz.
struct PreviewNoVehicleRepository: VehicleRepository {
    func vehicles() async throws -> [Vehicle] { [] }
    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }
    func deleteVehicle(_ id: Vehicle.ID) async throws { throw VehicleRepositoryError.vehicleNotFound }
    func addVehicle(variantID: VehicleVariant.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.variantNotFound
    }
    func setDefaultVehicle(_ id: Vehicle.ID) async throws -> Vehicle { throw VehicleRepositoryError.vehicleNotFound }
    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }
    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }
    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }
}
#endif
