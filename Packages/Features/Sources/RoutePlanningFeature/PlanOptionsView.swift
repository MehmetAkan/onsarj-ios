import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Plan seçenekleri modalının kökü: plan seçenekleri, şarj ağları ve ağ seçici aynı modal içinde
/// yığın geçişiyle açılır. Uygulama katmanı bu görünümü sunar; ana sayfa onu bilmez (CLAUDE.md 5.3).
///
/// Kaydet düğmesi yoktur: her değişiklik hemen saklanır. Her sayfadaki X ve aşağı çekme modalı kapatır;
/// hiçbir şey kaybolmaz. Üç sayfa aynı `RoutePreferencesModel`'i paylaşır.
public struct PlanOptionsView: View {
    enum Destination: Hashable {
        case networks
        case picker(NetworkPickerMode)
    }

    @State private var model: RoutePreferencesModel
    @State private var path: [Destination] = []
    private let catalog: any ChargingNetworkCatalog
    private let onClose: () -> Void

    /// - Parameters:
    ///   - preferencesStore: Tercihlerin deposu.
    ///   - networkCatalog: Şarj ağı kataloğu (ad çözümü ve arama).
    ///   - onClose: X'e dokunuldu; modal kapatılmalı.
    public init(
        preferencesStore: any RoutePreferencesStoring,
        networkCatalog: any ChargingNetworkCatalog,
        onClose: @escaping () -> Void
    ) {
        _model = State(initialValue: RoutePreferencesModel(store: preferencesStore, catalog: networkCatalog))
        catalog = networkCatalog
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack(path: $path) {
            PlanOptionsPage(model: model, onEditNetworks: { path.append(.networks) }, onClose: onClose)
                .navigationDestination(for: Destination.self, destination: destination)
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private func destination(_ destination: Destination) -> some View {
        switch destination {
        case .networks:
            ChargingNetworksView(
                model: model,
                onAdd: { path.append(.picker($0)) },
                onBack: pop,
                onClose: onClose
            )
        case .picker(let mode):
            NetworkPickerView(
                model: NetworkPickerModel(mode: mode, preferences: model, catalog: catalog),
                onBack: pop,
                onClose: onClose
            )
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
