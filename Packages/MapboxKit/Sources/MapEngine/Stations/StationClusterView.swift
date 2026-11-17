import DesignSystem
import SwiftUI

/// Uzaklaşınca birleşen istasyonların kümesi (`Docs/Design/pin-taslak.png`): koyu daire, beyaz çerçeve,
/// içinde istasyon sayısı, çevresinde yeşil hale. Pin gibi görsel olarak stile eklenir.
struct StationClusterView: View {
    /// Taslağın kaynak ölçüleri (pt).
    enum Metrics {
        /// Daire çapları (çerçeve dahil): 2–9, 10–99, 100 ve üstü.
        static let smallDiameter: CGFloat = 38
        static let mediumDiameter: CGFloat = 46
        static let largeDiameter: CGFloat = 56
        /// Beyaz çerçeve.
        static let borderWidth: CGFloat = 3
        /// Halenin daireden taşma payı (yarıçapa eklenir; çapa iki katı).
        static let haloWidth: CGFloat = 6
        /// Halenin opaklığı.
        static let haloOpacity: Double = 0.22
        /// Gösterilen en büyük sayı; üstü "999+" yazılır.
        static let maximumShownCount = 999
    }

    /// Küme boyu; sayıya göre seçilir.
    enum Size: CaseIterable {
        case small
        case medium
        case large

        init(count: Int) {
            switch count {
            case ..<10: self = .small
            case ..<100: self = .medium
            default: self = .large
            }
        }

        var diameter: CGFloat {
            switch self {
            case .small: Metrics.smallDiameter
            case .medium: Metrics.mediumDiameter
            case .large: Metrics.largeDiameter
            }
        }

        /// Taslakta 15 ve 18 pt kalın. Yazı boyutu `Typography`'den gelir (CLAUDE.md 6.6) ve görsel `large`
        /// yazı boyutunda çizilir: 15 pt `buttonSmall`, büyük kümede 17 pt `headline` (18 pt'lik metin stili yok).
        var font: Font {
            switch self {
            case .small, .medium: Typography.buttonSmall.weight(.bold)
            case .large: Typography.headline.weight(.bold)
            }
        }
    }

    /// Kümedeki istasyon sayısının yazısı: gerçek sayı, 1000 ve üstü "999+".
    static func label(for count: Int) -> String {
        count > Metrics.maximumShownCount ? "\(Metrics.maximumShownCount)+" : "\(count)"
    }

    let label: String
    let size: Size

    var body: some View {
        Text(verbatim: label)
            .font(size.font)
            .monospacedDigit()
            .foregroundStyle(Theme.onMapCluster)
            .frame(width: size.diameter, height: size.diameter)
            .background(Circle().fill(Theme.mapClusterFill))
            .overlay(Circle().strokeBorder(Theme.onMapCluster, lineWidth: Metrics.borderWidth))
            .padding(Metrics.haloWidth)
            .background(Circle().fill(Theme.availabilityAvailable.opacity(Metrics.haloOpacity)))
    }
}

#if DEBUG
#Preview("İstasyon kümesi") {
    HStack(spacing: Spacing.lg) {
        StationClusterView(label: "4", size: .small)
        StationClusterView(label: "27", size: .medium)
        StationClusterView(label: StationClusterView.label(for: 1200), size: .large)
    }
    .padding(Spacing.xl)
    .background(Theme.backgroundSheet)
}
#endif
