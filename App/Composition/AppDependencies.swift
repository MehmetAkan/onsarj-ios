import LocationKit
import PhoneNumbers

/// Uygulama boyunca paylaşılan bağımlılıklar (CLAUDE.md 5.3 kural 2 ve 7).
///
/// Somut nesneler yalnızca burada oluşturulur ve ekranlara `init` ile verilir.
@MainActor
final class AppDependencies {
    /// Telefon numarası kuralları. Metadata yüklemesi pahalıdır; tek örnek paylaşılır ve
    /// ilk ihtiyaçta oluşturulur, böylece açılış süresine eklenmez.
    private(set) lazy var phoneNumberFormatter = PhoneNumberFormatter()

    /// Cihazın konumu ve konum izni. Tek örnek: harita ve ileride navigasyon aynı akışı dinler.
    private(set) lazy var locationSource: any LocationSource = DeviceLocationSource()
}
