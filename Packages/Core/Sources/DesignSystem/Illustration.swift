import SwiftUI

/// Boş ve bilgi hallerinde kullanılan illüstrasyonlara erişim noktası.
///
/// Görseller `DesignSystem` modülünün kaynaklarında durur. Özellik modülleri görsele adıyla ve
/// paket bilgisiyle değil, bu tip üzerinden erişir (`BrandAsset` ile aynı düzen).
public enum Illustration {

    /// Henüz araç eklenmemiş garajın görseli. Arka plan olarak, `Effects.Muted` ile soluk çizilir.
    public static var vehicleEmptyState: Image { Image("vehicle-empty-state", bundle: .module) }
}
