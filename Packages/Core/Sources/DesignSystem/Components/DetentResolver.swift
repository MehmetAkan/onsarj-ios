import CoreGraphics

/// Bırakılan sayfanın oturacağı kademeyi seçer.
///
/// Seçim, bırakma konumundan ve hızdan yansıtılan bitiş konumuna göre yapılır:
/// - **Yavaş bırakma:** yansıtılan konuma en yakın kademe.
/// - **Hızlı fırlatma:** fırlatma yönündeki kademeler arasından yansıtılan konuma en yakını;
///   en az bir sonraki kademe. O yönde kademe kalmadıysa en yakın kademe.
///
/// Saf fonksiyondur; görünümden bağımsız olarak birim testle sınanır.
enum DetentResolver {
    /// Bu hızın (nokta/saniye) üstündeki bırakma fırlatma sayılır.
    static let flingVelocity: CGFloat = 500

    /// Bırakılan sayfanın, verilen hızla yavaşlayarak duracağı konum.
    ///
    /// UIKit kaydırma görünümünün normal yavaşlama oranı kullanılır; parmağın alıştığı his budur.
    static func projectedPosition(_ position: CGFloat, velocity: CGFloat) -> CGFloat {
        position + velocity * SheetMotion.decelerationDistancePerVelocity
    }

    /// - Parameters:
    ///   - position: Bırakıldığı andaki yükseklik.
    ///   - velocity: Bırakma hızı, nokta/saniye; pozitif değer sayfanın büyüdüğü yön.
    ///   - detents: Kademe yükseklikleri, küçükten büyüğe.
    /// - Returns: Seçilen kademenin `detents` içindeki sırası; liste boşsa `nil`.
    static func resolve(position: CGFloat, velocity: CGFloat, detents: [CGFloat]) -> Int? {
        guard !detents.isEmpty else { return nil }
        let projected = projectedPosition(position, velocity: velocity)
        let all = Array(detents.indices)

        let directional: [Int]
        if velocity >= flingVelocity {
            directional = all.filter { detents[$0] > position }
        } else if velocity <= -flingVelocity {
            directional = all.filter { detents[$0] < position }
        } else {
            directional = all
        }

        let candidates = directional.isEmpty ? all : directional
        return candidates.min { abs(detents[$0] - projected) < abs(detents[$1] - projected) }
    }
}
