import Combine
import CoreLocation
import DesignSystem
import MapboxMaps
import SwiftUI

/// Mapbox haritasının SwiftUI sarmalayıcısı.
///
/// Dışarıya Mapbox tipi açılmaz (CLAUDE.md 5.3 kural 3): görünüm, içinde Mapbox haritasını
/// barındıran sade bir `UIView` döndürür; stil, kamera ve konum `MapEngine`'in kendi
/// tipleriyle verilir.
///
/// - **Stil:** Ortamın renk temasına göre seçilir ve tema değişince kendiliğinden değişir.
/// - **Konum göstergesi:** `userLocation` verildikçe çizilir; `nil` iken gizlenir. Harita kendi
///   konum yöneticisini çalıştırmaz ve konum izni istemez; izin akışı uygulamanın işidir.
/// - **Kaynak gösterimi:** Mapbox logosu ve bilgi butonu varsayılan yerlerinde görünür kalır
///   (CLAUDE.md bölüm 7); üstüne öğe yerleştiren ekran onlara yer bırakır.
public struct MapView: UIViewRepresentable {
    private let style: MapStyle
    private let camera: MapCamera
    private let userLocation: CLLocation?

    /// - Parameters:
    ///   - style: Haritanın stili.
    ///   - camera: Başlangıç konumu ve kamera istekleri.
    ///   - userLocation: Kullanıcının son konumu; bilinmiyorsa veya izin yoksa `nil`.
    public init(style: MapStyle = .standard, camera: MapCamera, userLocation: CLLocation?) {
        self.style = style
        self.camera = camera
        self.userLocation = userLocation
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(camera: camera)
    }

    public func makeUIView(context: Context) -> UIView {
        let options = MapInitOptions(
            mapStyle: style.mapboxStyle(for: context.environment.colorScheme),
            locationDataModel: LocationDataModel(location: context.coordinator.locations.eraseToAnyPublisher())
        )
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let container = LayoutReportingView()
        container.addSubview(mapView)
        let coordinator = context.coordinator
        container.onLayout = { coordinator.applyInitialCameraIfNeeded() }
        coordinator.attach(to: mapView)
        return container
    }

    public func updateUIView(_ container: UIView, context: Context) {
        context.coordinator.apply(style.mapboxStyle(for: context.environment.colorScheme))
        context.coordinator.show(userLocation)
    }

    /// `MapView` ile harita arasındaki köprü. Dışarıdan kullanılmaz.
    @MainActor
    public final class Coordinator {
        /// Konum göstergesini besleyen akış. Mapbox ana iş parçacığında teslim bekler;
        /// değerler yalnızca `@MainActor` üzerinden gönderilir.
        let locations = CurrentValueSubject<[Location], Never>([])

        private let camera: MapCamera
        private weak var mapView: MapboxMaps.MapView?
        private var appliedStyle: MapboxMaps.MapStyle?

        /// İlk kamera, harita boyutu belli olunca bir kez uygulanır. Bölgeyi ekrana sığdırmak
        /// için boyut gerekir; o ana kadar gelen kamera istekleri bekler.
        private var isInitialCameraApplied = false

        init(camera: MapCamera) {
            self.camera = camera
        }

        func attach(to mapView: MapboxMaps.MapView) {
            self.mapView = mapView
            appliedStyle = mapView.mapboxMap.mapStyle
            mapView.viewport.addStatusObserver(self)
            camera.driver = self
        }

        /// Kullanıcı izlenecekse kamera doğrudan konuma gider; bölgeye uğrayıp atlamaz.
        func applyInitialCameraIfNeeded() {
            guard !isInitialCameraApplied, let mapView, mapView.bounds.width > 0, mapView.bounds.height > 0 else {
                return
            }
            isInitialCameraApplied = true
            if camera.isFollowingUser {
                followUser()
            } else if let region = camera.initialRegion {
                show(region, in: mapView)
            }
        }

        /// Bölgeyi kuzey yukarı, düz bakışla ekrana sığdırır. Hesap yapılamazsa harita
        /// Mapbox'ın varsayılan görünümünde (dünya) kalır.
        private func show(_ region: MapCamera.Region, in mapView: MapboxMaps.MapView) {
            // Mapbox sığdırma hesabını haritanın kendi boyutuyla yapar; boyut haritanın kendi
            // yerleşiminde güncellenir.
            mapView.layoutIfNeeded()
            let corners = [
                CLLocationCoordinate2D(latitude: region.south, longitude: region.west),
                CLLocationCoordinate2D(latitude: region.north, longitude: region.east),
            ]
            let inset = UIEdgeInsets(top: Spacing.xl, left: Spacing.xl, bottom: Spacing.xl, right: Spacing.xl)
            let fitted = try? mapView.mapboxMap.camera(
                for: corners,
                camera: CameraOptions(bearing: 0, pitch: 0),
                coordinatesPadding: inset,
                maxZoom: nil,
                offset: nil
            )
            if let fitted {
                mapView.mapboxMap.setCamera(to: fitted)
            }
        }

        /// Stil yalnızca değiştiğinde haritaya verilir; her görünüm güncellemesinde değil.
        func apply(_ style: MapboxMaps.MapStyle) {
            guard style != appliedStyle else { return }
            appliedStyle = style
            mapView?.mapboxMap.mapStyle = style
        }

        func show(_ location: CLLocation?) {
            guard let mapView else { return }
            guard let location else {
                mapView.location.options.puckType = nil
                return
            }
            if mapView.location.options.puckType == nil {
                mapView.location.options.puckType = .puck2D(.makeDefault(showBearing: true))
                mapView.location.options.puckBearing = .course
                mapView.location.options.puckBearingEnabled = true
            }
            locations.send([Location(location)])
        }
    }
}

extension MapView.Coordinator: MapCameraDriver {
    func followUser() {
        guard isInitialCameraApplied, let viewport = mapView?.viewport else { return }
        // Ana harita kuzey yukarı ve düz bakar; yön ve eğim navigasyon ekranının işidir.
        let state = viewport.makeFollowPuckViewportState(
            options: FollowPuckViewportStateOptions(zoom: MapCamera.followZoom, bearing: nil, pitch: 0)
        )
        viewport.transition(to: state)
    }
}

extension MapView.Coordinator: @preconcurrency ViewportStatusObserver {
    /// Kullanıcı haritayı elle hareket ettirince viewport boşa düşer; kamera izlemeyi bırakır.
    public func viewportStatusDidChange(
        from fromStatus: ViewportStatus,
        to toStatus: ViewportStatus,
        reason: ViewportStatusChangeReason
    ) {
        if case .idle = toStatus {
            camera.isFollowingUser = false
        }
    }
}

/// Yerleşimi tamamlandığında haber veren kap görünüm.
private final class LayoutReportingView: UIView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

extension Location {
    fileprivate convenience init(_ location: CLLocation) {
        self.init(
            coordinate: location.coordinate,
            timestamp: location.timestamp,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            speed: location.speed >= 0 ? location.speed : nil,
            bearing: location.course >= 0 ? location.course : nil
        )
    }
}
