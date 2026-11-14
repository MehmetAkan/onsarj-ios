#if DEBUG
import Foundation
import SearchFeature

/// Arama sayfasının tasarım verisi. **Geçicidir** (K-23 ile aynı ilke): arama kaynağı
/// kararlaştırılıp bağlanınca bu dosya silinir. Yalnızca Debug derlemesinde var.
nonisolated enum SearchDesignFixtures {
    private static let rows = [
        SearchRow(id: "fixture-place-gaziantep", kind: .place, title: "Gaziantep Şehir Merkezi"),
        SearchRow(id: "fixture-history-raw-coffe", kind: .history, title: "Raw Coffe Konyaaltı"),
        SearchRow(id: "fixture-charger-trugo", kind: .charger, title: "Trugo • Antalya Dünyagöz Yaşam"),
        SearchRow(id: "fixture-charger-en-yakit", kind: .charger, title: "En Yakıt • Bolu Wender Avm"),
    ]

    /// Başlangıç halindeki geçmiş: yer önerisi dışındaki satırlar.
    static func history() -> [SearchRow] {
        rows.filter { $0.kind != .place }
    }

    /// Yazılan metni içeren satırlar; büyük-küçük harf ve aksan duyarsız, yerel süzme.
    static func suggestions(matching query: String) -> [SearchRow] {
        rows.filter { $0.title.localizedStandardContains(query) }
    }
}
#endif
