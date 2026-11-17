import CoreGraphics

/// İstasyon detayına özgü ölçüler.
enum StationDetailMetrics {
    /// Soket müsaitlik rozetinin zemini: müsaitlik renginin açık tonu (rozet yazısı aynı rengin tam tonu).
    static let availabilityBadgeOpacity: Double = 0.16
    /// Özet satırında gösterilen en çok olanak simgesi.
    static let summaryAmenityLimit = 3
    /// Özet satırındaki müsaitlik noktasının çapı; yazı boyutuyla ölçeklenmez (pinlerdeki noktayla aynı).
    static let availabilityDotDiameter: CGFloat = 8
}
