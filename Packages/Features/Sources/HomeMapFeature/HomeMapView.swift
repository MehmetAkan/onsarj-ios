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
/// - **Ön katman:** iki kademeli alt sayfa (`HomeBottomSheet`, `DetentSheet` üzerine, K-25) ve
///   alt sıradaki üç yüzen buton. Butonlar sayfanın üst kenarının hemen üstünde durur ve sayfayı sürüklerken
///   parmakla birlikte izler. Sayfa yalnızca kendi alanındaki dokunuşları alır. Alt sayfada araç
///   kartı (`VehicleCard`) durur.
///
/// Haritada şarj istasyonları kümelenerek gösterilir (`StationFeed`). Pine dokununca pin seçilir, harita
/// onu alt sayfanın ve butonların üstünde kalan alanın ortasına getirir; seçim `selectedStation` bağına yazılır.
/// Boş haritaya dokununca seçim kalkar. Seçimin ne açacağına uygulama katmanı karar verir.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1); kullanıcının isteklerini kapanışlarla
/// dışarı bildirir. Harita stili cihazın temasını izler.
public struct HomeMapView: View {
    @State private var model: HomeMapModel
    @State private var vehicleCard: VehicleCardModel
    @Environment(\.openURL) private var openURL
    /// Haritanın alt kenarı ve sayfanın üstündeki butonların üst kenarı (global); aradaki şerit haritanın
    /// kapanan kısmıdır.
    @State private var mapBottom: CGFloat = 0
    @State private var bottomButtonsTop: CGFloat = 0

    private let onMenu: () -> Void
    private let onSearchTapped: () -> Void
    private let onAssistant: () -> Void
    private let onCategory: (PlaceCategory) -> Void
    private let onOptions: () -> Void
    private let onSavedPlans: () -> Void
    private let onNearbyChargers: () -> Void
    private let onSavedPlaces: () -> Void
    private let onSwitchVehicle: () -> Void
    private let onVehicleSettings: (Vehicle.ID) -> Void
    private let vehicleRevision: Int
    private let onAddVehicle: () -> Void
    @Binding private var selectedStation: Station?

    /// - Parameters:
    ///   - locationSource: Uygulama boyunca paylaşılan konum kaynağı.
    ///   - vehicleRepository: Kullanıcının araçları; araç kartı etkin aracı buradan alır.
    ///   - batteryLevelStore: Araç kartındaki batarya yüzdesinin deposu.
    ///   - stationRepository: Haritadaki şarj istasyonlarının kaynağı.
    ///   - onMenu: Sol üstteki menü butonuna dokunulduğunda çağrılır.
    ///   - onSearchTapped: Arama alanına dokunulduğunda çağrılır; arama ayrı bir ekranda açılır.
    ///   - onAssistant: Arama alanının yanındaki yapay zekâ asistanı butonuna dokunulduğunda çağrılır.
    ///   - onCategory: Kategori şeridindeki bir çipe dokunulduğunda, o kategoriyle çağrılır.
    ///   - onOptions: Alt sayfadaki "Seçenekler" butonuna dokunulduğunda çağrılır.
    ///   - onSavedPlans: Alt sayfadaki "Kayıtlı planlar" butonuna dokunulduğunda çağrılır.
    ///   - onNearbyChargers: Şimşek butonuna dokunulduğunda çağrılır.
    ///   - onSavedPlaces: Yer imi butonuna dokunulduğunda çağrılır.
    ///   - onSwitchVehicle: Araç kartında araç adına dokunulduğunda çağrılır.
    ///   - onVehicleSettings: Araç kartında ayarlar simgesine dokunulduğunda, kartın aracıyla çağrılır.
    ///   - onAddVehicle: Araç yokken kartta "Araç ekle"ye dokunulduğunda çağrılır.
    ///   - selectedStation: Haritada seçili istasyon. Pine dokununca yazılır, boş haritaya dokununca `nil` olur;
    ///     dışarıdan `nil` yapılınca pin seçimi kalkar.
    ///   - vehicleRevision: Araç verisinin sürümü. Değiştiğinde (ör. araç ayarları kapandığında) kart
    ///     aracı yeniden yükler; araç silindiyse "Araç ekle" haline geçer.
    public init(
        locationSource: any LocationSource,
        vehicleRepository: any VehicleRepository,
        batteryLevelStore: any BatteryLevelStoring,
        stationRepository: any StationRepository,
        onMenu: @escaping () -> Void,
        onSearchTapped: @escaping () -> Void,
        onAssistant: @escaping () -> Void,
        onCategory: @escaping (PlaceCategory) -> Void,
        onOptions: @escaping () -> Void,
        onSavedPlans: @escaping () -> Void,
        onNearbyChargers: @escaping () -> Void,
        onSavedPlaces: @escaping () -> Void,
        onSwitchVehicle: @escaping () -> Void,
        onVehicleSettings: @escaping (Vehicle.ID) -> Void,
        onAddVehicle: @escaping () -> Void,
        selectedStation: Binding<Station?>,
        vehicleRevision: Int
    ) {
        self.init(
            model: HomeMapModel(locationSource: locationSource, stationRepository: stationRepository),
            vehicleCard: VehicleCardModel(repository: vehicleRepository, batteryStore: batteryLevelStore),
            onMenu: onMenu,
            onSearchTapped: onSearchTapped,
            onAssistant: onAssistant,
            onCategory: onCategory,
            onOptions: onOptions,
            onSavedPlans: onSavedPlans,
            onNearbyChargers: onNearbyChargers,
            onSavedPlaces: onSavedPlaces,
            onSwitchVehicle: onSwitchVehicle,
            onVehicleSettings: onVehicleSettings,
            onAddVehicle: onAddVehicle,
            selectedStation: selectedStation,
            vehicleRevision: vehicleRevision
        )
    }

