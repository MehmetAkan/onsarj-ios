import OnsarjCore
import Testing

@Suite("SearchText")
struct SearchTextTests {
    @Test("İSTANBUL, ISTANBUL, Istanbul, ıstanbul ve istanbul aynı anahtara iner")
    func turkishDottedI() {
        let keys = Set(["İSTANBUL", "ISTANBUL", "Istanbul", "ıstanbul", "istanbul"].map(SearchText.key))
        #expect(keys == ["istanbul"])
    }

    @Test(
        "Aksan duyarsız içerir eşleşmesi", arguments: [("Eşarj", "ESARJ"), ("Mercedes-Benz", "benz"), ("Togg", "TOĞG")])
    func matches(text: String, query: String) {
        #expect(SearchText.matches(text, query: query))
    }

    @Test("Boş sorgu her metinle eşleşir; eşleşmeyen sorgu false")
    func emptyAndMismatch() {
        #expect(SearchText.matches("BYD", query: "  "))
        #expect(!SearchText.matches("BYD", query: "kia"))
    }
}
