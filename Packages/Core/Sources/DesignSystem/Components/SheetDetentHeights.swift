import CoreGraphics

/// `DetentSheet` kademelerinin yükseklikleri.
///
/// Yükseklikler ekranın alt kenarından ölçülür; alt güvenli alan (ana ekran göstergesi)
/// dahildir. Ölçümden hesaplanır; yazı boyutu veya ekran değişince güncellenir.
struct SheetDetentHeights: Equatable {
    var collapsed: CGFloat
    var medium: CGFloat

    subscript(detent: SheetDetent) -> CGFloat {
        switch detent {
        case .collapsed: collapsed
        case .medium: medium
        }
    }
}
