import MapboxMaps
import SwiftUI

/// Haritanın stili: açık ve koyu tema için ayrı görünüm.
///
/// Şimdilik Mapbox'ın hazır **Standard** stili kullanılır. Standard'ın ayrı bir gece adresi
/// (`standardNight`) yoktur; gece görünümü aynı stilin `night` ışık ön ayarıyla verilir.
/// Açık temada `day` ön ayarı seçilir.
///
/// **Özel onsarj stili** Mapbox Studio'da tasarlandığında yalnızca `standard` tanımındaki stil
/// adresleri değişir; `MapView` ve ekran kodu değişmez. Studio stili Standard tabanlı olursa
/// aynı ışık ön ayarlarını taşır; açık ve koyu için iki ayrı stil yapılırsa iki adres verilir
/// ve ön ayar `nil` olur.
public struct MapStyle: Sendable, Equatable {
    /// Bir temanın görünümü: stil adresi ve varsa Standard ışık ön ayarı.
    struct Appearance: Sendable, Equatable {
        let uri: StyleURI
        let lightPreset: StandardLightPreset?
    }

    let light: Appearance
    let dark: Appearance

    /// Mapbox Standard: açık temada gündüz, koyu temada gece ışığı.
    public static let standard = MapStyle(
        light: Appearance(uri: .standard, lightPreset: .day),
        dark: Appearance(uri: .standard, lightPreset: .night)
    )

    /// Verilen temanın Mapbox stil tanımı.
    ///
    /// Adres iki temada aynıysa tema değişimi stili yeniden yüklemez; yalnızca ışık ön ayarı
    /// değişir ve harita yerinde, kesintisiz geçiş yapar.
    func mapboxStyle(for colorScheme: ColorScheme) -> MapboxMaps.MapStyle {
        let appearance = colorScheme == .dark ? dark : light
        let configuration: JSONObject? = appearance.lightPreset.map { ["lightPreset": .string($0.rawValue)] }
        return MapboxMaps.MapStyle(uri: appearance.uri, configuration: configuration)
    }
}
