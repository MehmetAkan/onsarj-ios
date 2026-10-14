import SwiftUI

/// Ekran üst çubuğu: solda geri oku, ortada başlık.
///
/// Sistem gezinme çubuğu yerine kullanılır; ekran `.toolbar(.hidden, for: .navigationBar)`
/// ile çubuğu gizler ve bu bileşeni üst kenara yerleştirir. Böylece geri oku iOS sürümünden
/// bağımsız olarak aynı görünür: çerçevesiz, arka plansız, yalnızca ok.
///
/// ```swift
/// content
///     .safeAreaInset(edge: .top) {
///         ScreenHeader("signup.phone.navTitle", backLabel: "signup.phone.accessibility.back",
///                      bundle: .onsarj, onBack: onBack)
///     }
///     .toolbar(.hidden, for: .navigationBar)
/// ```
public struct ScreenHeader: View {
    private let titleKey: LocalizedStringKey
    private let backLabelKey: LocalizedStringKey
    private let bundle: Bundle?
    private let onBack: () -> Void

    /// - Parameters:
    ///   - titleKey: Başlığın String Catalog anahtarı.
    ///   - backLabel: Geri okunun VoiceOver etiketinin anahtarı.
    ///   - bundle: Metinlerin bulunduğu paket; özellik modülleri `.onsarj` verir.
    ///   - onBack: Geri okuna dokunulduğunda çağrılır.
    public init(
        _ titleKey: LocalizedStringKey,
        backLabel: LocalizedStringKey,
        bundle: Bundle? = nil,
        onBack: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.backLabelKey = backLabel
        self.bundle = bundle
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            Text(titleKey, bundle: bundle)
                .font(Typography.headline)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                // Başlık ortada kalır ve iki yanda geri okuna yer bırakır.
                .padding(.horizontal, Spacing.minTapTarget)

            backButton
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: Spacing.minTapTarget)
        .padding(.horizontal, Spacing.screenMargin)
        .background(Theme.backgroundPrimary)
    }

    /// Ok görsel olarak küçüktür; dokunma alanı `Spacing.minTapTarget` karesidir. Ok bu karenin
    /// soluna yaslanır, böylece ekran içeriğiyle aynı kenar boşluğundan başlar.
    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(Typography.buttonSmall)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(backLabelKey, bundle: bundle))
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × Large ve xxxLarge.
struct ScreenHeaderPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]

    static var previews: some View {
        ForEach(devices, id: \.self) { device in
            ForEach(typeSizes, id: \.self) { typeSize in
                VStack {
                    ScreenHeader("Create an account", backLabel: "Go back", onBack: {})
                    Spacer()
                }
                .dynamicTypeSize(typeSize)
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName("\(device) · \(typeSize)")
            }
        }
    }
}
#endif
