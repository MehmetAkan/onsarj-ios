/// Rota planlama tercihlerinin deposu.
///
/// Şimdilik cihazda; ileride backend'e taşınır. Ekranlar yalnızca bu protokolü bilir.
public protocol RoutePreferencesStoring: Sendable {
    /// Kayıtlı tercihler; kayıt yoksa veya okunamıyorsa `RoutePreferences.default`.
    func load() async -> RoutePreferences

    /// Tercihleri saklar; önceki kaydın yerine geçer.
    func save(_ preferences: RoutePreferences) async
}
