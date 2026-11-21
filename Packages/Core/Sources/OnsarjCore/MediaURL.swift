import Foundation

/// Backend yanıtlarındaki görsel adreslerini (araç görseli, ağ logosu) doğrular.
public enum MediaURL {
    /// Sunucusu olan http(s) adresleri kabul edilir; `acceptsFile` ise yolu olan `file` adresleri de
    /// (yalnızca Debug fixture'ları, K-23). `URL(string:)` geçersiz karakterleri kodlayıp yine de adres
    /// döndürebildiği için şema, sunucu ve yol ayrıca denetlenir. Kabul edilmeyen değer `nil` olur.
    public static func parse(_ string: String?, acceptsFile: Bool) -> URL? {
        guard let string, let url = URL(string: string), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        switch scheme {
        case "https", "http":
            guard let host = url.host, !host.isEmpty else { return nil }
            return url
        case "file" where acceptsFile:
            return url.path.isEmpty ? nil : url
        default:
            return nil
        }
    }
}
