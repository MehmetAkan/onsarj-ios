import CoreGraphics
import Foundation

/// `DetentSheet`'in hareket durumu: sayfa yüksekliği, içerik kaydırması ve süren sürükleme.
///
/// Görünümden bağımsızdır, zaman dışarıdan verilir; birim testle sınanabilir.
///
/// **Sürüklemenin dağıtımı.** Parmağın her küçük hareketi sayfa ile içerik arasında bölünür:
/// - Üst bölge (sürükleme göstergesi ve başlık) her zaman sayfayı sürükler.
/// - İçerik bölgesinde yukarı çekiş önce sayfayı ulaşılabilen en büyük kademeye kadar
///   büyütür, artanı içeriği kaydırır. Aşağı çekiş önce içeriği en üste döndürür, artanı sayfayı küçültür.
///
/// Bölme her harekette yeniden yapıldığı için parmak kalkmadan iki mod arasında geçilirken
/// sıçrama olmaz.
struct DetentSheetTracker {
    enum Region {
        case header
        case content
    }

    /// Hareketin sınırları; görünümün ölçümünden gelir.
    struct Limits: Equatable {
        var heights: SheetDetentHeights
        /// Sürüklemeyle ulaşılabilen kademeler, küçükten büyüğe; boş olamaz.
        var detents: [SheetDetent]
        /// İçeriğin en fazla kaydırılabileceği miktar.
        var maxContentOffset: CGFloat
        /// Lastik direncinin ölçeği: ekranın yüksekliği.
        var dimension: CGFloat

        var lowerHeight: CGFloat { heights[detents.first ?? .collapsed] }
        var upperHeight: CGFloat { heights[detents.last ?? .expanded] }
        var upperDetent: SheetDetent { detents.last ?? .expanded }
    }

    private struct Drag {
        let region: Region
        /// Yatay başlayan sürükleme (ör. içerikteki yatay liste) sayfayı hareket ettirmez.
        let isIgnored: Bool
        var lastTranslation: CGFloat
        /// Sınırlar uygulanmadan önceki yükseklik ve kaydırma; görünen değer bunlara lastik
        /// direnci uygulanarak bulunur.
        var rawHeight: CGFloat
        var rawOffset: CGFloat
    }

    /// UIKit kaydırma görünümünün sınır ötesi direnç katsayısı.
    private static let rubberBandCoefficient: CGFloat = 0.55

    private(set) var sheet: SheetMotion = .resting(0)
    private(set) var content: SheetMotion = .resting(0)
    /// Sayfanın bulunduğu ya da oturmakta olduğu kademe.
    private(set) var detent: SheetDetent
    private var drag: Drag?

    init(detent: SheetDetent) {
        self.detent = detent
    }

    var isDragging: Bool { drag != nil }
    var isAnimating: Bool { !sheet.isResting || !content.isResting }

    func height(at date: Date) -> CGFloat { sheet.value(at: date) }
    func contentOffset(at date: Date) -> CGFloat { content.value(at: date) }

    // MARK: - Ölçü ve kademe değişimi

    /// Kademe yükseklikleri değişti (ilk ölçüm, yazı boyutu). Duran sayfa yeni yüksekliğe geçer.
    mutating func layoutChanged(_ limits: Limits, at date: Date) {
        guard drag == nil, !isAnimating else { return }
        sheet = .resting(limits.heights[detent])
        content = .resting(Self.clamp(content.value(at: date), to: limits))
    }

    /// Kademeyi dışarıdan değiştirir (bağlama, VoiceOver). Sürükleme sürerken yok sayılır.
    mutating func move(to detent: SheetDetent, limits: Limits, at date: Date, reduceMotion: Bool) {
        guard drag == nil else { return }
        self.detent = detent
        sheet = .settle(
            from: sheet.value(at: date),
            to: limits.heights[detent],
            velocity: sheet.velocity(at: date),
            start: date,
            reduceMotion: reduceMotion
        )
    }

    /// İçeriği verilen miktar kadar kaydırır (VoiceOver kaydırması).
    mutating func scrollContent(by amount: CGFloat, limits: Limits, at date: Date, reduceMotion: Bool) {
        guard drag == nil else { return }
        let current = content.value(at: date)
        content = .settle(
            from: current,
            to: Self.clamp(current + amount, to: limits),
            velocity: 0,
            start: date,
            reduceMotion: reduceMotion
        )
    }

    /// Biten hareketleri duruşa çevirir. Sayfa, kademesinin güncel yüksekliğine oturur.
    mutating func finishMotions(limits: Limits, at date: Date) {
        if !sheet.isResting, sheet.isFinished(at: date) {
            sheet = .resting(limits.heights[detent])
        }
        if !content.isResting, content.isFinished(at: date) {
            content = .resting(Self.clamp(content.value(at: date), to: limits))
        }
    }

