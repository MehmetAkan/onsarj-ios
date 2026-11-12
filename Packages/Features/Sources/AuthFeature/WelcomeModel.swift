import Observation
import SwiftUI

/// Karşılama ekranının durumu: aktif slayt ve otomatik ilerleme zamanlayıcısı.
///
/// Ortamın otomatik ilerlemeye izin verip vermediğine görünüm karar verir (uygulama ön
/// planda mı, VoiceOver kapalı mı). Model bu izni, kullanıcının kaydırmasını ve son slayda
/// ulaşılıp ulaşılmadığını birleştirerek zamanlayıcıyı yönetir.
@MainActor
@Observable
final class WelcomeModel {

    /// Karşılama ekranındaki tanıtım slaytları, gösterim sırasıyla.
    enum Slide: CaseIterable, Identifiable {
        case charger
        case route
        case navigation

        var id: Self { self }

        var imageName: String {
            switch self {
            case .charger: "onboarding-charger"
            case .route: "onboarding-route"
            case .navigation: "onboarding-navigation"
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .charger: "welcome.slide.charger.title"
            case .route: "welcome.slide.route.title"
            case .navigation: "welcome.slide.navigation.title"
            }
        }

        var body: LocalizedStringKey {
            switch self {
            case .charger: "welcome.slide.charger.body"
            case .route: "welcome.slide.route.body"
            case .navigation: "welcome.slide.navigation.body"
            }
        }
    }

    let slides = Slide.allCases

    private(set) var currentSlide: Slide = .charger

    var currentIndex: Int {
        slides.firstIndex(of: currentSlide) ?? 0
    }

    @ObservationIgnored private let interval: Duration
    @ObservationIgnored private var autoAdvanceTask: Task<Void, Never>?

    /// Ortam otomatik ilerlemeye izin veriyor mu (uygulama ön planda, VoiceOver kapalı).
    @ObservationIgnored private var isAutoAdvanceAllowed = false

    /// Son slayda bir kez ulaşıldı mı. Ulaşıldıysa otomatik ilerleme bir daha başlamaz:
    /// kullanıcı üç slaydı da görmüştür, döngüye devam etmek bilgi eklemeden hareket ekler.
    @ObservationIgnored private var hasReachedLastSlide = false

    /// - Parameter interval: İki otomatik geçiş arasındaki süre.
    init(interval: Duration = .seconds(3)) {
        self.interval = interval
    }

    /// Kullanıcının kaydırarak seçtiği slayt.
    ///
    /// Zamanlayıcı sıfırdan başlatılır; aksi halde kullanıcı yeni slaydı okurken içerik
    /// altından kayabilirdi.
    func select(_ slide: Slide) {
        guard slide != currentSlide else { return }
        currentSlide = slide
        markIfLastSlide()
        restartAutoAdvance()
    }

    /// Ortamın otomatik ilerlemeye izin verip vermediğini bildirir.
    /// İzin verildiğinde zamanlayıcı sıfırdan başlar.
    func setAutoAdvance(enabled: Bool) {
        isAutoAdvanceAllowed = enabled
        restartAutoAdvance()
    }

    /// Bir sonraki slayda geçer. Son slayttaysa hiçbir şey yapmaz; başa dönülmez.
    func advance() {
        let nextIndex = currentIndex + 1
        guard nextIndex < slides.count else { return }
        withAnimation {
            currentSlide = slides[nextIndex]
        }
        markIfLastSlide()
    }

    private func markIfLastSlide() {
        if currentSlide == slides.last {
            hasReachedLastSlide = true
        }
    }

    private func restartAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        guard isAutoAdvanceAllowed, !hasReachedLastSlide else { return }

        autoAdvanceTask = Task { [weak self, interval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled, let self else { return }
                self.advance()
                if self.hasReachedLastSlide { return }
            }
        }
    }
}
