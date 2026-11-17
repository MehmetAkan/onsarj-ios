import SwiftUI

/// Birincil buton: tam genişlik, dolgulu, basılıyken koyulaşan.
///
/// Etkin/devre dışı durumu SwiftUI'ın standart `.disabled(_:)` değiştiricisiyle verilir.
/// Devre dışıyken buton gizlenmez, yalnızca vurgusu düşer (`Theme.actionPrimaryDisabled`
/// zemin, `Theme.onActionPrimaryDisabled` metin).
///
/// Metnin solunda isteğe bağlı bir simge durabilir (`icon`).
///
/// ```swift
/// PrimaryButton("signup.phone.action.continue", bundle: .onsarj, action: submit)
///     .disabled(!model.isValid)
/// PrimaryButton("stationDetail.directions", icon: .directions, bundle: .onsarj, action: directions)
/// ```
public struct PrimaryButton: View {
    private let titleKey: LocalizedStringKey
    private let icon: AppIcon?
    private let bundle: Bundle?
    private let action: () -> Void

    /// - Parameters:
    ///   - titleKey: Buton metninin String Catalog anahtarı.
    ///   - icon: Metnin solundaki simge; `nil` ise yalnızca metin.
    ///   - bundle: Metnin bulunduğu paket; özellik modülleri `.onsarj` verir.
    ///   - action: Dokunulduğunda çağrılır.
    public init(
        _ titleKey: LocalizedStringKey,
        icon: AppIcon? = nil,
        bundle: Bundle? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.icon = icon
        self.bundle = bundle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            if let icon {
                Label(title: { Text(titleKey, bundle: bundle) }, icon: { icon })
            } else {
                Text(titleKey, bundle: bundle)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    /// Butonun en küçük yüksekliği; cihazda ayarlandı. Yazı büyüdükçe buton da uzar.
    /// `Spacing.minTapTarget` değerinin üzerindedir, dokunma alanı sınırı kendiliğinden sağlanır.
    private static let minHeight: CGFloat = max(58, Spacing.minTapTarget)

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.button)
            .foregroundStyle(isEnabled ? Theme.onActionPrimary : Theme.onActionPrimaryDisabled)
            .multilineTextAlignment(.center)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: Self.minHeight)
            .background(background(isPressed: configuration.isPressed), in: shape)
            .contentShape(shape)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.button)
    }

    private func background(isPressed: Bool) -> Color {
        if !isEnabled {
            return Theme.actionPrimaryDisabled
        }
        return isPressed ? Theme.actionPrimaryPressed : Theme.actionPrimary
    }
}
