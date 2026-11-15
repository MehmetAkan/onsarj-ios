import SwiftUI

/// İki kademeli, tam genişlikte, kapatılamayan alt sayfa (K-22, K-25).
///
/// iOS'un `presentationDetents` yapısı iOS 26'dan itibaren küçük ve orta kademede sayfayı
/// kenarlardan içeride çiziyor; tasarım tüm sürümlerde tam genişlik istediği için bu bileşen
/// yazıldı. Saf SwiftUI'dır.
///
/// - **Yerleşim:** Ekranın alt kenarına dayanır, arka planı alt güvenli alanı doldurur. Başka
///   bir görünümün üstüne (`ZStack`) konur; yalnızca kendi alanındaki dokunuşları alır, geri
///   kalan alan alttaki görünüme (ör. harita) açıktır.
/// - **Kademeler:** Küçük = sürükleme göstergesi + başlığın ölçülen yüksekliği + alt güvenli
///   alan. Orta (en büyük kademe) içeriğin tamamını gösterecek kadar uzar: en az kullanılabilir
///   yüksekliğin yarısı, en çok `maxMediumHeightRatio`'su; içerik bundan uzunsa kayar. Ölçüm
///   değişince (yazı boyutu) kademeler de değişir.
/// - **Sürükleme:** Başlık her zaman sayfayı sürükler. İçerik orta kademede kayar; içerik ile
///   sayfa arasındaki devir `DetentSheetTracker`'da anlatılır. Bırakınca kademe
///   `DetentResolver` ile seçilir; sınırların ötesinde lastik direnci vardır.
/// - **Eşlikçi:** `accessory` (ör. harita üzerindeki yüzen butonlar) sayfanın üst kenarının hemen
///   üstünde durur ve sayfayı parmakla birlikte izler; orta kademenin üstüne çıkmaz, lastik
///   direnciyle uzayan sayfa onun üzerinden geçer.
/// - **İçerikteki butonlar:** İçerik bölgesinin sürüklemesi eşzamanlıdır (yatay listeler kayabilsin
///   diye), bu yüzden sayfayı sürükleyen parmak bir butonun üstünde kalkarsa buton da tetiklenebilir.
///   Sayfa sürüklenirken `isSheetDragInProgress` ortam değeri `true` olur; `CategoryChip` ve
///   `ActionTileButton` bu sırada dokunuşu yok sayar.
/// - **Zemin:** `Theme.backgroundSheet`; içindeki öğeler `Theme.backgroundCard` kullanır.
/// - **Klavye:** Sayfa klavyeyle küçülmez; içeriğin altına klavye kadar boşluk eklenir.
/// - **Erişilebilirlik:** Sürükleme göstergesi VoiceOver'da ayarlanabilir öğedir; artır/azalt
///   ile kademe değişir, mevcut kademe seslendirilir. "Hareketi Azalt" açıkken yay yerine
///   kısa bir geçiş kullanılır.
public struct DetentSheet<Header: View, Content: View, Accessory: View>: View {
    @Binding private var detent: SheetDetent
    private let accessibilityLabel: Text
    private let accessibilityValue: (SheetDetent) -> Text
    private let header: Header
    private let content: Content
    private let accessory: Accessory

    @State private var tracker: DetentSheetTracker
    @State private var metrics = Metrics()
    @GestureState private var isDraggingHeader = false
    @GestureState private var isDraggingContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Orta kademenin, güvenli alanlar dışındaki yüksekliğe en küçük oranı.
    private static var mediumHeightRatio: CGFloat { 0.5 }

    /// Orta kademenin en büyük oranı: içerik ne kadar uzun olursa olsun haritanın ve üstündeki
    /// butonların görünür kalacağı sınır.
    private static var maxMediumHeightRatio: CGFloat { 0.8 }

    /// - Parameters:
    ///   - detent: Mevcut kademe. Sayfa bir kademeye oturduğunda güncellenir; dışarıdan
    ///     değiştirilirse sayfa o kademeye geçer.
    ///   - accessibilityLabel: Sürükleme göstergesinin VoiceOver etiketi.
    ///   - accessibilityValue: Kademenin VoiceOver'da seslendirilen adı.
    ///   - header: Her zaman görünen, sayfayı sürükleyen üst bölge.
    ///   - content: Başlığın altındaki, kayabilen içerik.
    ///   - accessory: Sayfanın üstünde duran ve onu orta kademeye kadar izleyen öğeler.
    public init(
        detent: Binding<SheetDetent>,
        accessibilityLabel: Text,
        accessibilityValue: @escaping (SheetDetent) -> Text,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessory: () -> Accessory
    ) {
        _detent = detent
        _tracker = State(initialValue: DetentSheetTracker(detent: detent.wrappedValue))
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.header = header()
        self.content = content()
        self.accessory = accessory()
    }

