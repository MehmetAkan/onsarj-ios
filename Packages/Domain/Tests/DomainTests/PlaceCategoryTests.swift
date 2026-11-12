import Testing

@testable import OnsarjDomain

@Suite("PlaceCategory")
struct PlaceCategoryTests {
    @Test("Tanımlayıcılar kararlıdır: analitik ve API bu değerlere dayanır")
    func identifiersAreStable() {
        #expect(
            PlaceCategory.allCases.map(\.id) == [
                "restaurant", "cafe", "mosque", "market", "pharmacy", "atm", "hotel",
            ])
    }
}
