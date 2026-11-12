import MapboxMaps
import SwiftUI
import Testing

@testable import MapEngine

@Suite("MapStyle")
struct MapStyleTests {
    @Test("Açık temada Standard stil gündüz ışığıyla yüklenir")
    func lightSchemeUsesDayPreset() {
        let style = MapEngine.MapStyle.standard.mapboxStyle(for: .light)

        #expect(style == MapboxMaps.MapStyle.standard(lightPreset: .day))
    }

    @Test("Koyu temada Standard stil gece ışığıyla yüklenir")
    func darkSchemeUsesNightPreset() {
        let style = MapEngine.MapStyle.standard.mapboxStyle(for: .dark)

        #expect(style == MapboxMaps.MapStyle.standard(lightPreset: .night))
    }

    @Test("Tema değişimi stil adresini değiştirmez; harita yeniden yüklenmez")
    func schemesShareStyleURI() {
        let style = MapEngine.MapStyle.standard

        #expect(style.light.uri == style.dark.uri)
    }
}
