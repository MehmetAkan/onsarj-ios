import Observation
import OnsarjDomain

/// Özellikler arası tek geçiş noktası (CLAUDE.md 5.3 kural 1).
///
/// Özellik ekranları kendi geçişini yapmaz; kullanıcının isteğini kapanışlarla dışarı
/// bildirir. Bu istekler burada gezinme yığınına çevrilir.
@MainActor
@Observable
final class AppRouter {
    /// Uygulamanın hangi akışta olduğu. Her akışın kendi kök ekranı vardır.
    enum Flow: Equatable {
        /// Karşılama ekranıyla başlayan kayıt akışı.
        case signUp
        /// Ana harita.
        case home
    }

    /// Şu anki akış.
    private(set) var flow: Flow

    /// Kök ekranın üzerindeki ekranlar, alttan üste.
    var path: [Route] = []

    /// Arama sayfası ana haritanın üstünde büyük bir modal olarak açık mı (K-25).
    var isSearchPresented = false

    /// Plan seçenekleri (ve ondan açılan şarj ağları sayfaları) ana haritanın üstünde modal olarak açık mı.
    var isPlanOptionsPresented = false

    /// Ayarları açık olan araç; `nil` ise araç ayarları modalı kapalı.
    var vehicleSettings: VehicleSettingsPresentation?

    /// "Araçlarınız" / "Araç ekle" modalı; `nil` ise kapalı.
    var garage: GaragePresentation?

    /// Haritada seçili istasyon; seçiliyken istasyon detay sayfası açıktır. Sayfa kapanınca `nil` olur ve
    /// haritadaki pin seçimi kalkar.
    var selectedStation: Station?

    /// Araç verisinin sürümü. Araç ayarları veya garaj modalı kapanınca artar; ana sayfadaki kart aracı
    /// yeniden yükler.
    private(set) var vehicleRevision = 0

    /// Araçları değiştirebilen bir modal kapandı (X, aşağı çekme, araç seçildi, eklendi veya silindi).
    func vehiclesDidChange() {
        vehicleRevision += 1
    }

    /// - Parameter flow: Açılıştaki akış.
    init(flow: Flow = .signUp) {
        self.flow = flow
    }

    /// Kayıt akışını bitirir ve ana haritaya geçer.
    ///
    /// Kayıt ekranları yığından tamamen çıkarılır; ana haritadan geri dönerek kayıt
    /// akışına ulaşılamaz.
    func completeSignUp() {
        path.removeAll()
        flow = .home
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// En üstteki ekranı `route` ile değiştirir; geri dönüldüğünde değiştirilen ekrana
    /// değil, onun altındakine gidilir. Yığın boşsa `route` eklenir.
    ///
    /// Bir daha açılmaması gereken ekranlar için kullanılır (ör. harcanmış SMS kodu ekranı).
    func replaceTop(with route: Route) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }
}

/// Araç ayarları modalının sunumu: hangi aracın ayarları açık.
struct VehicleSettingsPresentation: Identifiable, Equatable {
    let vehicleID: Vehicle.ID

    var id: String { vehicleID.rawValue }
}

/// "Araçlarınız" / "Araç ekle" modalının sunumu: hangi sayfayla açıldığı.
enum GaragePresentation: String, Identifiable {
    /// Kartın adı ve okundan: araç listesi.
    case vehicles
    /// Araç yokken kartın "Araç ekle"sinden: markalar.
    case addVehicle

    var id: String { rawValue }
}
