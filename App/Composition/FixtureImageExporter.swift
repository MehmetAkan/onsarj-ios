#if DEBUG
import DesignSystem
import SwiftUI
import UIKit

/// Fixture'ların görsellerini (K-23, K-24, K-26) yerel dosyalara yazar. Yalnızca Debug derlemesinde var.
///
/// Fixture JSON'ları görsele adıyla başvurur; depolar adı buradan dönen sözlükle yerel dosya adresine
/// (`file://`) çevirir. Yazılamayan veya bulunamayan görsel sözlüğe girmez; kayıt görselsiz yüklenir
/// (araç kartı görselsiz, istasyon pini şimşekli).
///
/// - **Araç görseli** `DesignSystem`'deki illüstrasyondur; `ImageRenderer` ile şeffaflığı korunarak PNG'ye
///   çevrilir.
/// - **Şarj ağı logoları** uygulama hedefindeki `DebugFixtures/Media.xcassets` kataloğundandır.
@MainActor
enum FixtureImageExporter {
    /// Fixture JSON'undaki araç görseli adı.
    private static let vehicleImageName = "vehicle-empty-state"
    /// İstasyon fixture'ındaki şarj ağı logo adları (`DebugFixtures/Media.xcassets`).
    private static let networkLogoNames = ["operator-togg", "operator-zes", "operator-esarj", "operator-shell"]
    /// `Caches` altındaki klasör.
    private static let directoryName = "onsarj-fixture"
    /// Çizim ölçeği: en yoğun ekranın piksel yoğunluğu.
    private static let renderScale: CGFloat = 3

    /// Görselleri yazar; ad → dosya adresi.
    static func exportImages() -> [String: URL] {
        var urls: [String: URL] = [:]
        urls[vehicleImageName] = render(Illustration.vehicleEmptyState).flatMap { write($0, named: vehicleImageName) }
        for name in networkLogoNames {
            urls[name] = UIImage(named: name)?.pngData().flatMap { write($0, named: name) }
        }
        return urls
    }

    private static func render(_ image: Image) -> Data? {
        let renderer = ImageRenderer(content: image)
        renderer.scale = renderScale
        renderer.isOpaque = false
        return renderer.uiImage?.pngData()
    }

    private static func write(_ data: Data, named name: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = caches.appending(path: directoryName, directoryHint: .isDirectory)
        let file = directory.appending(path: "\(name).png", directoryHint: .notDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: file, options: .atomic)
            return file
        } catch {
            return nil
        }
    }
}
#endif
