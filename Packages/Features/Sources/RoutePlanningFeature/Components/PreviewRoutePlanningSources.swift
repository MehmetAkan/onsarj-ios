#if DEBUG
import OnsarjDomain
import SwiftUI

/// Önizleme için tercih deposu: verilen tercihleri döner, kaydetmez (CLAUDE.md 2.3).
struct PreviewPreferencesStore: RoutePreferencesStoring {
    let preferences: RoutePreferences

    func load() async -> RoutePreferences { preferences }
    func save(_ preferences: RoutePreferences) async {}

    static let empty = PreviewPreferencesStore(preferences: .default)
    static let filled = PreviewPreferencesStore(
        preferences: RoutePreferences(
            chargeStops: .fewer,
            avoid: [.tolls, .ferries],
            preferredNetworks: ["zes", "trugo", "total", "silinmis"].map(ChargingNetwork.ID.init),
            avoidedNetworks: [ChargingNetwork.ID("edeka")]
        )
    )
}

/// Önizleme için ağ kataloğu.
struct PreviewNetworkCatalog: ChargingNetworkCatalog {
    static let networks = [
        ChargingNetwork(id: ChargingNetwork.ID("edeka"), name: "EDEKA"),
        ChargingNetwork(id: ChargingNetwork.ID("esarj"), name: "Eşarj"),
        ChargingNetwork(id: ChargingNetwork.ID("total"), name: "TotalEnergies"),
        ChargingNetwork(id: ChargingNetwork.ID("trugo"), name: "Trugo"),
        ChargingNetwork(id: ChargingNetwork.ID("zes"), name: "ZES"),
    ]

    func networks(matching query: String) async throws -> [ChargingNetwork] {
        query.isEmpty ? Self.networks : Self.networks.filter { $0.name.localizedStandardContains(query) }
    }

    func networks(withIDs ids: [ChargingNetwork.ID]) async throws -> [ChargingNetwork] {
        ids.compactMap { id in Self.networks.first { $0.id == id } }
    }
}

/// CLAUDE.md 6.7 test matrisi: boş ve dolu × iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu.
struct PreviewMatrix<Content: View>: View {
    private static var devices: [String] { ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"] }
    private static var typeSizes: [DynamicTypeSize] { [.large, .xxxLarge] }
    private static var schemes: [ColorScheme] { [.light, .dark] }

    let content: (PreviewPreferencesStore) -> Content

    var body: some View {
        ForEach([false, true], id: \.self) { isFilled in
            ForEach(Self.devices, id: \.self) { device in
                ForEach(Self.typeSizes, id: \.self) { typeSize in
                    ForEach(Self.schemes, id: \.self) { scheme in
                        content(isFilled ? .filled : .empty)
                            .environment(\.dynamicTypeSize, typeSize)
                            .preferredColorScheme(scheme)
                            .previewDevice(PreviewDevice(rawValue: device))
                            .previewDisplayName(
                                "\(isFilled ? "Dolu" : "Boş") · \(device) · \(typeSize) · "
                                    + (scheme == .dark ? "koyu" : "açık")
                            )
                    }
                }
            }
        }
    }
}

/// Alt sayfaları, modelin yüklenmiş haliyle gösterir.
struct PreviewPageHost<Content: View>: View {
    @State private var model: RoutePreferencesModel
    private let content: (RoutePreferencesModel) -> Content

    init(store: PreviewPreferencesStore, @ViewBuilder content: @escaping (RoutePreferencesModel) -> Content) {
        _model = State(initialValue: RoutePreferencesModel(store: store, catalog: PreviewNetworkCatalog()))
        self.content = content
    }

    var body: some View {
        NavigationStack { content(model) }
            .task { await model.load() }
    }
}

struct PlanOptionsViewPreviews: PreviewProvider {
    static var previews: some View {
        PreviewMatrix { store in
            PlanOptionsView(preferencesStore: store, networkCatalog: PreviewNetworkCatalog(), onClose: {})
        }
    }
}

struct ChargingNetworksViewPreviews: PreviewProvider {
    static var previews: some View {
        PreviewMatrix { store in
            PreviewPageHost(store: store) { model in
                ChargingNetworksView(model: model, onAdd: { _ in }, onBack: {}, onClose: {})
            }
        }
    }
}

struct NetworkPickerViewPreviews: PreviewProvider {
    static var previews: some View {
        PreviewMatrix { store in
            PreviewPageHost(store: store) { model in
                NetworkPickerView(
                    model: NetworkPickerModel(mode: .avoid, preferences: model, catalog: PreviewNetworkCatalog()),
                    onBack: {},
                    onClose: {}
                )
            }
        }
    }
}
#endif
