import Observation

/// Özellikler arası tek geçiş noktası (CLAUDE.md 5.3 kural 1).
///
/// Özellik ekranları kendi geçişini yapmaz; kullanıcının isteğini kapanışlarla dışarı
/// bildirir. Bu istekler burada gezinme yığınına çevrilir.
@MainActor
@Observable
final class AppRouter {
    /// Kök ekranın üzerindeki ekranlar, alttan üste.
    var path: [Route] = []

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
