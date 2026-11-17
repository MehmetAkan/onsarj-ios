import MapboxMaps
import OnsarjDomain
import UIKit

extension MapView.Coordinator {
    /// Seçili pine geçişin süresi (sn).
    private static let selectionDuration: TimeInterval = 0.4
    /// Kamera kullanıcıyı izlerken görünen bölgenin en sık bildirilme aralığı (sn).
    private static let followingReportInterval: TimeInterval = 1

    func attachStations(to mapView: MapboxMaps.MapView, displayScale: CGFloat) {
        let layer = StationLayer(mapView: mapView, displayScale: displayScale)
        layer.onStationTapped = { [weak self] id in self?.stations.onStationTapped(id) }
        layer.onMapTapped = { [weak self] in self?.stations.onMapTapped() }
        stationLayer = layer
        mapView.mapboxMap.onMapIdle.observe { [weak self] _ in self?.reportVisibleRegion() }.store(in: &cancelables)
        mapView.mapboxMap.onCameraChanged.observe { [weak self] _ in self?.reportFollowingCamera() }
            .store(in: &cancelables)
    }

    /// İstasyonları ve seçimi katmana verir; seçim yeni bir istasyona geçtiyse pini ortalar.
    func apply(_ stations: MapStations) {
        let previousSelection = self.stations.selectedID
        self.stations = stations
        stationLayer?.update(stations: stations.stations, selectedID: stations.selectedID)
        if let id = stations.selectedID, id != previousSelection, let station = stationLayer?.station(withID: id) {
            center(on: station.coordinate, obscuredBottom: stations.obscuredBottom)
        }
    }

    /// Noktayı, haritanın kapanmayan üst kısmının ortasına yakınlaşmayı değiştirmeden getirir.
    private func center(on coordinate: GeoCoordinate, obscuredBottom: CGFloat) {
        guard let mapView else { return }
        let map: MapboxMap = mapView.mapboxMap
        let target = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let padding = UIEdgeInsets(top: 0, left: 0, bottom: min(obscuredBottom, mapView.bounds.height / 2), right: 0)
        guard
            let camera = try? map.camera(
                for: [target], camera: CameraOptions(), coordinatesPadding: padding,
                maxZoom: map.cameraState.zoom, offset: nil)
        else { return }
        mapView.viewport.idle()
        mapView.camera.ease(to: CameraOptions(center: camera.center), duration: Self.selectionDuration)
    }

    /// Kamera kullanıcıyı izlerken harita hiç boşta kalmaz: konum güncellendikçe kamera hareket eder ve
    /// `onMapIdle` gelmez. Bu durumda görünen bölge kamera değiştikçe, en sık `followingReportInterval`
    /// aralıkla bildirilir. İzleme yokken (kaydırma, yakınlaşma) bölge yalnızca harita boşta kalınca bildirilir.
    private func reportFollowingCamera() {
        guard let mapView, case .state = mapView.viewport.status else { return }
        let now = Date()
        if let lastFollowingReport, now.timeIntervalSince(lastFollowingReport) < Self.followingReportInterval {
            return
        }
        lastFollowingReport = now
        reportVisibleRegion()
    }

    /// Görünen bölgeyi bildirir: harita boşta kaldığında (kamera durup karoları yüklediğinde) ve kamera
    /// kullanıcıyı izlerken. Bölge değişmediyse bildirmez.
    private func reportVisibleRegion() {
        guard let mapView, mapView.bounds.width > 0 else { return }
        let box = Self.box(from: mapView.mapboxMap.coordinateBounds(for: mapView.bounds))
        guard box != lastIdleBox else { return }
        lastIdleBox = box
        stations.onCameraIdle(box)
    }

    /// Mapbox sınırlarını Domain kutusuna çevirir. Küre görünümünde veya 180. boylamı geçen görünümde batı
    /// boylamı doğudan büyük gelebilir; o zaman kutu tüm boylamları kapsar (kutu 180. boylamı geçemez).
    static func box(from bounds: CoordinateBounds) -> GeoBoundingBox {
        let south = min(bounds.southwest.latitude, bounds.northeast.latitude)
        let north = max(bounds.southwest.latitude, bounds.northeast.latitude)
        var west = bounds.southwest.longitude
        var east = bounds.northeast.longitude
        if west > east || east - west >= 360 {
            west = -180
            east = 180
        }
        return GeoBoundingBox(
            southWest: GeoCoordinate(latitude: max(-90, south), longitude: max(-180, west)),
            northEast: GeoCoordinate(latitude: min(90, north), longitude: min(180, east))
        )
    }
}
