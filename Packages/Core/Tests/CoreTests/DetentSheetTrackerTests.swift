import CoreGraphics
import Foundation
import Testing

@testable import DesignSystem

@Suite("DetentSheetTracker")
struct DetentSheetTrackerTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)
    private let heights = SheetDetentHeights(collapsed: 100, medium: 400, expanded: 800)
    private var limits: DetentSheetTracker.Limits {
        DetentSheetTracker.Limits(
            heights: heights, detents: [.collapsed, .medium, .expanded], maxContentOffset: 500, dimension: 900)
    }
    /// Büyük kademe sürüklemeyle ulaşılamaz (ana sayfa: yalnızca arama açar).
    private var restricted: DetentSheetTracker.Limits {
        DetentSheetTracker.Limits(
            heights: heights, detents: [.collapsed, .medium], maxContentOffset: 0, dimension: 900)
    }

    private func tracker(at detent: SheetDetent) -> DetentSheetTracker {
        var tracker = DetentSheetTracker(detent: detent)
        tracker.layoutChanged(limits, at: start)
        return tracker
    }

    /// Parmağın ardışık konumlarını (aşağı pozitif) sürükleme olarak verir.
    private func drag(
        _ tracker: inout DetentSheetTracker,
        region: DetentSheetTracker.Region,
        through steps: [CGFloat]
    ) {
        for step in steps {
            tracker.dragChanged(region: region, translation: CGSize(width: 0, height: step), limits: limits, at: start)
        }
    }

    @Test("Dikey sürükleme sayfayı hareket ettirir; içerikteki butonlar dokunuşu yok sayar")
    func verticalDragMovesSheet() {
        var tracker = tracker(at: .medium)
        tracker.dragChanged(region: .content, translation: CGSize(width: 2, height: -12), limits: limits, at: start)

        #expect(tracker.isMovingSheet)

        _ = tracker.dragEnded(velocity: 0, limits: limits, at: start, reduceMotion: false)
        #expect(!tracker.isMovingSheet)
    }

    @Test("Yatay başlayan sürükleme (kategori şeridi) sayfayı hareket ettirmez, butonları engellemez")
    func horizontalDragDoesNotMoveSheet() {
        var tracker = tracker(at: .medium)
        tracker.dragChanged(region: .content, translation: CGSize(width: -12, height: 2), limits: limits, at: start)
        tracker.dragChanged(region: .content, translation: CGSize(width: -80, height: -40), limits: limits, at: start)

        #expect(tracker.isDragging)
        #expect(!tracker.isMovingSheet)
        #expect(tracker.height(at: start) == 400)
    }

    @Test("İçerikte yukarı çekiş önce sayfayı büyütür, büyük kademeden sonra içeriği kaydırır")
    func contentDragUpExpandsThenScrolls() {
        var tracker = tracker(at: .medium)

        drag(&tracker, region: .content, through: [0, -300, -500])

        #expect(tracker.height(at: start) == 800)
        #expect(tracker.contentOffset(at: start) == 100)
    }

    @Test("İçerikte aşağı çekiş önce içeriği en üste döndürür, sonra sayfayı küçültür")
    func contentDragDownScrollsThenShrinks() {
        var tracker = tracker(at: .medium)
        drag(&tracker, region: .content, through: [0, -500])
        _ = tracker.dragEnded(velocity: 0, limits: limits, at: start, reduceMotion: false)
        tracker.finishMotions(limits: limits, at: start.addingTimeInterval(10))
        #expect(tracker.contentOffset(at: start) == 100)

        drag(&tracker, region: .content, through: [0, 60, 250])

        #expect(tracker.contentOffset(at: start) == 0)
        #expect(tracker.height(at: start) == 650)
    }

    @Test("Başlık her zaman sayfayı sürükler, içeriği kaydırmaz")
    func headerDragMovesSheetOnly() {
        var tracker = tracker(at: .medium)

        drag(&tracker, region: .header, through: [0, -200])

        #expect(tracker.height(at: start) == 600)
        #expect(tracker.contentOffset(at: start) == 0)
    }

    @Test("Sınırların ötesinde lastik direnci: sayfa parmaktan az hareket eder")
    func rubberBandBeyondLimits() {
        var tracker = tracker(at: .collapsed)

        drag(&tracker, region: .header, through: [0, 200])

        let height = tracker.height(at: start)
        #expect(height < 100)
        #expect(height > -100)
    }

    @Test("Bırakılan sayfa seçilen kademeye oturur ve kademeyi bildirir")
    func releaseSettlesOnDetent() {
        var tracker = tracker(at: .medium)
        drag(&tracker, region: .header, through: [0, -150])

        let detent = tracker.dragEnded(velocity: 0, limits: limits, at: start, reduceMotion: false)
        tracker.finishMotions(limits: limits, at: start.addingTimeInterval(10))

        #expect(detent == .medium)
        #expect(tracker.height(at: start) == 400)
        #expect(!tracker.isAnimating)
    }

    @Test("Yatay başlayan sürükleme sayfayı hareket ettirmez")
    func horizontalDragIsIgnored() {
        var tracker = tracker(at: .medium)

        tracker.dragChanged(region: .content, translation: CGSize(width: 40, height: 5), limits: limits, at: start)
        tracker.dragChanged(region: .content, translation: CGSize(width: 80, height: -200), limits: limits, at: start)

        #expect(tracker.height(at: start) == 400)
        #expect(tracker.dragEnded(velocity: -900, limits: limits, at: start, reduceMotion: false) == nil)
    }

    @Test("Sürüklenemeyen kademeye çıkılamaz: ortadan yukarı fırlatılan sayfa ortaya döner")
    func restrictedUpperDetentIsNotReachable() {
        var tracker = DetentSheetTracker(detent: .medium)
        tracker.layoutChanged(restricted, at: start)

        for step: CGFloat in [0, -300] {
            tracker.dragChanged(
                region: .header, translation: CGSize(width: 0, height: step), limits: restricted, at: start
            )
        }
        #expect(tracker.height(at: start) < 700)

        let detent = tracker.dragEnded(velocity: -2_000, limits: restricted, at: start, reduceMotion: false)
        #expect(detent == .medium)
    }

    @Test("Aramayla açılan büyük kademeden aşağı sürüklenebilir")
    func expandedCanBeDraggedDown() {
        var tracker = DetentSheetTracker(detent: .expanded)
        let fromExpanded = DetentSheetTracker.Limits(
            heights: heights, detents: [.collapsed, .medium, .expanded], maxContentOffset: 0, dimension: 900
        )
        tracker.layoutChanged(fromExpanded, at: start)

        for step: CGFloat in [0, 350] {
            tracker.dragChanged(
                region: .header, translation: CGSize(width: 0, height: step), limits: fromExpanded, at: start
            )
        }

        #expect(tracker.dragEnded(velocity: 0, limits: fromExpanded, at: start, reduceMotion: false) == .medium)
    }
}
