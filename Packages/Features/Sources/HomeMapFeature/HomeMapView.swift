import CoreLocation
import DesignSystem
import Localization
import LocationKit
import MapEngine
import OnsarjDomain
import SwiftUI
import UIKit

/// Ana harita ekranı.
///
/// İki bağımsız katmandan oluşur:
/// - **Arka plan:** tam ekran harita ve sol üstteki menü butonu. Menü butonu hiç hareket etmez.
/// - **Ön katman:** alt sayfa (`HomeBottomSheet`, `DetentSheet` üzerine) ve alt sıradaki üç
///   yüzen buton. Butonlar sayfanın üst kenarının hemen üstünde durur ve sayfayı sürüklerken
///   parmakla birlikte izler; orta kademenin üstüne çıkmaz, sayfa büyürken onların üzerinden
///   geçer. Sayfa yalnızca kendi alanındaki dokunuşları alır.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1); kullanıcının isteklerini kapanışlarla
/// dışarı bildirir. Harita stili cihazın temasını izler.
public struct HomeMapView: View {
    @State private var model: HomeMapModel
    @Environment(\.openURL) private var openURL

    private let onMenu: () -> Void
    private let onSearch: () -> Void
    private let onAssistant: () -> Void
    private let onCategory: (PlaceCategory) -> Void
    private let onOptions: () -> Void
    private let onSavedPlans: () -> Void
    private let onNearbyChargers: () -> Void
    private let onSavedPlaces: () -> Void

    /// - Parameters:
    ///   - locationSource: Uygulama boyunca paylaşılan konum kaynağı.
    ///   - onMenu: Sol üstteki menü butonuna dokunulduğunda çağrılır.
    ///   - onSearch: Arama alanına dokunulduğunda, sayfa büyük kademeye geçerken çağrılır.
    ///   - onAssistant: Arama alanının yanındaki yapay zekâ asistanı butonuna dokunulduğunda çağrılır.
    ///   - onCategory: Kategori şeridindeki bir çipe dokunulduğunda, o kategoriyle çağrılır.
    ///   - onOptions: Alt sayfadaki "Seçenekler" butonuna dokunulduğunda çağrılır.
    ///   - onSavedPlans: Alt sayfadaki "Kayıtlı planlar" butonuna dokunulduğunda çağrılır.
    ///   - onNearbyChargers: Şimşek butonuna dokunulduğunda çağrılır.
    ///   - onSavedPlaces: Yer imi butonuna dokunulduğunda çağrılır.
    public init(
        locationSource: any LocationSource,
        onMenu: @escaping () -> Void,
        onSearch: @escaping () -> Void,
        onAssistant: @escaping () -> Void,
        onCategory: @escaping (PlaceCategory) -> Void,
        onOptions: @escaping () -> Void,
        onSavedPlans: @escaping () -> Void,
        onNearbyChargers: @escaping () -> Void,
        onSavedPlaces: @escaping () -> Void
    ) {
        self.init(
            model: HomeMapModel(locationSource: locationSource),
            onMenu: onMenu,
            onSearch: onSearch,
            onAssistant: onAssistant,
            onCategory: onCategory,
            onOptions: onOptions,
            onSavedPlans: onSavedPlans,
            onNearbyChargers: onNearbyChargers,
            onSavedPlaces: onSavedPlaces
        )
    }

    init(
        model: HomeMapModel,
        onMenu: @escaping () -> Void = {},
        onSearch: @escaping () -> Void = {},
        onAssistant: @escaping () -> Void = {},
        onCategory: @escaping (PlaceCategory) -> Void = { _ in },
        onOptions: @escaping () -> Void = {},
        onSavedPlans: @escaping () -> Void = {},
        onNearbyChargers: @escaping () -> Void = {},
        onSavedPlaces: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)
        self.onMenu = onMenu
        self.onSearch = onSearch
        self.onAssistant = onAssistant
        self.onCategory = onCategory
        self.onOptions = onOptions
        self.onSavedPlans = onSavedPlans
        self.onNearbyChargers = onNearbyChargers
        self.onSavedPlaces = onSavedPlaces
    }

    public var body: some View {
        ZStack {
            MapView(camera: model.camera, userLocation: model.userLocation)
                .ignoresSafeArea()

            menuButton

            HomeBottomSheet(detent: $model.sheetDetent, actions: sheetActions) {
                bottomButtons
            }
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

    // MARK: - Yüzen butonlar

    private var menuButton: some View {
        FloatingMapButton(
            systemImage: "person.fill",
            accessibilityLabel: "home.accessibility.menu",
            bundle: .onsarj,
            action: onMenu
        )
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Sayfanın üstünde duran ve onu izleyen üç buton.
    private var bottomButtons: some View {
        HStack(spacing: Spacing.md) {
            FloatingMapButton(
                systemImage: "bolt.fill",
                accessibilityLabel: "home.accessibility.nearbyChargers",
                bundle: .onsarj,
                action: onNearbyChargers
            )
            RecenterButton(isFollowingUser: model.camera.isFollowingUser, action: model.recenter)
            Spacer()
            FloatingMapButton(
                systemImage: "bookmark.fill",
                accessibilityLabel: "home.accessibility.savedPlaces",
                bundle: .onsarj,
                action: onSavedPlaces
            )
        }
        .padding(.horizontal, Spacing.screenMargin)
    }

    private var sheetActions: HomeSheetActions {
        HomeSheetActions(
            search: beginSearch,
            assistant: onAssistant,
            category: onCategory,
            options: onOptions,
            savedPlans: onSavedPlans
        )
    }

    private func beginSearch() {
        model.beginSearch()
        onSearch()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu tema,
/// orta kademede. Ayrıca üç kademe, en zor durum olan SE + `xxxLarge` üzerinde.
///
/// Önizlemede harita çizilmeyebilir: Mapbox token'ı ve ağ gerekir. Butonlar ve sayfa görünür.
struct HomeMapViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let schemes: [ColorScheme] = [.light, .dark]
    private static let detents: [HomeMapModel.SheetDetent] = [.collapsed, .medium, .expanded]

    static var previews: some View {
        Group {
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    ForEach(schemes, id: \.self) { scheme in
                        screen(detent: .medium)
                            .environment(\.dynamicTypeSize, typeSize)
                            .preferredColorScheme(scheme)
                            .previewDevice(PreviewDevice(rawValue: device))
                            .previewDisplayName("\(device) · \(typeSize) · \(scheme == .dark ? "koyu" : "açık")")
                    }
                }
            }
            ForEach(detents, id: \.self) { detent in
                screen(detent: detent)
                    .environment(\.dynamicTypeSize, .xxxLarge)
                    .previewDevice(PreviewDevice(rawValue: devices[0]))
                    .previewDisplayName("Kademe: \(detent) · SE · xxxLarge")
            }
        }
    }

    @MainActor
    private static func screen(detent: HomeMapModel.SheetDetent) -> some View {
        let model = HomeMapModel(locationSource: PreviewLocationSource())
        model.sheetDetent = detent
        return HomeMapView(model: model)
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