    // MARK: - Sürükleme

    /// - Parameter translation: Sürüklemenin başından beri parmağın yer değiştirmesi;
    ///   pozitif `height` aşağı yön.
    mutating func dragChanged(region: Region, translation: CGSize, limits: Limits, at date: Date) {
        guard var current = drag else {
            begin(region: region, translation: translation, at: date)
            return
        }
        guard !current.isIgnored else { return }
        let upward = current.lastTranslation - translation.height
        current.lastTranslation = translation.height
        Self.distribute(upward, into: &current, upperHeight: limits.upperHeight)
        drag = current
        apply(current, limits: limits)
    }

    /// Sürüklemeyi bitirir ve sayfayı bir kademeye oturtur.
    ///
    /// - Parameter velocity: Bırakma hızı, nokta/saniye; pozitif değer aşağı yön.
    /// - Returns: Sayfanın oturacağı kademe; sürükleme yok sayıldıysa `nil`.
    mutating func dragEnded(velocity: CGFloat, limits: Limits, at date: Date, reduceMotion: Bool) -> SheetDetent? {
        guard let ended = drag else { return nil }
        drag = nil
        guard !ended.isIgnored else { return nil }

        let growth = -velocity
        let height = sheet.value(at: date)
        let offset = content.value(at: date)
        let range = 0...limits.maxContentOffset
        let contentOwnsRelease =
            ended.region == .content && ended.rawOffset > 0 && ended.rawHeight >= limits.upperHeight

        if contentOwnsRelease {
            detent = limits.upperDetent
            content = .momentum(from: offset, velocity: growth, range: range, start: date, reduceMotion: reduceMotion)
        } else {
            let candidates = limits.detents.map { limits.heights[$0] }
            let index = DetentResolver.resolve(position: height, velocity: growth, detents: candidates)
            detent = index.map { limits.detents[$0] } ?? detent
            if !range.contains(offset) {
                content = .momentum(from: offset, velocity: 0, range: range, start: date, reduceMotion: reduceMotion)
            }
        }
        sheet = .settle(
            from: height,
            to: limits.heights[detent],
            velocity: contentOwnsRelease ? 0 : growth,
            start: date,
            reduceMotion: reduceMotion
        )
        return detent
    }

    private mutating func begin(region: Region, translation: CGSize, at date: Date) {
        let isIgnored = abs(translation.width) > abs(translation.height)
        let height = sheet.value(at: date)
        let offset = content.value(at: date)
        drag = Drag(
            region: region,
            isIgnored: isIgnored,
            lastTranslation: translation.height,
            rawHeight: height,
            rawOffset: offset
        )
        guard !isIgnored else { return }
        // Süren hareket parmağın altında durur.
        sheet = .resting(height)
        content = .resting(offset)
    }

    private mutating func apply(_ drag: Drag, limits: Limits) {
        sheet = .resting(
            Self.rubberBand(drag.rawHeight, range: limits.lowerHeight...limits.upperHeight, dimension: limits.dimension)
        )
        content = .resting(
            Self.rubberBand(drag.rawOffset, range: 0...limits.maxContentOffset, dimension: limits.dimension)
        )
    }

    private static func distribute(_ upward: CGFloat, into drag: inout Drag, upperHeight: CGFloat) {
        switch drag.region {
        case .header:
            drag.rawHeight += upward
        case .content where upward > 0:
            let growth = min(upward, max(0, upperHeight - drag.rawHeight))
            drag.rawHeight += growth
            drag.rawOffset += upward - growth
        case .content:
            let downward = -upward
            let scroll = min(downward, max(0, drag.rawOffset))
            drag.rawOffset -= scroll
            drag.rawHeight -= downward - scroll
        }
    }

    // MARK: - Sınırlar

    /// Sınır içindeki değeri olduğu gibi, sınır dışındakini azalan bir dirençle verir.
    static func rubberBand(_ value: CGFloat, range: ClosedRange<CGFloat>, dimension: CGFloat) -> CGFloat {
        guard dimension > 0 else { return min(max(value, range.lowerBound), range.upperBound) }
        if value > range.upperBound {
            return range.upperBound + resistance(value - range.upperBound, dimension: dimension)
        }
        if value < range.lowerBound {
            return range.lowerBound - resistance(range.lowerBound - value, dimension: dimension)
        }
        return value
    }

    private static func resistance(_ overshoot: CGFloat, dimension: CGFloat) -> CGFloat {
        (1 - 1 / (overshoot * rubberBandCoefficient / dimension + 1)) * dimension
    }

    private static func clamp(_ offset: CGFloat, to limits: Limits) -> CGFloat {
        min(max(offset, 0), limits.maxContentOffset)
    }
}
