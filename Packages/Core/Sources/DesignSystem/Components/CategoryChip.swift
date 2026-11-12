import SwiftUI

/// Simge ve etiketten oluşan çip: ana sayfadaki kategori şeridi gibi.
///
/// Zemin `Theme.backgroundCard`, köşe `Radius.chip`, etiket `Typography.secondary` ve
/// `Theme.textSecondary`. Görsel yüksekliği küçük olabilir; dokunma alanı en az
/// `Spacing.minTapTarget`'tır. VoiceOver etiketi görünen metindir.
///
/// `DetentSheet` içinde, sayfa sürüklenirken dokunuşu tetiklemez.
///
/// ```swift
/// CategoryChip("category.cafe", icon: .categoryCafe, bundle: .onsarj) { select(.cafe) }
/// ```
public struct CategoryChip: View {
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
            HStack(spacing: Spacing.xs) {
                icon
                Text(titleKey, bundle: bundle)
                    .lineLimit(1)
            }
            .font(Typography.secondary)
            .foregroundStyle(Theme.textSecondary)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.chip))
            .frame(minHeight: Spacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func trigger() {
        guard !isSheetDragInProgress else { return }
        action()
    }
}

#if DEBUG
#Preview("CategoryChip") {
    HStack(spacing: Spacing.sm) {
        CategoryChip("Restaurants", icon: .categoryRestaurant, action: {})
        CategoryChip("Mosques", icon: .categoryMosque, action: {})
    }
    .padding(Spacing.xl)
    .background(Theme.backgroundSheet)
}
#endif
