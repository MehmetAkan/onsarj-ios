// Geçici veri (K-23): yalnızca fixture kataloğunun aramasında kullanılır; gerçek katalogda arama
// backend'dedir. Fixture silindiğinde bu dosya da silinir.
#if DEBUG
import Foundation

/// Ağ adlarının aranabilir biçimi: Türkçe kurallarıyla küçük harf, aksansız.
///
/// `I` → `ı` ve `İ` → `i` Türkçe kuralla küçültülür; ardından `ı` → `i` yapılır ve aksanlar
/// atılır (`ş` → `s`, `ç` → `c`, `ğ` → `g`, `ö` → `o`, `ü` → `u`). Böylece "ISTANBUL", "İstanbul",
/// "ıstanbul" ve "istanbul" aynı anahtara iner; "esarj" "Eşarj"ı bulur.
enum NetworkSearchKey {
    private static let turkish = Locale(identifier: "tr_TR")

    static func make(_ text: String) -> String {
        text.lowercased(with: turkish)
            .replacingOccurrences(of: "ı", with: "i")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: turkish)
    }
}
#endif
