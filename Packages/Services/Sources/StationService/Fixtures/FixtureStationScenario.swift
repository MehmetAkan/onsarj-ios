// Geçici (K-23): istasyon katmanını kodu değiştirmeden farklı yoğunlukta denemek için. Yalnızca Debug
// derlemesinde var.
#if DEBUG
/// Fixture istasyon deposunun senaryosu.
///
/// Uygulama başlatma argümanıyla seçilir: `-onsarjStationScenario <değer>`. Argüman
/// `UserDefaults.standard`'a `userDefaultsKey` anahtarıyla düşer.
public enum FixtureStationScenario: String, Sendable {
    /// Elle yazılmış liste: Antalya'da ~40, İstanbul ve Ankara'da birkaçar istasyon.
    case `default`
    /// Kümeleme ve performans sınaması: Antalya çevresinde sabit tohumla üretilen 1000 istasyon.
    case dense

    /// Başlatma argümanının `UserDefaults` anahtarı.
    public static let userDefaultsKey = "onsarjStationScenario"

    /// - Parameter value: Argümanın değeri; yoksa veya tanınmıyorsa `default`.
    public init(value: String?) {
        self = value.flatMap(Self.init(rawValue:)) ?? .default
    }
}
#endif
