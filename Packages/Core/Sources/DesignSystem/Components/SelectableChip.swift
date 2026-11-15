import SwiftUI

/// Seçilebilir çip: seçiliyken dolgulu (`Theme.actionPrimary`), değilken sade kart zemini.
///
/// Çoklu seçimde (plan seçeneklerindeki kaçınma çipleri) ve tek seçimde (araç ayarlarındaki sürüş
/// profilleri) kullanılır. Görsel yüksekliği küçük olabilir; dokunma alanı en az
/// `Spacing.minTapTarget`'tır. VoiceOver seçili çipi "seçili" diye okur. Satıra sığmayan çip
/// `WrappingHStack` içinde alt satıra geçer.
public struct SelectableChip: View {
    private let title: Text
    private let icon: AppIcon?
    private let isSelected: Bool
    private let action: () -> Void

    /// - Parameters:
    ///   - title: Etiket.
    ///   - icon: Etiketin solundaki simge; yoksa yalnızca metin.
    ///   - isSelected: Seçili mi.
    ///   - action: Dokunulduğunda çağrılır.
    public init(_ title: Text, icon: AppIcon? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    icon
                }
                title
            }
            .font(Typography.secondary)
            .foregroundStyle(isSelected ? Theme.onActionPrimary : Theme.textPrimary)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(
                isSelected ? Theme.actionPrimary : Theme.backgroundCard,
                in: RoundedRectangle(cornerRadius: Radius.chip)
            )
            .frame(minHeight: Spacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("SelectableChip") {
    WrappingHStack(spacing: Spacing.sm) {
        SelectableChip(Text(verbatim: "Standard"), isSelected: true) {}
        SelectableChip(Text(verbatim: "Highway"), isSelected: false) {}
        SelectableChip(Text(verbatim: "Tolls"), icon: .avoidTolls, isSelected: false) {}
    }
    .padding(Spacing.screenMargin)
    .background(Theme.backgroundSheet)
}
#endif
