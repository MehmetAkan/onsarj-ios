// Geçici (K-23): kartın hallerini kodu değiştirmeden denemek için. Yalnızca Debug derlemesinde var.
#if DEBUG
/// Fixture araç deposunun senaryosu.
///
/// Uygulama başlatma argümanıyla seçilir: `-onsarjFixtureScenario <değer>`. Argüman
/// `UserDefaults.standard`'a `userDefaultsKey` anahtarıyla düşer.
public enum FixtureScenario: String, Sendable {
    /// Fixture aracı, görselli.
    case `default`
    /// Fixture aracı, görselsiz.
    case noImage
    /// Hiç araç yok ("Araç ekle" hali).
    case noVehicles
    /// Depo hata fırlatır (hata hali).
    case failure

    /// Başlatma argümanının `UserDefaults` anahtarı.
    public static let userDefaultsKey = "onsarjFixtureScenario"

    /// - Parameter value: Argümanın değeri; yoksa veya tanınmıyorsa `default`.
    public init(value: String?) {
        self = value.flatMap(Self.init(rawValue:)) ?? .default
    }
}
#endif
