import Testing

@testable import OnsarjDomain

@Suite("BatteryLevel")
struct BatteryLevelTests {
    @Test("Aralık dışı değer sınıra çekilir", arguments: [(-5, 0), (130, 100), (0, 0), (100, 100), (42, 42)])
    func clampsToRange(input: Int, expected: Int) {
        #expect(BatteryLevel(percent: input).percent == expected)
    }

    @Test(
        "Band sınırları",
        arguments: [
            (0, BatteryLevelBand.low), (20, .low),
            (21, .medium), (50, .medium),
            (51, .high), (100, .high),
        ]
    )
    func bandBoundaries(percent: Int, expected: BatteryLevelBand) {
        #expect(BatteryLevel(percent: percent).band == expected)
    }

    @Test("Başlangıç değeri %30, orta bant")
    func initialLevel() {
        #expect(BatteryLevel.initial.percent == 30)
        #expect(BatteryLevel.initial.band == .medium)
    }
}
