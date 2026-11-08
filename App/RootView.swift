import AuthFeature
import DesignSystem
import HomeMapFeature
import SwiftUI

/// Uygulamanın kök görünümü: gezinme yığını ve ekranların `Route` karşılıkları.
///
/// Ekranların kapanışları burada `AppRouter` çağrılarına bağlanır. Henüz karşılığı
/// olmayan istekler (giriş yap, kodun doğrulanması ve tekrar gönderilmesi, ad ve soyadın
/// kaydı) ilgili ekran ve servisler yazıldığında bağlanır.
struct RootView: View {
    let dependencies: AppDependencies

    /// Açılışın kayıt akışını atlayıp doğrudan ana haritaya gitmesi.
    ///
    /// Proje sahibinin kararıyla **geçicidir**: ana sayfa tasarlanırken her açılışta kayıt
    /// akışından geçilmesin diye açıldı (PROGRESS.md Adım 27). Kayıt akışına dönmek için
    /// `false` yapılır. Oturum (`AuthService`, K-10) kurulduğunda bu sabit kaldırılır.
    private static let opensMapOnLaunch = true

    @State private var router = AppRouter(flow: Self.opensMapOnLaunch ? .home : .signUp)

    var body: some View {
        Group {
            switch router.flow {
            case .signUp:
                signUpFlow
            case .home:
                // Butonların ve aramanın açacağı ekranlar henüz yazılmadı; istekler o ekranlar
                // yazıldığında `AppRouter`'a bağlanır.
                HomeMapView(
                    locationSource: dependencies.locationSource,
                    onMenu: {},
                    onSearch: {},
                    onNearbyChargers: {},
                    onSavedPlaces: {}
                )
            }
        }
        .onsarjDynamicTypeRange()
    }

    private var signUpFlow: some View {
        NavigationStack(path: $router.path) {
            WelcomeView(
                onContinue: { router.push(.phoneEntry) },
                onLogin: {}
            )
            // Karşılama ekranının gezinme çubuğu yok; boş çubuk logoyu aşağı iterdi.
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self, destination: destination)
        }
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
                // Kayıtlı kullanıcıyı ayırmak backend'e bağlı (K-10); şimdilik her kod ad
                // ekranına geçer.
                // SMS kodu tek kullanımlıktır: kod doğrulanınca bu ekran yığından çıkarılır ve
                // hiçbir yoldan (geri oku, kenardan kaydırma) geri açılamaz. Harcanmış kodun
                // ekranına dönen kullanıcı çalışmayan bir kodla kalırdı. Yığın:
                // telefon → ad-soyad.
                onSubmit: { _ in router.replaceTop(with: .nameEntry) }
            )
        case .nameEntry:
            NameEntryView(
                // Altta telefon ekranı durur; girilen numara alanda dolu kalır.
                onBack: { router.pop() },
                // Ad ve soyadın kaydı backend'e bağlı (K-10); değerler henüz bir yere
                // gönderilmiyor. Kayıt akışı burada biter ve ana haritaya geçilir.
                onContinue: { _, _ in router.completeSignUp() }
            )
        }
    }
}
