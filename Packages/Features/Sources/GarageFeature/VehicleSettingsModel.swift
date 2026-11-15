import Foundation
import Observation
import OnsarjDomain

/// Araç ayarları, sürüş profilleri, profil formu ve konnektör sayfalarının paylaştığı durum.
///
/// Araç kimliğiyle başlar ve aracı depodan okur. Her yazma işleminden dönen `Vehicle` ile durumu
/// günceller. Çip, boya ve konnektör seçimleri **anında** kaydedilir: ekran seçimi hemen gösterir;
/// yazma başarısız olursa eski değere döner ve "Değişiklik kaydedilemedi" bildirilir.
@MainActor
@Observable
final class VehicleSettingsModel {
    enum Phase: Equatable {
        case loading
        case loaded
        /// Araç bulunamadı veya okunamadı.
        case failed
    }

    private(set) var phase = Phase.loading
    private(set) var vehicle: Vehicle?
    private(set) var notice: GarageNotice?

    /// Kaydı süren anlık seçimler; ekran bunları gösterir.
    private var pendingProfileID: DrivingProfile.ID?
    private var pendingColorHex: String?
    private var pendingConnectors: [ConnectorType]?

    @ObservationIgnored private let repository: any VehicleRepository
    @ObservationIgnored let vehicleID: Vehicle.ID

    init(repository: any VehicleRepository, vehicleID: Vehicle.ID) {
        self.repository = repository
        self.vehicleID = vehicleID
    }

    func load() async {
        phase = .loading
        do {
            vehicle = try await repository.vehicles().first { $0.id == vehicleID }
            phase = vehicle == nil ? .failed : .loaded
        } catch {
            phase = .failed
        }
    }

    // MARK: - Gösterilen değerler

    var activeProfileID: DrivingProfile.ID? {
        pendingProfileID ?? vehicle?.activeProfileID
    }

    var colorHex: String? {
        pendingColorHex ?? vehicle?.colorHex
    }

    var connectors: [ConnectorType] {
        pendingConnectors ?? vehicle?.connectors ?? []
    }

    func dismissNotice() {
        notice = nil
    }

    // MARK: - Anında kaydedilenler

    func selectProfile(_ id: DrivingProfile.ID) async {
        guard id != activeProfileID else { return }
        pendingProfileID = id
        await write { try await $0.setActiveProfile(id, for: $1) }
        pendingProfileID = nil
    }

    func selectPaint(_ paint: VehiclePaint) async {
        guard VehiclePaint(hex: colorHex ?? "") != paint else { return }
        pendingColorHex = paint.hex
        await write { try await $0.updateVehicle($1, VehicleUpdate(colorHex: paint.hex)) }
        pendingColorHex = nil
    }

    /// Konnektörü ekler veya çıkarır; son seçili tür çıkarılamaz. Sıra `ConnectorType` sırasıdır.
    func toggleConnector(_ connector: ConnectorType) async {
        var selected = Set(connectors)
        if selected.contains(connector) {
            guard selected.count > 1 else {
                notice = GarageNotice(kind: .connectorRequired)
                return
            }
            selected.remove(connector)
        } else {
            selected.insert(connector)
        }
        let ordered = ConnectorType.allCases.filter(selected.contains)
        pendingConnectors = ordered
        await write { try await $0.updateVehicle($1, VehicleUpdate(connectors: ordered)) }
        pendingConnectors = nil
    }

    // MARK: - Kaydet ile kaydedilenler

    /// Değer modalının sonucunu kaydeder. Başarılıysa `true`.
    func save(_ target: ValueEditTarget, editor: ValueEditor) async -> Bool {
        guard editor.canSave, let vehicle else { return false }
        let profile = vehicle.activeProfile
        switch target {
        case .consumption:
            guard let value = editor.decimalValue else { return false }
            return await saveProfile(profile.draft(consumption: value))
        case .maxSpeed:
            guard let value = editor.integerValue else { return false }
            return await saveProfile(profile.draft(maxSpeed: value))
        case .batteryDegradation:
            guard let value = editor.integerValue else { return false }
            return await write { try await $0.updateVehicle($1, VehicleUpdate(batteryHealthPercent: 100 - value)) }
        case .nickname:
            return await write { try await $0.updateVehicle($1, VehicleUpdate(nickname: editor.trimmed)) }
        }
    }

    /// Profil formunun ve değer modalının profil kaydı. Başarılıysa `true`.
    func saveProfile(_ draft: DrivingProfileDraft) async -> Bool {
        await write { try await $0.saveProfile(draft, for: $1) }
    }

    @discardableResult
    func deleteProfile(_ id: DrivingProfile.ID) async -> Bool {
        await write { try await $0.deleteProfile(id, for: $1) }
    }

    /// Aracı siler. Başarılıysa `true`; ekran modalı kapatır.
    func deleteVehicle() async -> Bool {
        do {
            try await repository.deleteVehicle(vehicleID)
            return true
        } catch {
            notice = GarageNotice(kind: .saveFailed)
            return false
        }
    }

    /// Yazma işlemini çalıştırır, dönen araçla durumu günceller; hata olursa bildirir.
    @discardableResult
    private func write(
        _ operation: (any VehicleRepository, Vehicle.ID) async throws -> Vehicle
    ) async -> Bool {
        do {
            vehicle = try await operation(repository, vehicleID)
            return true
        } catch {
            notice = GarageNotice(kind: .saveFailed)
            return false
        }
    }
}

extension DrivingProfile {
    /// Profilin değerleriyle taslak; verilen alanlar değişir.
    func draft(consumption: Double? = nil, maxSpeed: Int? = nil) -> DrivingProfileDraft {
        DrivingProfileDraft(
            id: id,
            name: name,
            consumptionKwhPer100Km: consumption ?? consumptionKwhPer100Km,
            maxSpeedKmh: maxSpeed ?? maxSpeedKmh
        )
    }
}
