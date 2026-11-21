import Foundation
import Observation
import OnsarjDomain

/// Haritada gösterilecek istasyonlar: kamera durdukça görünen bölgenin istasyonlarını depodan ister.
///
/// - **Bekleme:** Kamera durduktan `debounce` sonra istenir; arada kamera yeniden durursa önceki istek
///   iptal edilir, yalnızca sonuncusu gider.
/// - **Bölge önbelleği:** Görünen bölge `requestScale` katı genişletilerek istenir. Yakın zamanda alınan
///   bir bölgenin (son `rememberedRegionCount` bölge) içinde kalan görünüm için yeniden istenmez.
/// - **Eşik:** Görünen bölge `maximumRequestSpanDegrees`'tan genişse (ülke ölçeği) istek atılmaz; eldeki
///   istasyonlar gösterilmeye devam eder.
/// - Alınan istasyonlar kimliğe göre birleştirilir. Hata kullanıcıya gösterilmez; o bölge alınmamış
///   sayılır ve kamera yeniden durunca tekrar denenir.
@MainActor
@Observable
final class StationFeed {
    /// İstek atılan en geniş görünüm, boylam derecesi. ~7. yakınlaşma düzeyine (bölge ölçeği) denk gelir;
    /// daha geniş görünümde binlerce istasyon tek istekte istenmez.
    static let maximumRequestSpanDegrees: Double = 3
    /// İstenen bölgenin görünen bölgeye oranı; küçük kaydırmalar yeni istek gerektirmez.
    static let requestScale: Double = 1.5
    /// Bellekte tutulan alınmış bölge sayısı.
    static let rememberedRegionCount = 8
    /// Kamera durduktan sonra istekten önceki bekleme.
    static let defaultDebounce: Duration = .milliseconds(300)

    private(set) var stations: [Station] = []

    @ObservationIgnored private let repository: any StationRepository
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private var fetchedRegions: [GeoBoundingBox] = []
    @ObservationIgnored private var knownIDs: Set<Station.ID> = []
    /// Bekleyen istek; testler sonucunu bekleyebilsin diye görünür.
    @ObservationIgnored private(set) var pendingLoad: Task<Void, Never>?

    init(repository: any StationRepository, debounce: Duration = StationFeed.defaultDebounce) {
        self.repository = repository
        self.debounce = debounce
    }

    /// Kamera durdu; görünen bölge `visible`.
    func cameraDidIdle(_ visible: GeoBoundingBox) {
        pendingLoad?.cancel()
        pendingLoad = nil
        guard visible.longitudeSpan <= Self.maximumRequestSpanDegrees,
            !fetchedRegions.contains(where: { $0.contains(visible) })
        else { return }
        let region = visible.scaled(by: Self.requestScale)
        pendingLoad = Task { [weak self, debounce] in
            do {
                try await Task.sleep(for: debounce)
                try await self?.load(region)
            } catch {
                return
            }
        }
    }

    private func load(_ region: GeoBoundingBox) async throws {
        let loaded = try await repository.stations(in: region)
        try Task.checkCancellation()
        remember(region)
        let new = loaded.filter { !knownIDs.contains($0.id) }
        guard !new.isEmpty else { return }
        knownIDs.formUnion(new.map(\.id))
        stations.append(contentsOf: new)
    }

    private func remember(_ region: GeoBoundingBox) {
        fetchedRegions.append(region)
        if fetchedRegions.count > Self.rememberedRegionCount {
            fetchedRegions.removeFirst()
        }
    }
}
