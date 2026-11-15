/// Arama sayfasındaki bir satır: öneri, geçmiş araması veya şarj istasyonu.
///
/// Arama sonuçlarının kaynağı henüz kararlaştırılmadı; satırlar uygulama katmanından kapanışlarla
/// gelir. Tip yalnızca bu özelliğe aittir, Domain'e girmez.
public struct SearchRow: Sendable, Identifiable, Hashable {
    public enum Kind: Sendable, Hashable {
        /// Konum önerisi.
        case place
        /// Geçmişteki bir arama.
        case history
        /// Şarj istasyonu.
        case charger
    }

    public let id: String
    public let kind: Kind
    /// Görünen başlık. İstasyonlarda `İstasyon adı • Yer` biçimindedir.
    public let title: String

    public init(id: String, kind: Kind, title: String) {
        self.id = id
        self.kind = kind
        self.title = title
    }
}
