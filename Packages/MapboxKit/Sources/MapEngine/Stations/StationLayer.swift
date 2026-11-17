import MapboxMaps
import OnsarjDomain
import UIKit

/// Haritadaki istasyon katmanı (CLAUDE.md 5.4): GeoJSON kaynağı, kaynak düzeyinde kümeleme ve sembol
/// katmanları. Pinler görünüm olarak değil, stile eklenen görsellerle çizilir (`StationImageFactory`).
///
/// - **Kaynaklar:** tüm istasyonlar kümelenen kaynakta; seçili istasyon ayrıca kümelenmeyen küçük bir
///   kaynakta durur, böylece seçili pin hiçbir yakınlaşmada kümeye karışmaz ve seçim değişince binlerce
///   kayıt yeniden yüklenmez.
/// - **Katmanlar** (aşağıdan yukarı): pinler, kümeler, seçili pin. Stilin en üstüne, yer adlarının da
///   üstüne eklenir: Standard'ın `top` yuvası şehir ve semt adlarının altında kalır ve adlar pinlerin
///   üstüne biner. Kullanıcının konum noktası (`puck`) varsa katmanlar onun altına girer; nokta sonradan
///   eklenirse zaten en üste eklenir. Konum noktası pinlerin altında kalmaz.
/// - **Dokunma:** pine dokununca `onStationTapped`, kümeye dokununca kümenin açıldığı yakınlaşmaya
///   yumuşak geçiş, boş haritaya dokununca `onMapTapped`.
@MainActor
final class StationLayer {
    var onStationTapped: ((Station.ID) -> Void)?
    var onMapTapped: (() -> Void)?

    private enum ID {
        /// Mapbox'ın konum noktası katmanı.
        static let puck = "puck"
        static let source = "onsarj-stations"
        static let selectedSource = "onsarj-stations-selected"
        static let pins = "onsarj-station-pins"
        static let clusters = "onsarj-station-clusters"
        static let selectedPin = "onsarj-station-selected-pin"
    }

    private enum Property {
        static let stationID = "stationID"
        static let image = "image"
        static let pointCount = "point_count"
    }

    /// Kümeleme: birleşme yarıçapı (pt) ve kümelemenin süreceği en büyük yakınlaşma. 15 sokak düzeyidir
    /// (`MapCamera.followZoom`); orada her istasyon tek başına görünür.
    private enum Clustering {
        static let radius: Double = 50
        static let maxZoom: Double = 14
    }

    /// Kümeye dokununca yakınlaşma geçişinin süresi (sn).
    private static let expansionDuration: TimeInterval = 0.5

    private weak var mapView: MapboxMaps.MapView?
    private let images: StationImageFactory
    private var stations: [Station] = []
    private var selectedID: Station.ID?
    private var cancelables: [AnyCancelable] = []

    init(mapView: MapboxMaps.MapView, displayScale: CGFloat) {
        self.mapView = mapView
        images = StationImageFactory(displayScale: displayScale)
        observe(mapView.mapboxMap)
        addInteractions(to: mapView.mapboxMap)
    }

    /// Haritadaki istasyonlardan kimliği verilen.
    func station(withID id: Station.ID) -> Station? {
        stations.first { $0.id == id }
    }

    /// İstasyonları ve seçimi haritaya verir; yalnızca değişen kısmı günceller.
    func update(stations: [Station], selectedID: Station.ID?) {
        if stations != self.stations {
            self.stations = stations
            images.loadLogos(for: stations)
            pushStations()
        }
        if selectedID != self.selectedID {
            self.selectedID = selectedID
            pushSelection()
        }
    }

    // MARK: - Stil

    private func observe(_ map: MapboxMap) {
        map.onStyleLoaded.observe { [weak self] _ in self?.install() }.store(in: &cancelables)
        map.onStyleImageMissing
            .observe { [weak self, weak map] event in
                guard let self, let map, let image = images.image(named: event.imageId) else { return }
                try? map.addImage(image, id: event.imageId)
            }
            .store(in: &cancelables)
        images.onImagesChanged = { [weak map] redrawn in
            guard let map else { return }
            for (key, image) in redrawn where map.imageExists(withId: key.name) {
                try? map.addImage(image, id: key.name)
            }
        }
    }

    /// Stil her yüklendiğinde (tema değişimi dahil) kaynaklar ve katmanlar yeniden kurulur.
    private func install() {
        guard let map = mapView?.mapboxMap, !map.sourceExists(withId: ID.source) else { return }
        var source = GeoJSONSource(id: ID.source)
        source.data = .featureCollection(FeatureCollection(features: []))
        source.cluster = true
        source.clusterRadius = Clustering.radius
        source.clusterMaxZoom = Clustering.maxZoom
        var selectedSource = GeoJSONSource(id: ID.selectedSource)
        selectedSource.data = .featureCollection(FeatureCollection(features: []))
        try? map.addSource(source)
        try? map.addSource(selectedSource)
        let position: LayerPosition? = map.layerExists(withId: ID.puck) ? .below(ID.puck) : nil
        try? map.addLayer(pinLayer(id: ID.pins, source: ID.source, isSelected: false), layerPosition: position)
        try? map.addLayer(clusterLayer(), layerPosition: position)
        try? map.addLayer(
            pinLayer(id: ID.selectedPin, source: ID.selectedSource, isSelected: true), layerPosition: position)
        pushStations()
        pushSelection()
    }

