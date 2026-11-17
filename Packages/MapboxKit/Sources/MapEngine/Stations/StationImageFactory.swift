import OnsarjDomain
import SwiftUI
import UIKit

/// İstasyon pinlerini ve kümelerini SwiftUI ile bir kez çizer, sonucu önbellekte tutar.
///
/// Harita her karede görsel çizmez: stile eklenen görseli kullanır. Görsel, harita onu ilk kez
/// istediğinde (eksik görsel olayı) üretilir; ağ × müsaitlik × seçili ve küme yazısı başına bir kez.
/// Stil yeniden yüklenince harita görselleri yeniden ister ve önbellekten verilir.
///
/// **Logolar** ağın `logoURL`'sinden bir kez yüklenir (`file://` veya `https`). Logo gelmeden istenen
/// pin şimşekle çizilir; logo gelince o ağın görselleri yeniden çizilir ve `onImagesChanged` haber verir.
@MainActor
final class StationImageFactory {
    /// Bir ağın logosu yüklendiğinde, yeniden çizilen görsellerin adlarıyla çağrılır.
    var onImagesChanged: (([StationImageKey: UIImage]) -> Void)?

    private var images: [StationImageKey: UIImage] = [:]
    private var logos: [ChargingNetwork.ID: UIImage] = [:]
    private var requestedLogos: Set<URL> = []
    private let displayScale: CGFloat

    init(displayScale: CGFloat) {
        self.displayScale = displayScale
    }

    /// Adı verilen görsel; ad tanınmazsa `nil`.
    func image(named name: String) -> UIImage? {
        guard let key = StationImageKey(name: name) else { return nil }
        if let cached = images[key] { return cached }
        let image = render(key)
        images[key] = image
        return image
    }

    /// İstasyonların ağ logolarını, daha önce istenmediyse yükler.
    func loadLogos(for stations: [Station]) {
        var networks: [ChargingNetwork.ID: URL] = [:]
        for station in stations {
            if let url = station.network.logoURL, !requestedLogos.contains(url) {
                networks[station.network.id] = url
            }
        }
        for (network, url) in networks {
            requestedLogos.insert(url)
            Task { await loadLogo(for: network, from: url) }
        }
    }

    private func loadLogo(for network: ChargingNetwork.ID, from url: URL) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url), let logo = UIImage(data: data) else {
            return
        }
        logos[network] = logo
        var redrawn: [StationImageKey: UIImage] = [:]
        for key in images.keys {
            if case .pin(network, _, _) = key {
                let image = render(key)
                images[key] = image
                redrawn[key] = image
            }
        }
        if !redrawn.isEmpty {
            onImagesChanged?(redrawn)
        }
    }

    private func render(_ key: StationImageKey) -> UIImage? {
        switch key {
        case .pin(let network, let availability, let isSelected):
            let logo = logos[network].map { Image(uiImage: $0) }
            return render(StationPinView(availability: availability, logo: logo, isSelected: isSelected))
        case .cluster(let label):
            let count = Int(label.filter(\.isNumber)) ?? 0
            return render(StationClusterView(label: label, size: .init(count: count)))
        }
    }

    /// Görseller açık temada ve varsayılan yazı boyutunda çizilir: harita öğelerinin ölçüsü taslaktan gelir
    /// ve pin renkleri iki temada aynıdır.
    private func render(_ view: some View) -> UIImage? {
        let renderer = ImageRenderer(
            content:
                view
                .environment(\.colorScheme, .light)
                .environment(\.dynamicTypeSize, .large)
        )
        renderer.scale = displayScale
        renderer.isOpaque = false
        return renderer.uiImage
    }
}
