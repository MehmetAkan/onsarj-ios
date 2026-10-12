import DesignSystem
import SwiftUI

/// Sayfa göstergesi: aktif sayfa uzun kapsül, diğerleri yuvarlak nokta.
///
/// Yerleşik `.indexViewStyle` bu biçimi vermediği için elle çizilir. Ekran okuyucudan
/// gizlidir; sayfalar arasında gezinme kaydırmalı alanın kendisinden yapılır.
struct PageIndicator: View {
    let count: Int
    let currentIndex: Int

    /// Noktanın çapı; aktif kapsülün yüksekliği de budur.
    private static let dotDiameter: CGFloat = 8

    /// Aktif sayfayı gösteren kapsülün genişliği.
    private static let activeDotWidth: CGFloat = 24

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                let isActive = index == currentIndex
                Capsule()
                    .fill(isActive ? Theme.indicatorActive : Theme.indicatorInactive)
                    .frame(
                        width: isActive ? Self.activeDotWidth : Self.dotDiameter,
                        height: Self.dotDiameter
                    )
            }
        }
        .animation(.easeInOut, value: currentIndex)
        .accessibilityHidden(true)
    }
}
