import Foundation
import Observation
import OnsarjDomain

/// İstasyon detay sayfasının durumu.
///
/// Sayfa pinden bilinen özetle (`Station`) açılır: başlık hemen görünür, detay ayrı istekle yüklenir.
/// Yükleme başarısız olursa hata gösterilir ve tekrar denenebilir.
@MainActor
@Observable
final class StationDetailModel {
    enum State: Equatable {
        case loading
        case loaded(StationDetail)
        case failed
    }

    /// "Adres kopyalandı" geri bildiriminin görünme süresi.
    static let copyFeedbackDuration: Duration = .seconds(2)

    let station: Station
    private(set) var state: State = .loading
    /// Adres kopyalandı geri bildirimi görünüyor mu.
    private(set) var isAddressCopied = false
    /// Her kopyalamada artar; titreşim bu değerin değişimine bağlıdır.
    private(set) var copyCount = 0

    @ObservationIgnored private let repository: any StationRepository
    @ObservationIgnored private let copyToPasteboard: @MainActor (String) -> Void
    @ObservationIgnored private var feedbackTask: Task<Void, Never>?

    /// - Parameters:
    ///   - station: Pinden bilinen özet.
    ///   - repository: Detayın kaynağı.
    ///   - copyToPasteboard: Metni panoya yazar.
    init(
        station: Station,
        repository: any StationRepository,
        copyToPasteboard: @escaping @MainActor (String) -> Void
    ) {
        self.station = station
        self.repository = repository
        self.copyToPasteboard = copyToPasteboard
    }

    var detail: StationDetail? {
        if case .loaded(let detail) = state { detail } else { nil }
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await repository.stationDetail(station.id))
        } catch {
            state = .failed
        }
    }

    /// Adresi panoya yazar ve kısa bir geri bildirim gösterir.
    func copyAddress() {
        guard let detail else { return }
        copyToPasteboard(detail.address)
        copyCount += 1
        isAddressCopied = true
        feedbackTask?.cancel()
        feedbackTask = Task { [weak self] in
            try? await Task.sleep(for: Self.copyFeedbackDuration)
            guard !Task.isCancelled else { return }
            self?.isAddressCopied = false
        }
    }

    /// Paylaşım metni; adres yüklenmediyse adressiz.
    var shareText: String {
        StationShareText.text(for: station, address: detail?.address)
    }
}
