import CoreLocation
import DesignSystem
import Foundation
import LocationKit
import MapEngine
import Observation
import OnsarjDomain

/// Ana harita ekranının durumu: kamera, konum izni ve kullanıcının konumu.
///
/// Konum izni açılışta değil, kullanıcı "konumuma dön" butonuna ilk dokunduğunda istenir
/// (CLAUDE.md bölüm 7). İzin daha önce verilmişse kamera açılışta kullanıcının konumuna gider.
/// Konum bilinmezken harita cihazın bölge ayarındaki ülkenin üzerinde açılır; bölge
/// belirlenemezse `CountryBounds.fallbackRegionCode` ülkesinde.
///
/// Haritadaki istasyonlar `StationFeed`'den gelir. Seçili istasyon ekranın dışında tutulur (`HomeMapView`'un
/// `selectedStation` bağı): detay sayfası kapanınca seçimi uygulama katmanı kaldırır.
@MainActor
@Observable
final class HomeMapModel {
    /// Alt sayfanın kademesi (`DetentSheet`, K-22, K-25).
    typealias SheetDetent = DesignSystem.SheetDetent

    let camera: MapCamera
    private(set) var authorization: LocationAuthorization
    private(set) var userLocation: CLLocation?

    /// Haritadaki istasyonlar.
    let stationFeed: StationFeed

    /// Alt sayfanın kademesi. Ekran orta kademede açılır.
    var sheetDetent: SheetDetent = .medium

    /// İzin reddedilmişken butona dokunulunca Ayarlar'a yönlendiren uyarı.
    var isLocationDeniedAlertPresented = false

    @ObservationIgnored private let locationSource: any LocationSource

    /// İzin penceresi butona dokunularak açıldıysa, izin verilince kamera konuma gider.
    @ObservationIgnored private var followsUserWhenAuthorized = false

    init(
        locationSource: any LocationSource,
        stationRepository: any StationRepository,
        stationDebounce: Duration = StationFeed.defaultDebounce,
        locale: Locale = .current
    ) {
        self.locationSource = locationSource
        stationFeed = StationFeed(repository: stationRepository, debounce: stationDebounce)
        authorization = locationSource.authorization
        camera = MapCamera(initialRegion: CountryBounds.forRegion(of: locale).map(Self.region))
        if authorization == .authorized {
            camera.followUser()
        }
    }

    /// "Konumuma dön" butonu.
    func recenter() {
        switch authorization {
        case .authorized:
            camera.followUser()
        case .notDetermined:
            followsUserWhenAuthorized = true
            locationSource.requestAuthorization()
        case .denied:
            isLocationDeniedAlertPresented = true
        }
    }

    /// Dokunulan pinin istasyonu; haritada yoksa `nil`.
    func station(withID id: Station.ID) -> Station? {
        stationFeed.stations.first { $0.id == id }
    }

    /// İzin değişikliklerini dinler. Ekran görünür kaldıkça çalışır.
    func observeAuthorization() async {
        for await authorization in locationSource.authorizationUpdates() {
            apply(authorization)
        }
    }

    /// Kullanıcının konumunu dinler. İzin yokken akış bekler, izin verilince başlar.
    func observeLocation() async {
        for await location in locationSource.locationUpdates() {
            userLocation = location
        }
    }

    private static func region(_ bounds: CountryBounds) -> MapCamera.Region {
        MapCamera.Region(west: bounds.west, south: bounds.south, east: bounds.east, north: bounds.north)
    }

    func apply(_ authorization: LocationAuthorization) {
        self.authorization = authorization
        switch authorization {
        case .authorized:
            if followsUserWhenAuthorized {
                followsUserWhenAuthorized = false
                camera.followUser()
            }
        case .denied:
            // İzin Ayarlar'dan geri alındıysa eski konum gösterilmeye devam etmez.
            followsUserWhenAuthorized = false
            userLocation = nil
        case .notDetermined:
            break
        }
    }
}
