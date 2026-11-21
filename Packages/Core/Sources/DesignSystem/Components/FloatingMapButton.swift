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
///     icon: .charger,
///     accessibilityLabel: "home.accessibility.nearbyChargers",
///     bundle: .onsarj,
///     action: onNearbyChargers
/// )
/// ```
public struct FloatingMapButton: View {
    private let icon: AppIcon
    private let accessibilityLabel: LocalizedStringKey
    private let bundle: Bundle?
    private let action: () -> Void

    /// - Parameters:
    ///   - icon: Simge (CLAUDE.md 6.9).
    ///   - accessibilityLabel: VoiceOver etiketinin String Catalog anahtarı.
    ///   - bundle: Metnin bulunduğu paket; özellik modülleri `.onsarj` verir.
    ///   - action: Dokunulduğunda çağrılır.
    public init(
        icon: AppIcon,
        accessibilityLabel: LocalizedStringKey,
        bundle: Bundle? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.bundle = bundle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            icon.floatingMapButtonSurface()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel, bundle: bundle))
    }
}

extension View {
    /// `FloatingMapButton`'ın görünümü: yükseltilmiş yüzeyde dairesel simge, `Spacing.minTapTarget` dokunma
    /// alanı. Kendi düğmesini çizen sistem bileşenleri (ör. `ShareLink`) aynı görünümü bununla alır:
    ///
    /// ```swift
    /// ShareLink(item: text) { AppIcon.share.floatingMapButtonSurface() }
    ///     .buttonStyle(.plain)
    /// ```
    public func floatingMapButtonSurface() -> some View {
        font(Typography.button)
            .foregroundStyle(Theme.textPrimary)
            .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
            .background(Theme.backgroundElevated, in: Circle())
            // Gölgenin yayılımı ve aşağı kayması boşluk ölçeğinden alınır; ayrı bir gölge
            // ölçeği tanımlanana kadar tek kaynak budur.
            .shadow(color: Theme.shadowFloating, radius: Spacing.sm, y: Spacing.xs)
            .contentShape(Circle())
    }
}

#if DEBUG
#Preview("FloatingMapButton · açık") {
    FloatingMapButton(icon: .charger, accessibilityLabel: "Preview", action: {})
        .padding(Spacing.xl)
        .background(Theme.backgroundSubtle)
        .preferredColorScheme(.light)
}

#Preview("FloatingMapButton · koyu") {
    FloatingMapButton(icon: .charger, accessibilityLabel: "Preview", action: {})
        .padding(Spacing.xl)
        .background(Theme.backgroundSubtle)
        .preferredColorScheme(.dark)
}
#endif
