import CoreGraphics
import OnsarjDomain

/// Haritadaki istasyon içeriği: gösterilecek istasyonlar, seçim ve kullanıcı etkileşimleri. Dışarıya
/// yalnızca Domain tipleri açılır (CLAUDE.md 5.3 kural 3).
public struct MapStations {
    /// Gösterilecek istasyonlar; harita bunları kümeleyerek çizer.
    public var stations: [Station]
    /// Seçili istasyon; pini büyür ve çerçevesi yeşil olur.
    public var selectedID: Station.ID?
    /// Seçili istasyonun konumu. Pin o an haritada yüklü olmasa da (ör. listeden uzaktaki bir istasyon
    /// seçildiğinde) harita bu noktayı ortalar; `nil` ise yüklü pinin konumu kullanılır.
    public var selectedCoordinate: GeoCoordinate?
    /// Haritanın altını kapatan alanın yüksekliği (alt sayfa ve üstündeki butonlar). Seçili pin bu alanın
    /// üstünde kalan bölgenin ortasına getirilir; seçim sürerken değer değişirse (ör. üstte bir sayfa açıldı)
    /// pin yeniden ortalanır.
    public var obscuredBottom: CGFloat
    /// Bir pine dokunulduğunda.
    public var onStationTapped: (Station.ID) -> Void
    /// Pin veya küme dışında, haritanın boş bir yerine dokunulduğunda.
    public var onMapTapped: () -> Void
    /// Kamera durduğunda, ekranda görünen bölgeyle. Kamera kullanıcının konumunu izlerken hiç durmaz;
    /// o sırada en sık saniyede bir çağrılır.
    public var onCameraIdle: (GeoBoundingBox) -> Void

    public init(
        stations: [Station] = [],
        selectedID: Station.ID? = nil,
        selectedCoordinate: GeoCoordinate? = nil,
        obscuredBottom: CGFloat = 0,
        onStationTapped: @escaping (Station.ID) -> Void = { _ in },
        onMapTapped: @escaping () -> Void = {},
        onCameraIdle: @escaping (GeoBoundingBox) -> Void = { _ in }
    ) {
        self.stations = stations
        self.selectedID = selectedID
        self.selectedCoordinate = selectedCoordinate
        self.obscuredBottom = obscuredBottom
        self.onStationTapped = onStationTapped
        self.onMapTapped = onMapTapped
        self.onCameraIdle = onCameraIdle
    }
}
