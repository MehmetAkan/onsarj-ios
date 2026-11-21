import Foundation
import Observation
import OnsarjCore
import OnsarjDomain

/// "Araç ekle" akışının durumu: marka → model → varyant.
///
/// Katalog yanıtları akış boyunca bellekte tutulur; geri gelince yeniden istenmez. Marka araması
/// istemcide, Türkçe kurallarıyla büyük/küçük harf ve aksan duyarsız "içerir" eşleşmesidir (`SearchText`).
@MainActor
@Observable
final class AddVehicleModel {
    /// Bir katalog isteğinin hali.
    enum Load<Value: Equatable>: Equatable {
        case loading
        case loaded(Value)
        case failed
    }

    private(set) var brands = Load<[VehicleBrand]>.loading
    private(set) var models: [VehicleBrand.ID: Load<[VehicleModel]>] = [:]
    private(set) var variants: [VehicleModel.ID: Load<[VehicleVariant]>] = [:]
    /// Eklenmekte olan varyant; işlem sürerken diğer satırlar pasif.
    private(set) var addingVariantID: VehicleVariant.ID?
    private(set) var notice: GarageNotice?
    var brandQuery = ""

    @ObservationIgnored private let repository: any VehicleRepository
    @ObservationIgnored private let catalog: any VehicleCatalog

    init(repository: any VehicleRepository, catalog: any VehicleCatalog) {
        self.repository = repository
        self.catalog = catalog
    }

    /// Aramaya uyan markalar; markalar yüklenmediyse boş.
    var filteredBrands: [VehicleBrand] {
        guard case .loaded(let all) = brands else { return [] }
        return all.filter { SearchText.matches($0.name, query: brandQuery) }
    }

    // MARK: - Yükleme

    func loadBrands() async {
        if case .loaded = brands { return }
        brands = .loading
        do {
            brands = .loaded(try await catalog.brands())
        } catch {
            brands = .failed
        }
    }

    func loadModels(of brandID: VehicleBrand.ID) async {
        if case .loaded = models[brandID] { return }
        models[brandID] = .loading
        do {
            models[brandID] = .loaded(try await catalog.models(of: brandID))
        } catch {
            models[brandID] = .failed
        }
    }

    func loadVariants(of modelID: VehicleModel.ID) async {
        if case .loaded = variants[modelID] { return }
        variants[modelID] = .loading
        do {
            variants[modelID] = .loaded(try await catalog.variants(of: modelID))
        } catch {
            variants[modelID] = .failed
        }
    }

    // MARK: - Ekleme

    /// Varyanttan araç ekler. Başarılıysa `true` (modal kapanır); hata olursa "Araç eklenemedi" ve
    /// sayfada kalınır. Bir ekleme sürerken ikincisi başlamaz.
    func add(_ variant: VehicleVariant) async -> Bool {
        guard addingVariantID == nil else { return false }
        addingVariantID = variant.id
        defer { addingVariantID = nil }
        do {
            _ = try await repository.addVehicle(variantID: variant.id)
            return true
        } catch {
            notice = GarageNotice(kind: .addFailed)
            return false
        }
    }

    func dismissNotice() {
        notice = nil
    }
}
