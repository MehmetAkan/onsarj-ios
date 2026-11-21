import Foundation

/// İki nokta arasındaki kuş uçuşu uzaklık.
public enum GeoDistance {
    /// Dünyanın ortalama yarıçapı (km, IUGG).
    public static let earthRadiusKm: Double = 6371.0088

    /// Haversine formülüyle büyük daire uzaklığı (km). Dünya küre kabul edilir; hata %0,5'in altındadır.
    public static func kilometers(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let lat1 = radians(start.latitude)
        let lat2 = radians(end.latitude)
        let deltaLat = lat2 - lat1
        let deltaLon = radians(end.longitude - start.longitude)
        let sinHalfLat = sin(deltaLat / 2)
        let sinHalfLon = sin(deltaLon / 2)
        let haversine = sinHalfLat * sinHalfLat + cos(lat1) * cos(lat2) * sinHalfLon * sinHalfLon
        return 2 * earthRadiusKm * asin(min(1, sqrt(haversine)))
    }

    private static func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
