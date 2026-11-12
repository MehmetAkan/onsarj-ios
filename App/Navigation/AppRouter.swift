import Observation

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
