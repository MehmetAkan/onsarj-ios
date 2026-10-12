import SwiftUI

/// Marka görsellerine erişim noktası.
///
/// Görseller `DesignSystem` modülünün kaynaklarında durur. Özellik modülleri
/// görsele adıyla ve paket bilgisiyle değil, bu tip üzerinden erişir.
public enum BrandAsset {

    /// Marka logosu. Açık ve koyu tema için ayrı varyantı vardır; tema değişince
    /// kendiliğinden doğru varyant seçilir.
    public static var logo: Image { Image("brand-logo", bundle: .module) }

    /// Logonun gösterim yüksekliği. Genişlik en-boy oranından kendiliğinden hesaplanır.
    ///
    /// Görselin doğal boyutu (291×82 pt) ekranda fazla yer kaplar; logo her yerde
    /// bu yükseklikle gösterilir.
    public static let logoHeight: CGFloat = 35
}
