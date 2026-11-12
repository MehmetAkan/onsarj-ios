#if canImport(UIKit)
import SwiftUI
import UIKit

/// Sistem gezinme çubuğunu gizler, kenardan kaydırarak geri dönmeyi açık tutar.
///
/// `ScreenHeader` kullanan ekranlar sistem çubuğunu gizler. UIKit, çubuk gizliyken kenardan
/// kaydırma hareketini (`interactivePopGestureRecognizer`) kendiliğinden kapatır. Bu
/// değiştirici hareketi geri açar: yığında birden fazla ekran varsa ve bir geçiş sürmüyorsa
/// hareket başlar. Kaydırma sistemin kendi animasyonuyla, parmağı izleyerek bir ekran geri
/// gider.
///
/// **Kaydırma ekran ekran kapatılmaz.** Geri dönülmemesi gereken bir ekran varsa (ör. SMS
/// kodu tek kullanımlık olduğu için kod ekranı) o ekran gezinme yığınından çıkarılır; böylece
/// geri oku da kaydırma da aynı, doğru yere gider. Kaydırmayı kapatıp ekranı yığında bırakmak
/// kuralı yalnızca bir yoldan korur.
///
/// Dosyanın tamamı UIKit'e özeldir (CLAUDE.md 6.8, üçüncü durum).
struct HiddenNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .background(PopGestureEnabler())
    }
}

extension View {
    /// Sistem gezinme çubuğunu gizler, kenardan kaydırarak geri dönmeyi açık tutar.
    /// Bkz. `HiddenNavigationBar`.
    public func hidesNavigationBar() -> some View {
        modifier(HiddenNavigationBar())
    }
}

/// Ekranın bulunduğu `UINavigationController`'a ulaşmak için görünmez bir denetleyici.
private struct PopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ controller: Controller, context: Context) {}

    final class Controller: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.delegate = PopGestureDelegate.shared
        }
    }
}

/// Bütün gezinme denetleyicileri için ortak, durumsuz temsilci. Temsilci zayıf tutulduğu için
/// paylaşılan tek örnek kullanılır; ekran kapanınca temsilci boşa düşmez.
@MainActor
private final class PopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = PopGestureDelegate()

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Hareket, gezinme denetleyicisinin kök görünümüne bağlıdır; görünümün bir sonraki
        // yanıtlayıcısı denetleyicinin kendisidir.
        guard let navigationController = gestureRecognizer.view?.next as? UINavigationController else {
            return false
        }
        return navigationController.viewControllers.count > 1
            && navigationController.transitionCoordinator == nil
    }
}
#endif
