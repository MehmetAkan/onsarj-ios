import Foundation

/// Arama metinlerinin karşılaştırma biçimi: Türkçe kurallarıyla küçük harf, aksansız.
///
/// `I` → `ı` ve `İ` → `i` Türkçe kuralla küçültülür; ardından `ı` → `i` yapılır ve aksanlar atılır
/// (`ş` → `s`, `ç` → `c`, `ğ` → `g`, `ö` → `o`, `ü` → `u`). Böylece "ISTANBUL", "İstanbul", "ıstanbul"
/// ve "istanbul" aynı anahtara iner; "esarj" "Eşarj"ı bulur. Uygulamadaki tüm "içerir" aramaları
/// (şarj ağı kataloğu fixture'ı, araç markaları) bu kuralı kullanır.
public enum SearchText {
    private static let turkish = Locale(identifier: "tr_TR")

    /// Metnin karşılaştırma anahtarı.
    public static func key(_ text: String) -> String {
        text.lowercased(with: turkish)
            .replacingOccurrences(of: "ı", with: "i")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: turkish)
    }

    /// Metin, kırpılmış sorguyu (anahtar biçiminde) içeriyor mu? Boş sorgu her metinle eşleşir.
    public static func matches(_ text: String, query: String) -> Bool {
        let queryKey = key(query.trimmingCharacters(in: .whitespacesAndNewlines))
        return queryKey.isEmpty || key(text).contains(queryKey)
    }
}
