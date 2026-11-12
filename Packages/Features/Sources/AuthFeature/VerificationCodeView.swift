import DesignSystem
import Localization
import PhoneNumbers
import SwiftUI

/// SMS doğrulama kodu ekranı: kayıt akışında telefon ekranından sonra gelir.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1). Geri dönüş `onBack`, tekrar
/// gönderme `onResend`, kod `onSubmit` ile dışarı bildirilir. Numarayı değiştirmek isteyen
/// kullanıcı geri okunu kullanır. Ekran uygulama katmanında bir `NavigationStack` içinde
/// gösterilmelidir; sistem gezinme çubuğunu gizler, yerine `ScreenHeader` kullanır.
public struct VerificationCodeView: View {
    private let onBack: () -> Void
    private let onResend: () -> Void

    @State private var model: VerificationCodeModel

    /// - Parameters:
    ///   - phoneNumber: Kodun gönderildiği numara, E.164 biçiminde: `"+905537359394"`.
    ///   - formatter: Uygulama boyunca paylaşılan telefon numarası biçimleyicisi.
    ///   - resendInterval: Tekrar gönderme için beklenecek süre, saniye.
    ///   - onBack: Kullanıcı geri okuna dokunduğunda çağrılır.
    ///   - onResend: Geri sayım bitince tekrar göndermeye dokunulduğunda çağrılır.
    ///   - onSubmit: Kod tamamlandığında ya da "Devam"a dokunulduğunda çağrılır. Kod yanlışsa
    ///     `VerificationCodeError` fırlatır; mesaj ekranda gösterilir. Kapanış sürerken
    ///     ikinci bir gönderim yapılmaz.
    public init(
        phoneNumber: String,
        formatter: PhoneNumberFormatter,
        resendInterval: TimeInterval = 60,
        onBack: @escaping () -> Void,
        onResend: @escaping () -> Void,
        onSubmit: @escaping @MainActor (_ code: String) async throws(VerificationCodeError) -> Void
    ) {
        let parsed = formatter.parse(phoneNumber, for: formatter.defaultCountry())
        let model = VerificationCodeModel(
            phoneNumber: "\(parsed.country.displayDialCode) \(parsed.formatted)",
            resendInterval: resendInterval,
            onSubmit: onSubmit
        )
        self.init(model: model, onBack: onBack, onResend: onResend)
    }

    init(
        model: VerificationCodeModel,
        onBack: @escaping () -> Void,
        onResend: @escaping () -> Void
    ) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.onResend = onResend
    }

    public var body: some View {
        ScrollView {
            content
        }
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
        .safeAreaInset(edge: .top) {
            ScreenHeader(
                "verification.navTitle",
                backLabel: "signup.phone.accessibility.back",
                bundle: .onsarj,
                onBack: onBack
            )
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .hidesNavigationBar()
        .onChange(of: model.error) { _, error in
            if let error {
                AccessibilityNotification.Announcement(error.message).post()
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            IconBadge(image: Image("sms-entry-icon", bundle: .module))

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("verification.title", bundle: .onsarj)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                description
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                CodeInputField(
                    code: Binding(get: { model.code }, set: { model.updateCode($0) }),
                    length: VerificationCodeModel.codeLength,
                    hasError: model.error != nil,
                    focusesOnAppear: true
                )

                errorMessage

                ResendCodeButton(
                    countdownStart: model.resendCountdownStart,
                    remainingSeconds: model.remainingResendSeconds(at:)
                ) {
                    if model.resend() {
                        onResend()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.lg)
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("verification.body", bundle: .onsarj)
                .font(Typography.secondary)
                .foregroundStyle(Theme.textSecondary)

            Text(verbatim: model.phoneNumber)
                .font(Typography.bodyStrong)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
    }

    /// Hata yokken de yerini korur (saydam); mesaj görünüp kaybolurken alttaki içerik kaymaz.
    private var errorMessage: some View {
        Text(verbatim: (model.error ?? .invalidCode).message)
            .font(Typography.caption)
            .foregroundStyle(Theme.textError)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(model.error == nil ? 0 : 1)
            .accessibilityHidden(model.error == nil)
    }

    /// Klavyenin üstünde kalır: `safeAreaInset` klavye açıldığında yukarı taşınır.
    private var continueButton: some View {
        PrimaryButton("verification.action.continue", bundle: .onsarj) {
            model.submit()
        }
        .disabled(!model.canSubmit)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.sm)
        .background(Theme.backgroundPrimary)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi (iPhone SE ve Pro Max × Large ve xxxLarge);
/// boş, kısmen dolu, dolu ve hatalı durumlar; ayrıca her durumun koyu tema görünümü.
struct VerificationCodeViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private struct PreviewState {
        let name: String
        let code: String
        var error: VerificationCodeError?
    }

    private static let states = [
        PreviewState(name: "boş", code: ""),
        PreviewState(name: "kısmen dolu", code: "123"),
        PreviewState(name: "dolu", code: "123456"),
        PreviewState(name: "hatalı", code: "123456", error: .invalidCode),
    ]

    static var previews: some View {
        ForEach(states, id: \.name) { state in
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    screen(state)
                        .dynamicTypeSize(typeSize)
                        .previewDevice(PreviewDevice(rawValue: device))
                        .previewDisplayName("\(device) · \(typeSize) · \(state.name)")
                }
            }

            screen(state)
                .preferredColorScheme(.dark)
                .previewDevice(PreviewDevice(rawValue: devices[1]))
                .previewDisplayName("\(devices[1]) · koyu · \(state.name)")
        }
    }

    @MainActor
    private static func screen(_ state: PreviewState) -> some View {
        NavigationStack {
            VerificationCodeView(
                model: VerificationCodeModel(
                    phoneNumber: "+90 553 735 93 94",
                    resendInterval: 60,
                    code: state.code,
                    error: state.error,
                    onSubmit: { _ in }
                ),
                onBack: {},
                onResend: {}
            )
        }
    }
}
#endif
