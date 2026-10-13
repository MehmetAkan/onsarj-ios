import SwiftUI

/// Birincil buton: tam genişlik, dolgulu, basılıyken koyulaşan.
///
/// Etkin/devre dışı durumu SwiftUI'ın standart `.disabled(_:)` değiştiricisiyle verilir.
/// Devre dışıyken buton gizlenmez, yalnızca vurgusu düşer (`Theme.actionPrimaryDisabled`).
///
/// ```swift
/// PrimaryButton("signup.phone.action.continue", bundle: .onsarj, action: submit)
///     .disabled(!model.isValid)
/// ```
public struct PrimaryButton: View {
    private let titleKey: LocalizedStringKey
    private let bundle: Bundle?
    private let action: () -> Void

    /// - Parameters:
    ///   - titleKey: Buton metninin String Catalog anahtarı.
    ///   - bundle: Metnin bulunduğu paket; özellik modülleri `.onsarj` verir.
    ///   - action: Dokunulduğunda çağrılır.
    public init(_ titleKey: LocalizedStringKey, bundle: Bundle? = nil, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.bundle = bundle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(titleKey, bundle: bundle)
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
            .foregroundStyle(Theme.onActionPrimary)
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
