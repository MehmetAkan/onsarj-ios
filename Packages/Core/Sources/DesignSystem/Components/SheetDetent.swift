/// `DetentSheet`'in kademeleri, küçükten büyüğe.
public enum SheetDetent: Int, CaseIterable, Comparable, Sendable {
    /// En küçük kademe. Sayfa bunun altına inmez.
    case collapsed
    /// En büyük kademe: içeriğe göre, kullanılabilir yüksekliğin yarısı ile `DetentSheet` sınırı arası.
    case medium

    public static func < (lhs: SheetDetent, rhs: SheetDetent) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
