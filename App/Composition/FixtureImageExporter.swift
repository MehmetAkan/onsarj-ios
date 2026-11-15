#if DEBUG
import DesignSystem
import SwiftUI
import UIKit

/// Fixture aracının görselini (K-23, K-24) yerel bir dosyaya yazar. Yalnızca Debug derlemesinde var.
///
/// Fixture JSON'u görsele adıyla başvurur; `FixtureVehicleRepository` adı buradan dönen sözlükle
/// yerel dosya adresine çevirir. Görsel `DesignSystem`'deki illüstrasyondur ve `ImageRenderer` ile
/// şeffaflığı korunarak PNG'ye çevrilir. Yazılamayan görsel sözlüğe girmez; araç görselsiz yüklenir.
@MainActor
enum FixtureImageExporter {
    /// Fixture JSON'undaki görsel adı.
    private static let vehicleImageName = "vehicle-empty-state"
    /// `Caches` altındaki klasör.
    private static let directoryName = "onsarj-fixture"
    /// Çizim ölçeği: en yoğun ekranın piksel yoğunluğu.
    private static let renderScale: CGFloat = 3

    /// Görselleri yazar; ad → dosya adresi.
    static func exportImages() -> [String: URL] {
        guard let url = export(Illustration.vehicleEmptyState, named: vehicleImageName) else { return [:] }
        return [vehicleImageName: url]
    }

    private static func export(_ image: Image, named name: String) -> URL? {
        let renderer = ImageRenderer(content: image)
        renderer.scale = renderScale
        renderer.isOpaque = false
        guard let data = renderer.uiImage?.pngData(),
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else {
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
