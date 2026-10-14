import AuthFeature
import DesignSystem
import SwiftUI

/// Uygulamanın kök görünümü: gezinme yığını ve ekranların `Route` karşılıkları.
///
/// Ekranların kapanışları burada `AppRouter` çağrılarına bağlanır. Henüz karşılığı
/// olmayan istekler (giriş yap, kodun doğrulanması ve tekrar gönderilmesi) ilgili ekran
/// ve servisler yazıldığında bağlanır.
struct RootView: View {
    let dependencies: AppDependencies

    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            WelcomeView(
                onContinue: { router.push(.phoneEntry) },
                onLogin: {}
            )
            // Karşılama ekranının gezinme çubuğu yok; boş çubuk logoyu aşağı iterdi.
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self, destination: destination)
        }
        .onsarjDynamicTypeRange()
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .phoneEntry:
            PhoneEntryView(
                formatter: dependencies.phoneNumberFormatter,
                onBack: { router.pop() },
                onContinue: { router.push(.verificationCode(phoneNumber: $0)) }
            )
        case .verificationCode(let phoneNumber):
            VerificationCodeView(
                phoneNumber: phoneNumber,
                formatter: dependencies.phoneNumberFormatter,
                // Telefon ekranı yığında altta durur ve durumunu korur; geri dönüldüğünde
                // girilen numara alanda dolu kalır.
                onBack: { router.pop() },
                onResend: {},
                onSubmit: { _ in }
            )
        }
    }
}
