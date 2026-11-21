import Foundation
import OnsarjCore
import Testing

@Suite("MediaURL")
struct MediaURLTests {
    @Test("https ve http kabul, file yalnızca istenirse")
    func schemes() {
        #expect(MediaURL.parse("https://cdn.example.com/a.png", acceptsFile: false)?.host == "cdn.example.com")
        #expect(MediaURL.parse("http://cdn.example.com/a.png", acceptsFile: false) != nil)
        #expect(MediaURL.parse("file:///tmp/a.png", acceptsFile: false) == nil)
        #expect(MediaURL.parse("file:///tmp/a.png", acceptsFile: true)?.path == "/tmp/a.png")
    }

    @Test("Sunucusuz, şemasız ve boş değer reddedilir")
    func rejects() {
        #expect(MediaURL.parse("https:///a.png", acceptsFile: false) == nil)
        #expect(MediaURL.parse("operator-zes", acceptsFile: true) == nil)
        #expect(MediaURL.parse(nil, acceptsFile: true) == nil)
        #expect(MediaURL.parse("ftp://example.com/a.png", acceptsFile: true) == nil)
    }
}
