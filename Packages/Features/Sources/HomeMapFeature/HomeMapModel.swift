import CoreLocation
import Foundation
import LocationKit
import MapEngine
import Observation

/// Ana harita ekranının durumu: kamera, konum izni ve kullanıcının konumu.
///
/// Konum izni açılışta değil, kullanıcı "konumuma dön" butonuna ilk dokunduğunda istenir
/// (CLAUDE.md bölüm 7). İzin daha önce verilmişse kamera açılışta kullanıcının konumuna gider.
/// Konum bilinmezken harita cihazın bölge ayarındaki ülkenin üzerinde açılır; bölge
/// belirlenemezse `CountryBounds.fallbackRegionCode` ülkesinde.
@MainActor
@Observable
final class HomeMapModel {
    let camera: MapCamera
    private(set) var authorization: LocationAuthorization
    private(set) var userLocation: CLLocation?

    /// İzin reddedilmişken butona dokunulunca Ayarlar'a yönlendiren uyarı.
    var isLocationDeniedAlertPresented = false

    @ObservationIgnored private let locationSource: any LocationSource

    /// İzin penceresi butona dokunularak açıldıysa, izin verilince kamera konuma gider.
    @ObservationIgnored private var followsUserWhenAuthorized = false

    init(locationSource: any LocationSource, locale: Locale = .current) {
        self.locationSource = locationSource
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
