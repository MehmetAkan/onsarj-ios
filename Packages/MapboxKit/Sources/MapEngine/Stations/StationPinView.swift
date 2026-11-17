import DesignSystem
import OnsarjDomain
import SwiftUI

/// Haritadaki istasyon pini (`Docs/Design/pin-taslak.png`): beyaz daire içinde ağ logosu, altında kısa
/// sap, sapın ucunda müsaitlik noktası ve halesi. Pinin üstünde metin yoktur.
///
/// Haritaya görünüm olarak değil, bir kez çizilip stile eklenen görsel olarak girer (CLAUDE.md 5.4,
/// `StationImageFactory`). Pinin konum noktası müsaitlik noktasının merkezidir (`Metrics.anchorFromBottom`).
struct StationPinView: View {
    /// Taslağın kaynak ölçüleri (pt). Seçili pin aynı çizimin `selectedScale` katıdır; yalnızca çerçeve
    /// kalınlaşır.
    enum Metrics {
        /// Görselin kutusu. Daire ve hale kutunun içinde kalır; kenarlardaki boşluk gölgeye yer açar.
        static let boxSize = CGSize(width: 64, height: 96)
        /// Logo dairesinin üst kenarının kutunun üstünden uzaklığı; gölge için.
        static let circleTop: CGFloat = 5
        /// Logo dairesinin çapı (çerçeve dahil).
        static let circleDiameter: CGFloat = 50
        /// Logo dairesinin çerçevesi.
        static let borderWidth: CGFloat = 2
        /// Seçili pinin çerçevesi.
        static let selectedBorderWidth: CGFloat = 3.5
        /// Dairenin içindeki logo alanının çapı; logo bu daireye kırpılır.
        static let logoDiameter: CGFloat = 34
        /// Sapın daireye değdiği yerdeki genişliği; sap müsaitlik noktasına doğru sivrilir.
        static let stemTopWidth: CGFloat = 12
        /// Müsaitlik noktasının merkezinin kutunun üstünden uzaklığı.
        static let dotCenterY: CGFloat = 80
        /// Müsaitlik noktasının çapı (beyaz çerçeve hariç).
        static let dotDiameter: CGFloat = 11
        /// Müsaitlik noktasının beyaz çerçevesi.
        static let dotBorderWidth: CGFloat = 2
        /// Müsaitlik halesinin çapı ve opaklığı.
        static let haloDiameter: CGFloat = 22
        static let haloOpacity: Double = 0.28
        /// Seçili pinin büyüme katı.
        static let selectedScale: CGFloat = 1.22
        /// Gölgenin yarıçapı ve aşağı kayması.
        static let shadowRadius: CGFloat = Spacing.xs
        static let shadowOffsetY: CGFloat = Spacing.xs / 2

        /// Konum noktasının (müsaitlik noktasının merkezi) kutunun altından uzaklığı; seçili pinde ölçeklenir.
        static func anchorFromBottom(isSelected: Bool) -> CGFloat {
            (boxSize.height - dotCenterY) * (isSelected ? selectedScale : 1)
        }
    }

    let availability: StationAvailability
    /// Ağ logosu; yoksa daire içinde şimşek çizilir.
    let logo: Image?
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .top) {
            stem
            circle.padding(.top, Metrics.circleTop)
            dot.offset(y: Metrics.dotCenterY - Metrics.haloDiameter / 2)
        }
        .frame(width: Metrics.boxSize.width, height: Metrics.boxSize.height, alignment: .top)
        .scaleEffect(isSelected ? Metrics.selectedScale : 1, anchor: .top)
        .frame(
            width: Metrics.boxSize.width * scale,
            height: Metrics.boxSize.height * scale,
            alignment: .top
        )
    }

    private var scale: CGFloat { isSelected ? Metrics.selectedScale : 1 }

    private var borderColor: Color { isSelected ? Theme.mapPinSelected : Theme.mapPinBorder }

    private var circle: some View {
        Circle()
            .fill(Theme.mapPinSurface)
            .overlay {
                Circle()
                    .strokeBorder(
                        borderColor, lineWidth: isSelected ? Metrics.selectedBorderWidth : Metrics.borderWidth)
            }
            .overlay { logoContent }
            .frame(width: Metrics.circleDiameter, height: Metrics.circleDiameter)
            .shadow(color: Theme.shadowFloating, radius: Metrics.shadowRadius, y: Metrics.shadowOffsetY)
    }

    @ViewBuilder
    private var logoContent: some View {
        if let logo {
            logo
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.logoDiameter, height: Metrics.logoDiameter)
                .clipShape(Circle())
        } else {
            AppIcon.charger
                .font(Typography.sectionTitle)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    /// Daireden müsaitlik noktasına sivrilen sap. Dairenin altına biraz girer; çerçevenin altında kalır.
    private var stem: some View {
        let top = Metrics.circleTop + Metrics.circleDiameter - Metrics.borderWidth * 2
        let tip = Metrics.dotCenterY - Metrics.dotDiameter / 2
        return StemShape()
            .fill(isSelected ? Theme.mapPinSelected : Theme.mapPinSurface)
            .overlay { StemShape().stroke(borderColor, lineWidth: Metrics.borderWidth / 2) }
            .frame(width: Metrics.stemTopWidth, height: tip - top)
            .offset(y: top)
    }

    private var dot: some View {
        let color = Self.color(for: availability)
        return ZStack {
            Circle().fill(color.opacity(Metrics.haloOpacity))
                .frame(width: Metrics.haloDiameter, height: Metrics.haloDiameter)
            Circle().fill(Theme.mapPinSurface)
                .frame(
                    width: Metrics.dotDiameter + Metrics.dotBorderWidth * 2,
                    height: Metrics.dotDiameter + Metrics.dotBorderWidth * 2
                )
            Circle().fill(color)
                .frame(width: Metrics.dotDiameter, height: Metrics.dotDiameter)
        }
    }

    static func color(for availability: StationAvailability) -> Color {
        switch availability {
        case .available: Theme.availabilityAvailable
        case .partial: Theme.availabilityPartial
        case .unavailable: Theme.availabilityUnavailable
        case .unknown: Theme.availabilityUnknown
        }
    }
}

/// Üstte geniş, altta sivri sap; yalnızca yan kenarları çizilir (üst kenar dairenin altında kalır).
private struct StemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#if DEBUG
#Preview("İstasyon pini") {
    HStack(spacing: Spacing.lg) {
        ForEach(StationAvailability.allCases, id: \.self) { availability in
            StationPinView(availability: availability, logo: nil, isSelected: false)
        }
        StationPinView(availability: .available, logo: nil, isSelected: true)
    }
    .padding(Spacing.xl)
    .background(Theme.backgroundSheet)
}
#endif
