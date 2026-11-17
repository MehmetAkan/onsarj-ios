import AuthFeature
import DesignSystem
import GarageFeature
import HomeMapFeature
import OnsarjDomain
import RoutePlanningFeature
import SearchFeature
import StationDetailFeature
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
                // Butonların açacağı ekranlar henüz yazılmadı; istekler o ekranlar yazıldığında
                // `AppRouter`'a bağlanır. Arama sayfası büyük bir modal olarak açılır (K-25).
                HomeMapView(
                    locationSource: dependencies.locationSource,
                    vehicleRepository: dependencies.vehicleRepository,
                    batteryLevelStore: dependencies.batteryLevelStore,
                    stationRepository: dependencies.stationRepository,
                    onMenu: {},
                    onSearchTapped: { router.isSearchPresented = true },
                    onAssistant: {},
                    onCategory: { _ in },
                    onOptions: { router.isPlanOptionsPresented = true },
                    onSavedPlans: {},
                    onNearbyChargers: {},
                    onSavedPlaces: {},
                    onSwitchVehicle: { router.garage = .vehicles },
                    onVehicleSettings: { router.vehicleSettings = VehicleSettingsPresentation(vehicleID: $0) },
                    onAddVehicle: { router.garage = .addVehicle },
                    selectedStation: $router.selectedStation,
                    vehicleRevision: router.vehicleRevision
                )
                .sheet(isPresented: $router.isSearchPresented) {
                    searchSheet
                }
                .sheet(isPresented: $router.isPlanOptionsPresented) {
                    planOptionsSheet
                }
                .sheet(item: $router.vehicleSettings, onDismiss: router.vehiclesDidChange) { presentation in
                    vehicleSettingsSheet(presentation)
                }
                .sheet(item: $router.garage, onDismiss: router.vehiclesDidChange) { presentation in
                    garageSheet(presentation)
                }
                .sheet(isPresented: isStationDetailPresented) {
                    stationDetailSheet
                }
            }
        }
        .onsarjDynamicTypeRange()
    }

    /// İstasyon detayı, haritada bir pin seçiliyken açık. Sayfa kapanınca (X, aşağı çekme) seçim kalkar.
    private var isStationDetailPresented: Binding<Bool> {
        Binding(
            get: { router.selectedStation != nil },
            set: { isPresented in
                if !isPresented { router.selectedStation = nil }
            }
        )
    }

    /// İstasyon detay sayfası (2.9: sistem `.sheet`, orta ve büyük kademe). Orta kademede arkadaki harita
    /// etkileşime açıktır: başka bir pine dokununca seçim değişir ve sayfa kapanmadan o istasyonla yenilenir
    /// (`.id`); boş haritaya dokununca seçim kalkar ve sayfa kapanır. Yol tarifi (rota planlama) ve oylar
    /// henüz yazılmadı; o istekler boş.
    @ViewBuilder
    private var stationDetailSheet: some View {
        if let station = router.selectedStation {
            StationDetailView(
                station: station,
                repository: dependencies.stationRepository,
                onClose: { router.selectedStation = nil },
                onDirections: { _ in },
                onShowReviews: { _ in }
            )
            .id(station.id)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }

    /// Arama sayfası. Sonuç listesi ve kayıtlı yer ekranları henüz yazılmadı; o istekler boş.
    private var searchSheet: some View {
        SearchView(
            history: dependencies.searchHistory,
            suggestions: dependencies.searchSuggestions,
            onClose: { router.isSearchPresented = false },
            onSubmit: { _ in },
            onSelect: { _ in },
            onSetHome: {},
            onSetWork: {},
            onAddSaved: {},
            onDeleteHistory: { _ in }
        )
        .presentationDragIndicator(.visible)
        .onsarjDynamicTypeRange()
    }

    /// Plan seçenekleri; arama sayfasıyla aynı sunum. Değişiklikler anında kaydedildiği için aşağı
    /// çekerek kapatmak bir şey kaybettirmez.
    private var planOptionsSheet: some View {
        PlanOptionsView(
            preferencesStore: dependencies.routePreferencesStore,
            networkCatalog: dependencies.chargingNetworkCatalog,
            onClose: { router.isPlanOptionsPresented = false }
        )
        .presentationDragIndicator(.visible)
        .onsarjDynamicTypeRange()
    }

    /// Araç ayarları; plan seçenekleriyle aynı sunum. Kapanınca ana sayfadaki kart yeniden yüklenir.
    private func vehicleSettingsSheet(_ presentation: VehicleSettingsPresentation) -> some View {
        VehicleSettingsView(
            repository: dependencies.vehicleRepository,
            vehicleID: presentation.vehicleID,
            onClose: { router.vehicleSettings = nil }
        )
        .presentationDragIndicator(.visible)
        .onsarjDynamicTypeRange()
    }

    /// "Araçlarınız" (içerik yüksekliğinde) veya "Araç ekle" (tam yükseklik). Kademeleri `GarageView`
    /// yönetir. Kapanınca ana sayfadaki kart yeniden yüklenir.
    private func garageSheet(_ presentation: GaragePresentation) -> some View {
        GarageView(
            repository: dependencies.vehicleRepository,
            catalog: dependencies.vehicleCatalog,
            start: presentation == .vehicles ? .vehicles : .addVehicle,
            onClose: { router.garage = nil }
        )
        .presentationDragIndicator(.visible)
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