    public var body: some View {
        ZStack {
            measurementLayers
            TimelineView(.animation(paused: !tracker.isAnimating)) { context in
                let height = tracker.height(at: context.date)
                ZStack(alignment: .bottom) {
                    accessoryLayer(sheetHeight: height)
                    sheet(height: height, contentOffset: tracker.contentOffset(at: context.date))
                }
                .onChange(of: context.date) { _, date in
                    tracker.finishMotions(limits: limits, at: date)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
        }
        .onChange(of: limits, initial: true) { _, limits in
            tracker.layoutChanged(limits, at: .now)
        }
        .onChange(of: detent) { _, detent in
            guard detent != tracker.detent else { return }
            tracker.move(to: detent, limits: limits, at: .now, reduceMotion: reduceMotion)
        }
        // Sistem sürüklemeyi bitiş bildirmeden iptal ederse sayfa yarıda kalmaz.
        .onChange(of: isDraggingHeader) { _, isActive in if !isActive { endDrag(velocity: 0) } }
        .onChange(of: isDraggingContent) { _, isActive in if !isActive { endDrag(velocity: 0) } }
    }

    // MARK: - Sayfa

    /// Eşlikçi, sayfanın üst kenarının bir boşluk üstünde; orta kademenin üstüne çıkmaz.
    /// Sayfayla aynı zaman çizelgesinden çizildiği için sürüklerken ve otururken birlikte hareket eder.
    private func accessoryLayer(sheetHeight: CGFloat) -> some View {
        accessory
            .padding(.bottom, max(0, min(sheetHeight, heights.medium)) + Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func sheet(height: CGFloat, contentOffset: CGFloat) -> some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: Radius.sheet, topTrailingRadius: Radius.sheet)
        return VStack(spacing: 0) {
            headerArea
            contentArea(offset: contentOffset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: max(0, height), alignment: .top)
        .clipShape(shape)
        .environment(\.isSheetDragInProgress, tracker.isMovingSheet)
        .background {
            shape
                .fill(Theme.backgroundSheet)
                .shadow(color: Theme.shadowFloating, radius: Spacing.sm)
        }
    }

    private var headerArea: some View {
        VStack(spacing: 0) {
            grabber
            header.padding(.bottom, Spacing.md)
        }
        .frame(maxWidth: .infinity)
        // Sayfa lastik direnciyle başlıktan kısa kalsa bile başlık ezilmez; ölçüm sabit kalır.
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            metrics.headerHeight = height
        }
        .contentShape(Rectangle())
        // Öncelikli: sürükleme başlayınca başlıktaki butonun dokunuşu iptal olur. Eşzamanlı
        // olsaydı parmak butonun üstünde kalkınca buton da tetiklenirdi (ör. arama açılırdı).
        // Kısa dokunuş sürükleme eşiğini geçmediği için butona gider.
        .highPriorityGesture(dragGesture(.header, state: $isDraggingHeader))
    }

    private var grabber: some View {
        Capsule()
            .fill(Theme.indicatorInactive)
            .frame(width: Spacing.xxl, height: Spacing.xs)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue(detent))
            .accessibilityAdjustableAction(adjust)
    }

    private func contentArea(offset: CGFloat) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                metrics.contentHeight = height
            }
            .padding(.bottom, metrics.contentBottomInset)
            .offset(y: -offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(dragGesture(.content, state: $isDraggingContent))
            .accessibilityElement(children: .contain)
            .accessibilityScrollAction(scrollForAccessibility)
    }

    // MARK: - Ölçüm

