import CoreGraphics
import Testing

@testable import DesignSystem

@Suite("DetentResolver")
struct DetentResolverTests {
    /// Küçük, orta, büyük.
    private let detents: [CGFloat] = [100, 400, 800]

    @Test(
        "Yavaş bırakılan sayfa en yakın kademeye oturur",
        arguments: [(CGFloat(180), 0), (CGFloat(320), 1), (CGFloat(520), 1), (CGFloat(700), 2)]
    )
    func slowReleasePicksNearest(position: CGFloat, expected: Int) {
        #expect(DetentResolver.resolve(position: position, velocity: 50, detents: detents) == expected)
        #expect(DetentResolver.resolve(position: position, velocity: -50, detents: detents) == expected)
    }

    @Test("Hızlı yukarı fırlatma, en yakın kademe aşağıda olsa bile yukarıdaki kademeye gider")
    func fastFlingUpGoesUp() {
        #expect(DetentResolver.resolve(position: 120, velocity: 600, detents: detents) == 1)
        #expect(DetentResolver.resolve(position: 420, velocity: 600, detents: detents) == 2)
    }

    @Test("Hızlı aşağı fırlatma, en yakın kademe yukarıda olsa bile aşağıdaki kademeye gider")
    func fastFlingDownGoesDown() {
        #expect(DetentResolver.resolve(position: 780, velocity: -600, detents: detents) == 1)
        #expect(DetentResolver.resolve(position: 380, velocity: -600, detents: detents) == 0)
    }

    @Test("Çok hızlı fırlatma, yansıtılan konum ötedeyse bir kademe atlar")
    func veryFastFlingSkipsDetent() {
        #expect(DetentResolver.resolve(position: 110, velocity: 3_000, detents: detents) == 2)
    }

    @Test("Sınır dışındaki konum en yakın uç kademeye döner")
    func outOfBoundsReturnsToEdge() {
        #expect(DetentResolver.resolve(position: 900, velocity: 0, detents: detents) == 2)
        #expect(DetentResolver.resolve(position: 40, velocity: 0, detents: detents) == 0)
        #expect(DetentResolver.resolve(position: 900, velocity: 2_000, detents: detents) == 2)
        #expect(DetentResolver.resolve(position: 40, velocity: -2_000, detents: detents) == 0)
    }

    @Test("Tek kademede her bırakma o kademeye oturur")
    func singleDetent() {
        #expect(DetentResolver.resolve(position: 50, velocity: -2_000, detents: [300]) == 0)
        #expect(DetentResolver.resolve(position: 600, velocity: 2_000, detents: [300]) == 0)
    }

    @Test("Kademe listesi boşsa seçim yapılmaz")
    func emptyDetents() {
        #expect(DetentResolver.resolve(position: 100, velocity: 0, detents: []) == nil)
    }

    @Test("Kademenin tam üstüne bırakılan sayfa yerinde kalır, hızlı fırlatma bir sonrakine geçer")
    func releaseExactlyOnDetent() {
        #expect(DetentResolver.resolve(position: 400, velocity: 0, detents: detents) == 1)
        #expect(DetentResolver.resolve(position: 400, velocity: 600, detents: detents) == 2)
        #expect(DetentResolver.resolve(position: 400, velocity: -600, detents: detents) == 0)
    }
}
