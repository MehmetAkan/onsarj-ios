import Observation

/// Haritanın kamerası: başlangıç bölgesi ve kullanıcının konumunu izleme.
///
/// Ekran modeli kamerayı oluşturur ve `MapView`'a verir. Model kameraya ne istediğini söyler
/// (`followUser()`); kameranın haritayı nasıl hareket ettireceği `MapView`'un işidir.
/// Harita henüz ekrana gelmeden verilen istek saklanır ve harita kurulunca uygulanır.
@MainActor
@Observable
public final class MapCamera {
    /// Haritada bir bölge: sınır kutusu, derece cinsinden. `west <= east`; 180. boylamı geçmez.
    public struct Region: Sendable, Equatable {
        public let west: Double
        public let south: Double
        public let east: Double
        public let north: Double

        public init(west: Double, south: Double, east: Double, north: Double) {
            self.west = west
            self.south = south
            self.east = east
            self.north = north
        }
    }

    /// Kullanıcının konumu izlenirken kullanılan yakınlaştırma: sokak düzeyi.
    static let followZoom: Double = 15

    /// Harita ilk açıldığında ekrana sığdırılan bölge. `nil` ise harita dünyanın tamamıyla açılır.
    public let initialRegion: Region?

    /// Kamera kullanıcının konumunu izliyor mu.
    ///
    /// `followUser()` ile `true` olur. Kullanıcı haritayı elle kaydırınca kamera izlemeyi
    /// bırakır ve değer `false` olur.
    public internal(set) var isFollowingUser = false

    /// Kamera isteklerini haritaya uygulayan nesne; `MapView` kurulunca bağlanır.
    @ObservationIgnored weak var driver: (any MapCameraDriver)?

    public init(initialRegion: Region?) {
        self.initialRegion = initialRegion
    }

    /// Kamerayı kullanıcının konumuna götürür ve konum değiştikçe izler.
    ///
    /// Konum henüz bilinmiyorsa kamera ilk konum geldiğinde oraya gider.
    public func followUser() {
        isFollowingUser = true
        driver?.followUser()
    }
}

/// `MapCamera` isteklerini haritaya uygulayan taraf.
@MainActor
protocol MapCameraDriver: AnyObject {
    func followUser()
}
