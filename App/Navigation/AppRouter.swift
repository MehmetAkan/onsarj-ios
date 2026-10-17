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

    /// Yığında `route`'un üzerindeki bütün ekranları kaldırır. `route` yığında yoksa
    /// hiçbir şey yapmaz.
    func pop(to route: Route) {
        guard let index = path.lastIndex(of: route) else { return }
        path.removeSubrange(path.index(after: index)...)
    }
}
