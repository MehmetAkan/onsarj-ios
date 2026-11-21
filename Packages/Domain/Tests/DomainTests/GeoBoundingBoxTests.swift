import Testing

@testable import OnsarjDomain

@Suite("GeoBoundingBox")
struct GeoBoundingBoxTests {
    private let box = GeoBoundingBox(
        southWest: GeoCoordinate(latitude: 36, longitude: 30),
        northEast: GeoCoordinate(latitude: 38, longitude: 32)
    )

    @Test("Nokta içeride, sınırda ve dışarıda")
    func containsCoordinate() {
        #expect(box.contains(GeoCoordinate(latitude: 37, longitude: 31)))
        #expect(box.contains(GeoCoordinate(latitude: 36, longitude: 32)))
        #expect(!box.contains(GeoCoordinate(latitude: 35.9, longitude: 31)))
        #expect(!box.contains(GeoCoordinate(latitude: 37, longitude: 32.1)))
    }

    @Test("Büyütülmüş kutu merkezi korur ve küçük kutuyu kapsar")
    func scaledContainsOriginal() {
        let scaled = box.scaled(by: 1.5)
        #expect(scaled.longitudeSpan == 3)
        #expect(scaled.latitudeSpan == 3)
        #expect(scaled.contains(box))
        #expect(!box.contains(scaled))
    }

    @Test("Büyütme dünya sınırlarını aşmaz")
    func scaledIsClamped() {
        let world = GeoBoundingBox(
            southWest: GeoCoordinate(latitude: -80, longitude: -170),
            northEast: GeoCoordinate(latitude: 80, longitude: 170)
        )
        .scaled(by: 2)
        #expect(world.southWest == GeoCoordinate(latitude: -90, longitude: -180))
        #expect(world.northEast == GeoCoordinate(latitude: 90, longitude: 180))
    }

    @Test("Köşeleri ters kutu hiçbir noktayı içermez ve çökmez")
    func invertedBoxContainsNothing() {
        let inverted = GeoBoundingBox(
            southWest: GeoCoordinate(latitude: 38, longitude: 170),
            northEast: GeoCoordinate(latitude: 36, longitude: -170)
        )
        #expect(!inverted.contains(GeoCoordinate(latitude: 37, longitude: 175)))
        #expect(!inverted.contains(GeoCoordinate(latitude: 37, longitude: 0)))
    }

    @Test("Koordinat geçerliliği")
    func coordinateValidity() {
        #expect(GeoCoordinate(latitude: 90, longitude: -180).isValid)
        #expect(!GeoCoordinate(latitude: 90.1, longitude: 0).isValid)
        #expect(!GeoCoordinate(latitude: 0, longitude: 181).isValid)
    }
}
