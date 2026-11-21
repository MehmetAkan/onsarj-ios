import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// "Araçlarınız" ve "Araç ekle" modalının kökü.
///
/// - `.vehicles`: araç listesiyle, içerik yüksekliğinde açılır (araç çoksa büyür, liste kayar).
///   "Yeni araç ekle" aynı modal içinde markalara geçer ve modal tam yüksekliğe çıkar; geri ile listeye
///   dönülünce yeniden içerik yüksekliğine iner.
/// - `.addVehicle`: doğrudan markalarla, tam yükseklikte açılır; markalarda geri düğmesi yoktur.
///
/// Araç seçilince veya eklenince `onClose` çağrılır; uygulama katmanı modalı kapatır ve ana sayfa
/// kartını yeniden yükler.
public struct GarageView: View {
    /// Modalın açıldığı yer.
    public enum Start: Sendable, Hashable {
        /// Kartın adı ve okundan: "Araçlarınız".
        case vehicles
        /// Araç yokken kartın "Araç ekle"sinden: markalar.
        case addVehicle
    }

    enum Destination: Hashable {
        case brands
        case models(VehicleBrand)
        case variants(VehicleModel)
    }

    @State private var garage: GarageModel
    @State private var catalog: AddVehicleModel
    @State private var path: [Destination] = []
    @State private var fittedHeight: CGFloat?
    @State private var detent = PresentationDetent.large
    private let start: Start
    private let onClose: () -> Void

    /// - Parameters:
    ///   - repository: Araç deposu; varsayılan seçme ve ekleme buradan yapılır.
    ///   - catalog: Araç kataloğu.
    ///   - start: Modalın ilk sayfası.
    ///   - onClose: X'e dokunuldu, araç seçildi veya eklendi; modal kapatılmalı.
    public init(
        repository: any VehicleRepository,
        catalog: any VehicleCatalog,
        start: Start,
        onClose: @escaping () -> Void
    ) {
        _garage = State(initialValue: GarageModel(repository: repository))
        _catalog = State(initialValue: AddVehicleModel(repository: repository, catalog: catalog))
        self.start = start
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack(path: $path) {
            root.navigationDestination(for: Destination.self, destination: destination)
        }
        .overlay(alignment: .bottom) {
            if let notice = garage.notice ?? catalog.notice {
                NoticeBanner(notice: notice) {
                    garage.dismissNotice()
                    catalog.dismissNotice()
                }
            }
        }
        .presentationDetents(detents, selection: $detent)
        .onChange(of: path) { updateDetent() }
        .onChange(of: fittedHeight) { updateDetent() }
    }

    @ViewBuilder private var root: some View {
        switch start {
        case .vehicles:
            VehicleListPage(
                model: garage,
                onAddNew: { path.append(.brands) },
                onClose: onClose,
                onIdealHeightChange: { fittedHeight = $0 }
            )
        case .addVehicle:
            BrandListPage(model: catalog, onBack: nil, onSelect: { path.append(.models($0)) }, onClose: onClose)
        }
    }

    @ViewBuilder
    private func destination(_ destination: Destination) -> some View {
        switch destination {
        case .brands:
            BrandListPage(model: catalog, onBack: pop, onSelect: { path.append(.models($0)) }, onClose: onClose)
        case .models(let brand):
            ModelListPage(
                model: catalog, brand: brand, onSelect: { path.append(.variants($0)) }, onBack: pop, onClose: onClose)
        case .variants(let vehicleModel):
            VariantListPage(model: catalog, vehicleModel: vehicleModel, onAdded: onClose, onBack: pop, onClose: onClose)
        }
    }

    /// Araç listesinde içerik yüksekliği, katalog sayfalarında tam yükseklik.
    private var detents: Set<PresentationDetent> {
        start == .vehicles ? [fittedDetent, .large] : [.large]
    }

    private var fittedDetent: PresentationDetent {
        fittedHeight.map { .height($0) } ?? .medium
    }

    private func updateDetent() {
        detent = start == .vehicles && path.isEmpty ? fittedDetent : .large
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