    init(
        model: HomeMapModel,
        vehicleCard: VehicleCardModel,
        onMenu: @escaping () -> Void = {},
        onSearchTapped: @escaping () -> Void = {},
        onAssistant: @escaping () -> Void = {},
        onCategory: @escaping (PlaceCategory) -> Void = { _ in },
        onOptions: @escaping () -> Void = {},
        onSavedPlans: @escaping () -> Void = {},
        onNearbyChargers: @escaping () -> Void = {},
        onSavedPlaces: @escaping () -> Void = {},
        onSwitchVehicle: @escaping () -> Void = {},
        onVehicleSettings: @escaping (Vehicle.ID) -> Void = { _ in },
        onAddVehicle: @escaping () -> Void = {},
        selectedStation: Binding<Station?> = .constant(nil),
        vehicleRevision: Int = 0
    ) {
        _model = State(initialValue: model)
        _vehicleCard = State(initialValue: vehicleCard)
        self.onMenu = onMenu
        self.onSearchTapped = onSearchTapped
        self.onAssistant = onAssistant
        self.onCategory = onCategory
        self.onOptions = onOptions
        self.onSavedPlans = onSavedPlans
        self.onNearbyChargers = onNearbyChargers
        self.onSavedPlaces = onSavedPlaces
        self.onSwitchVehicle = onSwitchVehicle
        self.onVehicleSettings = onVehicleSettings
        self.onAddVehicle = onAddVehicle
        _selectedStation = selectedStation
        self.vehicleRevision = vehicleRevision
    }

    public var body: some View {
        ZStack {
            MapView(
                camera: model.camera,
                userLocation: model.userLocation,
                controlsLayout: Self.mapControlsLayout,
                stations: mapStations
            )
            .ignoresSafeArea()
            .onGeometryChange(for: CGFloat.self) {
                $0.frame(in: .global).maxY
            } action: {
                mapBottom = $0
            }

            menuButton

            HomeBottomSheet(detent: $model.sheetDetent, actions: sheetActions, vehicleCard: vehicleCard) {
                bottomButtons
                    .onGeometryChange(for: CGFloat.self) {
                        $0.frame(in: .global).minY
                    } action: {
                        bottomButtonsTop = $0
                    }
            }
        }
        .task { await model.observeAuthorization() }
        .task { await model.observeLocation() }
        .task { await vehicleCard.load() }
        .onChange(of: vehicleRevision) {
            Task { await vehicleCard.refresh() }
        }
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

    // MARK: - İstasyonlar

    private var mapStations: MapStations {
        MapStations(
            stations: model.stationFeed.stations,
            selectedID: selectedStation?.id,
            obscuredBottom: max(0, mapBottom - bottomButtonsTop),
            onStationTapped: { id in
                selectedStation = model.station(withID: id)
            },
            onMapTapped: { selectedStation = nil },
            onCameraIdle: model.stationFeed.cameraDidIdle
        )
    }

    // MARK: - Yüzen butonlar

    /// Menü butonunun bulunduğu üst sıra. Mapbox'ın bilgi butonu bu sıranın sağ ucunda, menü
    /// butonuyla aynı hizada; ölçek çubuğu menü butonunun sağında durur.
    private static let mapControlsLayout = MapControlsLayout(
        top: Spacing.sm,
        horizontalMargin: Spacing.screenMargin,
        rowHeight: Spacing.minTapTarget,
        spacing: Spacing.sm
    )

    private var menuButton: some View {
        FloatingMapButton(
            icon: .profile,
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
                icon: .charger,
                accessibilityLabel: "home.accessibility.nearbyChargers",
                bundle: .onsarj,
                action: onNearbyChargers
            )
            RecenterButton(isFollowingUser: model.camera.isFollowingUser, action: model.recenter)
            Spacer()
            FloatingMapButton(
                icon: .savedPlaces,
                accessibilityLabel: "home.accessibility.savedPlaces",
                bundle: .onsarj,
                action: onSavedPlaces
            )
        }
        .padding(.horizontal, Spacing.screenMargin)
    }

    private var sheetActions: HomeSheetActions {
        HomeSheetActions(
            search: onSearchTapped,
            assistant: onAssistant,
            category: onCategory,
            options: onOptions,
            savedPlans: onSavedPlans,
            switchVehicle: onSwitchVehicle,
            vehicleSettings: onVehicleSettings,
            addVehicle: onAddVehicle
        )
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu tema,
/// orta kademede. Ayrıca iki kademe, en zor durum olan SE + `xxxLarge` üzerinde.
///
/// Önizlemede harita çizilmeyebilir: Mapbox token'ı ve ağ gerekir. Butonlar ve sayfa görünür.
struct HomeMapViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let schemes: [ColorScheme] = [.light, .dark]
    private static let detents: [HomeMapModel.SheetDetent] = [.collapsed, .medium]

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
        let model = HomeMapModel(locationSource: PreviewLocationSource(), stationRepository: PreviewStationRepository())
        model.sheetDetent = detent
        let vehicleCard = VehicleCardModel(
            repository: PreviewVehicleRepository(content: .vehicle(PreviewVehicleRepository.dolphin)),
            batteryStore: PreviewBatteryLevelStore(percent: nil)
        )
        return HomeMapView(model: model, vehicleCard: vehicleCard)
    }
}

/// Önizleme için istasyon deposu: önizlemede harita çizilmediği için boş.
private struct PreviewStationRepository: StationRepository {
    func stations(in box: GeoBoundingBox) async throws -> [Station] { [] }

    func stationDetail(_ id: Station.ID) async throws -> StationDetail {
        throw StationRepositoryError.stationNotFound
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
