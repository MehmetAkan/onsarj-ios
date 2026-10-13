/// Uygulamadaki gezinme hedefleri.
///
/// Kök ekran (karşılama) burada yer almaz; yığının tabanıdır. Her yeni ekran
/// buraya bir durum olarak eklenir ve `RootView` içinde karşılığı tanımlanır.
enum Route: Hashable {
    case phoneEntry
}
