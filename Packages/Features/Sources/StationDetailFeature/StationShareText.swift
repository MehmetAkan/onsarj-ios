import Foundation
import OnsarjDomain

/// İstasyonun paylaşım metni: ad, ağ, adres ve konumu Apple Haritalar'da açan bağlantı.
///
/// Uygulama içi derin bağlantı henüz yok; bağlantı herkesin açabildiği bir harita adresidir.
enum StationShareText {
    /// Sorgu değerlerinde kodlanmadan kalabilen karakterler. `urlQueryAllowed` `&`, `=`, `+` ve `?`'i serbest
    /// bırakır; adın içindeki bu karakterler sorguyu bölmesin diye kodlanır.
    private static let queryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?#")
        return allowed
    }()

    static func text(for station: Station, address: String?) -> String {
        [station.name, station.network.name, address, mapsURL(for: station)?.absoluteString]
            .compactMap { $0 }
            .joined(separator: "\n")
    }

    /// `https://maps.apple.com/?ll=<enlem>,<boylam>&q=<ad>`; ad URL kodlamalı.
    static func mapsURL(for station: Station) -> URL? {
        let latitude = coordinate(station.coordinate.latitude)
        let longitude = coordinate(station.coordinate.longitude)
        let name = station.name.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? ""
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.path = "/"
        components.percentEncodedQuery = "ll=\(latitude),\(longitude)&q=\(name)"
        return components.url
    }

    /// Yerel ayardan bağımsız, nokta ayraçlı koordinat.
    private static func coordinate(_ value: Double) -> String {
        let style = FloatingPointFormatStyle<Double>(locale: Locale(identifier: "en_US_POSIX"))
        return value.formatted(style.precision(.fractionLength(0...6)).grouping(.never))
    }
}
