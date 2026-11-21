import CoreGraphics

/// İstasyon detayına ve yakındaki istasyonlar listesine özgü ölçüler.
enum StationDetailMetrics {
    /// Soket müsaitlik rozetinin zemini: müsaitlik renginin açık tonu (rozet yazısı aynı rengin tam tonu).
    static let availabilityBadgeOpacity: Double = 0.16
    /// Özet satırında gösterilen en çok olanak simgesi.
    static let summaryAmenityLimit = 3
    /// Özet satırındaki müsaitlik noktasının çapı; yazı boyutuyla ölçeklenmez (pinlerdeki noktayla aynı).
    static let availabilityDotDiameter: CGFloat = 8
    /// Listedeki istasyon fotoğrafının en-boy oranı (16:9).
    static let photoAspectRatio: CGFloat = 16.0 / 9.0
}
