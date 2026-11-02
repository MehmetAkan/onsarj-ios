import CoreLocation
import DesignSystem
import Localization
import LocationKit
import MapEngine
import SwiftUI
import UIKit

/// Ana harita ekranı: tam ekran harita, kullanıcının konumu ve "konumuma dön" butonu.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1). Harita stili cihazın temasını izler.
public struct HomeMapView: View {
    @State private var model: HomeMapModel
    @Environment(\.openURL) private var openURL

    /// - Parameter locationSource: Uygulama boyunca paylaşılan konum kaynağı.
    public init(locationSource: any LocationSource) {
        self.init(model: HomeMapModel(locationSource: locationSource))
    }

    init(model: HomeMapModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView(camera: model.camera, userLocation: model.userLocation)
                .ignoresSafeArea()

            RecenterButton(isFollowingUser: model.camera.isFollowingUser, action: model.recenter)
                .padding(.trailing, Spacing.screenMargin)
                // Mapbox bilgi butonu sağ alt köşededir ve görünür kalmalıdır (CLAUDE.md bölüm 7);
                // buton onun üstünde durur.
                .padding(.bottom, Spacing.xxxl)
        }
        .task { await model.observeAuthorization() }
        .task { await model.observeLocation() }
        .alert(
            Text("home.map.locationDenied.title", bundle: .onsarj),
            isPresented: $model.isLocationDeniedAlertPresented
        ) {
            Button(action: openSettings) {
                Text("home.map.locationDenied.openSettings", bundle: .onsarj)
            }
            Button(role: .cancel) {
            } label: {
                Text("home.map.locationDenied.cancel", bundle: .onsarj)
            }
        } message: {
            Text("home.map.locationDenied.message", bundle: .onsarj)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × açık ve koyu tema.
///
/// Önizlemede harita çizilmeyebilir: Mapbox token'ı ve ağ gerekir. Buton ve yerleşim görünür.
struct HomeMapViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let schemes: [ColorScheme] = [.light, .dark]

    static var previews: some View {
        ForEach(devices, id: \.self) { device in
            ForEach(schemes, id: \.self) { scheme in
                screen
                    .preferredColorScheme(scheme)
                    .previewDevice(PreviewDevice(rawValue: device))
                    .previewDisplayName("\(device) · \(scheme == .dark ? "koyu" : "açık")")
            }
        }
    }

    @MainActor
    private static var screen: some View {
        HomeMapView(locationSource: PreviewLocationSource())
    }
}

/// Önizleme için konum kaynağı: izin sorulmamış, konum yok.
@MainActor
private final class PreviewLocationSource: LocationSource {
    let authorization = LocationAuthorization.notDetermined

    func requestAuthorization() {}

    func authorizationUpdates() -> AsyncStream<LocationAuthorization> {
        AsyncStream { $0.yield(authorization) }
    }

    func locationUpdates() -> AsyncStream<CLLocation> {
        AsyncStream { _ in }
    }
}
#endif