    /// Ekranı, güvenli alanı ve klavye dahil görünür alanı ölçen görünmez katmanlar.
    /// Dokunuş almazlar.
    private var measurementLayers: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    metrics.screen = frame
                }
            Color.clear
                .ignoresSafeArea(.keyboard)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    metrics.safeArea = frame
                }
            Color.clear
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    metrics.visible = frame
                }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var heights: SheetDetentHeights {
        let collapsed = metrics.headerHeight + metrics.safeBottom
        let usable = metrics.screen.height - metrics.safeTop - metrics.safeBottom
        let fitted = metrics.headerHeight + metrics.contentHeight + metrics.safeBottom
        let lower = usable * Self.mediumHeightRatio + metrics.safeBottom
        let upper = usable * Self.maxMediumHeightRatio + metrics.safeBottom
        let medium = max(min(max(fitted, lower), upper), collapsed)
        return SheetDetentHeights(collapsed: collapsed, medium: medium)
    }

    private var limits: DetentSheetTracker.Limits {
        let heights = heights
        let detents = SheetDetent.allCases
        let upper = heights[detents.last ?? .medium]
        let visibleContent = upper - metrics.headerHeight
        let fullContent = metrics.contentHeight + metrics.contentBottomInset
        return DetentSheetTracker.Limits(
            heights: heights,
            detents: detents,
            maxContentOffset: max(0, fullContent - visibleContent),
            dimension: metrics.screen.height
        )
    }

    // MARK: - Etkileşim

    private func dragGesture(_ region: DetentSheetTracker.Region, state: GestureState<Bool>) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating(state) { _, isActive, _ in
                isActive = true
            }
            .onChanged { value in
                tracker.dragChanged(region: region, translation: value.translation, limits: limits, at: .now)
            }
            .onEnded { value in
                endDrag(velocity: value.velocity.height)
            }
    }

    private func endDrag(velocity: CGFloat) {
        guard tracker.isDragging else { return }
        let settled = tracker.dragEnded(velocity: velocity, limits: limits, at: .now, reduceMotion: reduceMotion)
        if let settled, settled != detent {
            detent = settled
        }
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        let detents = SheetDetent.allCases
        switch direction {
        case .increment: detent = detents.first { $0 > detent } ?? detent
        case .decrement: detent = detents.last { $0 < detent } ?? detent
        @unknown default: break
        }
    }

    private func scrollForAccessibility(_ edge: Edge) {
        let page = heights[.medium] - metrics.headerHeight
        let amount: CGFloat
        switch edge {
        case .top, .leading: amount = -page
        case .bottom, .trailing: amount = page
        }
        tracker.scrollContent(by: amount, limits: limits, at: .now, reduceMotion: reduceMotion)
    }
}

extension DetentSheet where Accessory == EmptyView {
    /// Eşlikçisi olmayan sayfa.
    public init(
        detent: Binding<SheetDetent>,
        accessibilityLabel: Text,
        accessibilityValue: @escaping (SheetDetent) -> Text,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            detent: detent,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            header: header,
            content: content,
            accessory: { EmptyView() }
        )
    }
}

// MARK: - Ölçüler

private struct Metrics: Equatable {
    /// Ekranın tamamı.
    var screen: CGRect = .zero
    /// Kap güvenli alanı; klavye hariç.
    var safeArea: CGRect = .zero
    /// Klavye dahil tüm güvenli alanların içinde kalan görünür alan.
    var visible: CGRect = .zero
    var headerHeight: CGFloat = 0
    var contentHeight: CGFloat = 0

    var safeTop: CGFloat { max(0, safeArea.minY - screen.minY) }
    var safeBottom: CGFloat { max(0, screen.maxY - safeArea.maxY) }

    /// İçeriğin altında bırakılan boşluk: alt güvenli alan, klavye açıksa klavye.
    var contentBottomInset: CGFloat { max(safeBottom, screen.maxY - visible.maxY) }
}

#if DEBUG
/// Kaydırılabilir içerikli örnek sayfa; sürükleme ve içerik devri önizlemede denenir.
private struct DetentSheetPreview: View {
    @State var detent: SheetDetent

    var body: some View {
        ZStack {
            Theme.backgroundSubtle.ignoresSafeArea()
            DetentSheet(
                detent: $detent,
                accessibilityLabel: Text(verbatim: "Sheet"),
                accessibilityValue: Self.accessibilityValue
            ) {
                Text(verbatim: "Header")
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
                    .background(Theme.backgroundSubtle, in: RoundedRectangle(cornerRadius: Radius.field))
                    .padding(.horizontal, Spacing.screenMargin)
            } content: {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(1...40, id: \.self) { row in
                        Text(verbatim: "Row \(row)").font(Typography.body)
                    }
                }
                .padding(.horizontal, Spacing.screenMargin)
            }
        }
    }
}

extension DetentSheetPreview {
    fileprivate static func accessibilityValue(for detent: SheetDetent) -> Text {
        Text(verbatim: "\(detent)")
    }
}

#Preview("DetentSheet · orta") { DetentSheetPreview(detent: .medium) }
#Preview("DetentSheet · küçük · koyu") {
    DetentSheetPreview(detent: .collapsed).preferredColorScheme(.dark)
}
#endif
