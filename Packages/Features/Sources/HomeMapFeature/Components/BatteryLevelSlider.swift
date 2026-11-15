import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Araç kartındaki batarya yüzdesi çubuğu.
///
/// - **Sürükleme:** yalnızca yatay başlayan sürükleme yüzdeyi değiştirir. Karar, `DetentSheet`'in
///   kuralıyla aynıdır (ilk harekette yatay bileşen dikeyden büyük mü) ve aynı varsayılan
///   `DragGesture` eşiğini kullanır; böylece dikey başlayan sürükleme sayfaya kalır, yatay olanı
///   sayfa yok sayar. Saf SwiftUI'dır, UIKit gerekmez.
/// - **Değer:** parmağın konumu yüzdeye çevrilir, 1'er adımla; sınıra çekme `BatteryLevel`'dadır.
///   Sürüklerken `onChange`, parmak kalkınca bir kez `onCommit` çağrılır.
/// - **Renk:** dolgu `BatteryLevel.band`'den gelir; eşikler burada yazılmaz. Bant değiştiği anda,
///   yalnızca sürüklerken hafif seçim titreşimi verilir.
/// - **Erişilebilirlik:** ayarlanabilir öğe; değer yüzde olarak seslendirilir ("yüzde 30"),
///   artır/azalt adımı `Metrics.accessibilityStep`.
struct BatteryLevelSlider: View {
    let level: BatteryLevel
    let onChange: (Int) -> Void
    let onCommit: () -> Void

    /// Bu bileşene özgü ölçüler.
    private enum Metrics {
        /// Çubuğun kalınlığı.
        static let trackHeight: CGFloat = 8
        /// Tutamacın çapı; çubuktan kalındır. Dokunma alanı bütün satırdır (`Spacing.minTapTarget`).
        static let thumbDiameter: CGFloat = 20
        /// VoiceOver artır/azalt adımı, yüzde puanı.
        static let accessibilityStep = 5
        /// Yüzde ölçeğinin üst sınırı; parmak konumu 0…bu değere çevrilir.
        static let percentScale: CGFloat = 100
    }

    private enum Axis {
        case horizontal
        case vertical
    }

    @State private var width: CGFloat = 0
    /// Süren sürüklemenin yönü; ilk harekette belirlenir, parmak kalkana kadar değişmez.
    @State private var dragAxis: Axis?
    @Environment(\.locale) private var locale

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Theme.batteryTrack)
                .frame(height: Metrics.trackHeight)
            Capsule()
                .fill(fillColor)
                .frame(width: thumbCenter, height: Metrics.trackHeight)
            Circle()
                .fill(Theme.batteryThumb)
                .shadow(color: Theme.shadowFloating, radius: Spacing.xs)
                .frame(width: Metrics.thumbDiameter, height: Metrics.thumbDiameter)
                .offset(x: thumbCenter - Metrics.thumbDiameter / 2)
        }
        .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            self.width = width
        }
        .gesture(dragGesture)
        .sensoryFeedback(.selection, trigger: level.band) { _, _ in dragAxis == .horizontal }
        .accessibilityElement()
        .accessibilityLabel(Text("vehicleCard.batteryLevel", bundle: .onsarj))
        .accessibilityValue(Text(level.percent.formatted(.percent.locale(locale))))
        .accessibilityAdjustableAction(adjust)
    }

    private var fillColor: Color {
        switch level.band {
        case .low: Theme.batteryLow
        case .medium: Theme.batteryMedium
        case .high: Theme.batteryHigh
        }
    }

    /// Tutamacın merkezinin x konumu. Tutamaç çubuğun içinde kalır: %0'da sol uçta, %100'de sağ uçta.
    private var thumbCenter: CGFloat {
        let radius = Metrics.thumbDiameter / 2
        return radius + travel * CGFloat(level.percent) / Metrics.percentScale
    }

    /// Tutamaç merkezinin gidebildiği yol.
    private var travel: CGFloat {
        max(0, width - Metrics.thumbDiameter)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let axis = dragAxis ?? Self.axis(of: value.translation)
                dragAxis = axis
                guard axis == .horizontal, travel > 0 else { return }
                let position = value.location.x - Metrics.thumbDiameter / 2
                onChange(Int((position / travel * Metrics.percentScale).rounded()))
            }
            .onEnded { _ in
                let wasHorizontal = dragAxis == .horizontal
                dragAxis = nil
                if wasHorizontal {
                    onCommit()
                }
            }
    }

    /// `DetentSheet` ile aynı kural: ilk harekette yatay bileşen büyükse yatay.
    private static func axis(of translation: CGSize) -> Axis {
        abs(translation.width) > abs(translation.height) ? .horizontal : .vertical
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment: onChange(level.percent + Metrics.accessibilityStep)
        case .decrement: onChange(level.percent - Metrics.accessibilityStep)
        @unknown default: return
        }
        onCommit()
    }
}
