import CoreLocation
import Foundation
import LocationKit
import Testing

@testable import HomeMapFeature

@MainActor
@Suite("HomeMapModel")
struct HomeMapModelTests {
    @Test("İzin daha önce verilmişse açılışta kamera kullanıcının konumuna gider")
    func followsUserWhenAlreadyAuthorized() {
        let model = HomeMapModel(locationSource: FakeLocationSource(authorization: .authorized))

        #expect(model.camera.isFollowingUser)
    }

    @Test("İzin sorulmamışsa açılışta izin istenmez, kamera başlangıç konumunda kalır")
    func doesNotRequestOnLaunch() {
        let source = FakeLocationSource(authorization: .notDetermined)
        let model = HomeMapModel(locationSource: source)

        #expect(source.requestCount == 0)
        #expect(!model.camera.isFollowingUser)
    }

    @Test("Butona ilk dokunuşta izin istenir; izin verilince kamera konuma gider")
    func requestsOnFirstTapThenFollows() {
        let source = FakeLocationSource(authorization: .notDetermined)
        let model = HomeMapModel(locationSource: source)

        model.recenter()
        #expect(source.requestCount == 1)
        #expect(!model.camera.isFollowingUser)

        model.apply(.authorized)
        #expect(model.camera.isFollowingUser)
    }

    @Test("Butona dokunulmadan gelen izin kamerayı hareket ettirmez")
    func authorizationWithoutTapDoesNotFollow() {
        let model = HomeMapModel(locationSource: FakeLocationSource(authorization: .notDetermined))

        model.apply(.authorized)

        #expect(!model.camera.isFollowingUser)
    }

    @Test("Harita cihazın bölgesindeki ülkenin üzerinde açılır")
    func initialRegionFollowsLocale() {
        let model = HomeMapModel(
            locationSource: FakeLocationSource(authorization: .notDetermined),
            locale: Locale(identifier: "de_DE")
        )
        let germany = CountryBounds.forRegionCode("DE")

        #expect(model.camera.initialRegion?.west == germany?.west)
        #expect(model.camera.initialRegion?.north == germany?.north)
    }

    @Test("Bölge belirlenemezse harita yedek ülkede açılır")
    func initialRegionFallsBack() {
        let model = HomeMapModel(
            locationSource: FakeLocationSource(authorization: .notDetermined),
            locale: Locale(identifier: "en")
        )
        let fallback = CountryBounds.forRegionCode(CountryBounds.fallbackRegionCode)

        #expect(model.camera.initialRegion?.west == fallback?.west)
        #expect(model.camera.initialRegion?.south == fallback?.south)
    }

    @Test("İzin reddedilmişse buton izin istemez, Ayarlar uyarısını açar")
    func deniedShowsSettingsAlert() {
        let source = FakeLocationSource(authorization: .denied)
        let model = HomeMapModel(locationSource: source)

        model.recenter()

        #expect(source.requestCount == 0)
        #expect(model.isLocationDeniedAlertPresented)
    }

    @Test("İzin sonradan geri alınırsa konum göstergesi kaldırılır")
    func revokedAuthorizationClearsLocation() async {
        let source = FakeLocationSource(authorization: .authorized)
        let model = HomeMapModel(locationSource: source)
        let observation = Task { await model.observeLocation() }
        while !source.hasLocationSubscriber {
            await Task.yield()
        }
        source.send(CLLocation(latitude: 41.0, longitude: 29.0))
        while model.userLocation == nil {
            await Task.yield()
        }

        model.apply(.denied)

        #expect(model.userLocation == nil)
        observation.cancel()
    }
}

@MainActor
private final class FakeLocationSource: LocationSource {
    private(set) var authorization: LocationAuthorization
    private(set) var requestCount = 0
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?

    init(authorization: LocationAuthorization) {
        self.authorization = authorization
    }

    func requestAuthorization() {
        requestCount += 1
    }

    func authorizationUpdates() -> AsyncStream<LocationAuthorization> {
        AsyncStream { $0.yield(authorization) }
    }

    func locationUpdates() -> AsyncStream<CLLocation> {
        let (stream, continuation) = AsyncStream.makeStream(of: CLLocation.self)
        locationContinuation = continuation
        return stream
    }

    var hasLocationSubscriber: Bool {
        locationContinuation != nil
    }

    func send(_ location: CLLocation) {
        locationContinuation?.yield(location)
    }
}
