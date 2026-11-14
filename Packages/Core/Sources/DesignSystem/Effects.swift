import CoreGraphics

/// Görsel efekt token'ları.
///
/// Değerler cihazda ayarlanır; bu yüzden tek yerde durur.
public enum Effects {

    /// Üzerine eylem yerleştirilen arka plan görseli (ör. boş araç kartı): bulanık ve soluk.
    public enum Muted {
        /// Bulanıklık yarıçapı.
        public static let blurRadius: CGFloat = 8

        /// Opaklık.
        public static let opacity: Double = 0.6
    }
}
