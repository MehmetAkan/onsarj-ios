import OnsarjDomain

/// Ana sayfanın alt sayfasındaki öğelerin dışarı verdiği sinyaller.
///
/// Hiçbiri ekran açmaz; geçişe `HomeMapView`'ın kapanışları üzerinden App katmanı karar verir
/// (CLAUDE.md 5.3 kural 1).
struct HomeSheetActions {
    /// Arama alanına dokunuldu.
    var search: () -> Void
    /// Yapay zekâ asistanı butonuna dokunuldu.
    var assistant: () -> Void
    /// Kategori şeridinde bir çipe dokunuldu.
    var category: (PlaceCategory) -> Void
    /// "Seçenekler" butonuna dokunuldu.
    var options: () -> Void
    /// "Kayıtlı planlar" butonuna dokunuldu.
    var savedPlans: () -> Void
}
