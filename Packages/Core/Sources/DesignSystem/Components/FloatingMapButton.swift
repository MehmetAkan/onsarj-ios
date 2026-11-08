import SwiftUI

/// Harita üzerinde yüzen dairesel buton.
///
/// Yükseltilmiş yüzey (`Theme.backgroundElevated`) ve gölgesiyle (`Theme.shadowFloating`)
/// haritadan ayrılır; simge `Theme.textPrimary` rengindedir. Dokunma alanı
/// `Spacing.minTapTarget`'tır.
///
/// Simge yalnızca görsel olduğu için VoiceOver etiketi zorunludur.
///
/// ```swift
/// FloatingMapButton(
///     systemImage: "bolt.fill",
///     accessibilityLabel: "home.accessibility.nearbyChargers",
///     bundle: .onsarj,
///     action: onNearbyChargers
/// )
/// ```
public struct FloatingMapButton: View {
    private let systemImage: String
    private let accessibilityLabel: LocalizedStringKey
    private let bundle: Bundle?
    private let action: () -> Void

    /// - Parameters:
    ///   - systemImage: SF Symbols simge adı.
    ///   - accessibilityLabel: VoiceOver etiketinin String Catalog anahtarı.
    ///   - bundle: Metnin bulunduğu paket; özellik modülleri `.onsarj` verir.
    ///   - action: Dokunulduğunda çağrılır.
    public init(
        systemImage: String,
        accessibilityLabel: LocalizedStringKey,
        bundle: Bundle? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.bundle = bundle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Typography.button)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                .background(Theme.backgroundElevated, in: Circle())
                // Gölgenin yayılımı ve aşağı kayması boşluk ölçeğinden alınır; ayrı bir gölge
                // ölçeği tanımlanana kadar tek kaynak budur.
                .shadow(color: Theme.shadowFloating, radius: Spacing.sm, y: Spacing.xs)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel, bundle: bundle))
    }
}

#if DEBUG
#Preview("FloatingMapButton · açık") {
    FloatingMapButton(systemImage: "bolt.fill", accessibilityLabel: "Preview", action: {})
        .padding(Spacing.xl)
        .background(Theme.backgroundSubtle)
        .preferredColorScheme(.light)
}

#Preview("FloatingMapButton · koyu") {
    FloatingMapButton(systemImage: "bolt.fill", accessibilityLabel: "Preview", action: {})
        .padding(Spacing.xl)
        .background(Theme.backgroundSubtle)
        .preferredColorScheme(.dark)
}
#endif
