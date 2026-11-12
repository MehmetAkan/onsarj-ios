import DesignSystem
import Localization
import SwiftUI

/// Karşılama ekranı: otomatik ilerleyen tanıtım slaytları ve giriş eylemleri.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1). Kullanıcının isteği
/// `onContinue` ve `onLogin` ile dışarı bildirilir; hedef ekranı uygulama katmanı açar.
public struct WelcomeView: View {
    private let onContinue: () -> Void
    private let onLogin: () -> Void

    @State private var model = WelcomeModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled

    /// - Parameters:
    ///   - onContinue: Kullanıcı "Telefon ile Devam Et" butonuna dokunduğunda çağrılır.
    ///   - onLogin: Kullanıcı "Giriş yap" bağlantısına dokunduğunda çağrılır.
    public init(onContinue: @escaping () -> Void, onLogin: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onLogin = onLogin
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            BrandAsset.logo
                .resizable()
                .scaledToFit()
                .frame(height: BrandAsset.logoHeight)
                .accessibilityHidden(true)

            slides

            PageIndicator(count: model.slides.count, currentIndex: model.currentIndex)

            actions
        }
        .padding(.vertical, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .onAppear(perform: updateAutoAdvance)
        .onDisappear { model.setAutoAdvance(enabled: false) }
        .onChange(of: scenePhase, updateAutoAdvance)
        .onChange(of: isVoiceOverEnabled, updateAutoAdvance)
    }

    private var slides: some View {
        let selection = Binding(
            get: { model.currentSlide },
            set: { model.select($0) }
        )
        let pager = TabView(selection: selection) {
            ForEach(model.slides) { slide in
                OnboardingSlide(slide: slide)
                    .tag(slide)
            }
        }
        #if os(iOS)
        return pager.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        return pager
        #endif
    }

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            PrimaryButton("welcome.action.continue", bundle: .onsarj, action: onContinue)

            loginRow
        }
        .padding(.horizontal, Spacing.screenMargin)
    }

    /// Soru ve bağlantı yan yana sığmazsa (büyük yazı boyutu, dar ekran) alt alta dizilir.
    private var loginRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.xs) {
                loginQuestion
                loginButton
            }
            VStack(spacing: Spacing.xs) {
                loginQuestion
                loginButton
            }
        }
        .font(Typography.secondary)
    }

    private var loginQuestion: some View {
        Text("welcome.login.question", bundle: .onsarj)
            .foregroundStyle(Theme.textSecondary)
    }

    private var loginButton: some View {
        Button(action: onLogin) {
            Text("welcome.login.action", bundle: .onsarj)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.textPrimary)
                .frame(minHeight: Spacing.minTapTarget)
        }
    }

    /// Otomatik ilerleme yalnızca uygulama ön plandayken ve VoiceOver kapalıyken çalışır.
    /// Ekran okuyucu bir metni seslendirirken içeriğin kayması kullanıcıyı içerikten koparır.
    private func updateAutoAdvance() {
        model.setAutoAdvance(enabled: scenePhase == .active && !isVoiceOverEnabled)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × Large ve xxxLarge; ayrıca koyu tema.
struct WelcomeViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]

    static var previews: some View {
        Group {
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    WelcomeView(onContinue: {}, onLogin: {})
                        .dynamicTypeSize(typeSize)
                        .previewDevice(PreviewDevice(rawValue: device))
                        .previewDisplayName("\(device) · \(typeSize)")
                }
            }

            WelcomeView(onContinue: {}, onLogin: {})
                .preferredColorScheme(.dark)
                .previewDevice(PreviewDevice(rawValue: devices[1]))
                .previewDisplayName("\(devices[1]) · koyu")
        }
    }
}
#endif
