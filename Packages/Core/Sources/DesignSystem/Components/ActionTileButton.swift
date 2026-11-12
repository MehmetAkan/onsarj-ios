import SwiftUI

/// Simge ve etiketi yatayda ortalayan, bulunduğu genişliği dolduran buton: ana sayfadaki
/// "Seçenekler" ve "Kayıtlı planlar" gibi.
///
/// Zemin `Theme.backgroundCard`, köşe `Radius.button`, etiket `Typography.buttonSmall` ve
/// `Theme.textPrimary`. Dokunma alanı en az `Spacing.minTapTarget`'tır; yazı büyüyünce etiket
/// alt satıra geçer ve buton uzar. Basılıyken soluklaşır. VoiceOver etiketi görünen metindir.
///
/// Yan yana dizilen butonların eşit yükseklikte kalması için dikey olarak genişleyebilir;
/// kapsayıcı `.fixedSize(horizontal: false, vertical: true)` ile en uzununa eşitler.
///
/// `DetentSheet` içinde, sayfa sürüklenirken dokunuşu tetiklemez.
public struct ActionTileButton: View {
    private let titleKey: LocalizedStringKey
    private let icon: AppIcon
    private let bundle: Bundle?
    private let action: () -> Void

    @Environment(\.isSheetDragInProgress) private var isSheetDragInProgress

    /// - Parameters:
    ///   - titleKey: Etiketin String Catalog anahtarı.
    ///   - icon: Etiketin solundaki simge.
    ///   - bundle: Metnin bulunduğu paket; özellik modülleri `.onsarj` verir.
    ///   - action: Dokunulduğunda çağrılır.
    public init(
        _ titleKey: LocalizedStringKey,
        icon: AppIcon,
        bundle: Bundle? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.icon = icon
        self.bundle = bundle
        self.action = action
    }

    public var body: some View {
        Button(action: trigger) {
            HStack(spacing: Spacing.sm) {
                icon
                Text(titleKey, bundle: bundle)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(ActionTileButtonStyle())
    }

    private func trigger() {
        guard !isSheetDragInProgress else { return }
        action()
    }
}

private struct ActionTileButtonStyle: ButtonStyle {
    /// Basılı durumdaki saydamlık. Zemin rengini değiştirmek yerine soluklaştırılır: bir basamak
    /// koyu zemin, sayfa zeminiyle (`backgroundSheet`) aynı tona düşüp butonu yok ederdi.
    private static let pressedOpacity = 0.6

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.button)
        return configuration.label
            .font(Typography.buttonSmall)
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget, maxHeight: .infinity)
            .background(Theme.backgroundCard, in: shape)
            .contentShape(shape)
            .opacity(configuration.isPressed ? Self.pressedOpacity : 1)
    }
}

#if DEBUG
#Preview("ActionTileButton") {
    HStack(spacing: Spacing.sm) {
        ActionTileButton("Options", icon: .options, action: {})
        ActionTileButton("Saved plans", icon: .savedPlans, action: {})
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding(Spacing.xl)
    .background(Theme.backgroundSheet)
}
#endif