    private func pinLayer(id: String, source: String, isSelected: Bool) -> SymbolLayer {
        var layer = SymbolLayer(id: id, source: source)
        layer.filter = pinFilter(excluding: nil)
        layer.iconImage = .expression(Exp(.get) { Property.image })
        layer.iconAnchor = .constant(.bottom)
        let anchor = Double(StationPinView.Metrics.anchorFromBottom(isSelected: isSelected))
        layer.iconOffset = .constant([0, anchor])
        layer.iconAllowOverlap = .constant(true)
        layer.iconIgnorePlacement = .constant(true)
        layer.iconEmissiveStrength = .constant(1)
        return layer
    }

    /// Küme görselinin adı: ön ek ve sayı yazısı (1000 ve üstü "999+", `StationClusterView.label`).
    private func clusterLayer() -> SymbolLayer {
        let maximum = StationClusterView.Metrics.maximumShownCount
        var layer = SymbolLayer(id: ID.clusters, source: ID.source)
        layer.filter = Exp(.has) { Property.pointCount }
        layer.iconImage = .expression(
            Exp(.concat) {
                StationImageKey.clusterPrefix
                Exp(.switchCase) {
                    Exp(.gt) {
                        Exp(.get) { Property.pointCount }
                        Double(maximum)
                    }
                    "\(maximum)+"
                    Exp(.toString) { Exp(.get) { Property.pointCount } }
                }
            })
        layer.iconAllowOverlap = .constant(true)
        layer.iconIgnorePlacement = .constant(true)
        layer.iconEmissiveStrength = .constant(1)
        return layer
    }

    /// Kümelenmemiş pinler; seçili istasyon kendi katmanında çizildiği için burada atlanır.
    private func pinFilter(excluding id: Station.ID?) -> Exp {
        Exp(.all) {
            Exp(.not) { Exp(.has) { Property.pointCount } }
            Exp(.neq) {
                Exp(.get) { Property.stationID }
                id?.rawValue ?? ""
            }
        }
    }

    // MARK: - Veri

    private func pushStations() {
        guard let map = mapView?.mapboxMap, map.sourceExists(withId: ID.source) else { return }
        let features = stations.map { feature(for: $0, isSelected: false) }
        map.updateGeoJSONSource(withId: ID.source, geoJSON: .featureCollection(FeatureCollection(features: features)))
    }

    private func pushSelection() {
        guard let map = mapView?.mapboxMap, map.sourceExists(withId: ID.selectedSource) else { return }
        let selected = selectedID.flatMap(station(withID:)).map { [feature(for: $0, isSelected: true)] } ?? []
        map.updateGeoJSONSource(
            withId: ID.selectedSource, geoJSON: .featureCollection(FeatureCollection(features: selected)))
        let filter = pinFilter(excluding: selectedID)
        try? map.updateLayer(withId: ID.pins, type: SymbolLayer.self) { $0.filter = filter }
    }

    private func feature(for station: Station, isSelected: Bool) -> Feature {
        let image = StationImageKey.pin(
            network: station.network.id, availability: station.availability, isSelected: isSelected)
        var feature = Feature(
            geometry: Point(
                CLLocationCoordinate2D(
                    latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)))
        feature.identifier = .string(station.id.rawValue)
        feature.properties = [
            Property.stationID: .string(station.id.rawValue),
            Property.image: .string(image.name),
        ]
        return feature
    }

    // MARK: - Dokunma

    private func addInteractions(to map: MapboxMap) {
        for layer in [ID.pins, ID.selectedPin] {
            cancelables.append(
                AnyCancelable(
                    map.addInteraction(
                        TapInteraction(.layer(layer)) { [weak self] feature, _ in
                            guard case .string(let id)? = feature.properties[Property.stationID] else { return false }
                            self?.onStationTapped?(Station.ID(id))
                            return true
                        }
                    )))
        }
        cancelables.append(
            AnyCancelable(
                map.addInteraction(
                    TapInteraction(.layer(ID.clusters)) { [weak self] feature, context in
                        self?.expandCluster(feature.originalFeature, at: context.coordinate)
                        return true
                    }
                )))
        cancelables.append(
            AnyCancelable(
                map.addInteraction(
                    TapInteraction { [weak self] _ in
                        self?.onMapTapped?()
                        return false
                    }
                )))
    }

    /// Haritayı kümenin dağıldığı yakınlaşmaya, kümenin üzerine yumuşakça götürür.
    private func expandCluster(_ cluster: Feature, at coordinate: CLLocationCoordinate2D) {
        guard let mapView else { return }
        let center: CLLocationCoordinate2D =
            if case .point(let point)? = cluster.geometry { point.coordinates } else { coordinate }
        let expand = { [weak mapView] (result: Result<FeatureExtensionValue, Error>) in
            guard let mapView, case .success(let value) = result, let zoom = (value.value as? NSNumber)?.doubleValue
            else { return }
            mapView.viewport.idle()
            mapView.camera.ease(to: CameraOptions(center: center, zoom: zoom), duration: Self.expansionDuration)
        }
        mapView.mapboxMap.getGeoJsonClusterExpansionZoom(forSourceId: ID.source, feature: cluster, completion: expand)
    }
}
