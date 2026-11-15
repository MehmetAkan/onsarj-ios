/// Rotada kaçınılabilecek yol türleri.
public enum RouteAvoidance: Sendable, Equatable, Hashable, CaseIterable {
    /// Ücretli yollar ve köprüler.
    case tolls
    /// Otoyollar.
    case highways
    /// Feribotlar ve araba trenleri.
    case ferries
    /// Ülke sınırı geçişleri.
    case borders
}
