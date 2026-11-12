/// `DetentSheet`'in kademeleri, küçükten büyüğe.
public enum SheetDetent: Int, CaseIterable, Comparable, Sendable {
    /// En küçük kademe. Sayfa bunun altına inmez.
    case collapsed
    /// Ara kademe.
    case medium
    /// Ekranın üstüne kadar açılan kademe.
    case expanded

    public static func < (lhs: SheetDetent, rhs: SheetDetent) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
