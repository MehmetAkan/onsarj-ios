import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Ağ seçici satırı: ad ve sağda küçük kapsül düğme. Satırın tamamı dokunulabilir.
///
/// - `prefer`: "Ekle" (sade çerçeve) / "Eklendi" (dolu, onay simgeli).
/// - `avoid`: "Kaçın" (kırmızı çerçeve ve metin) / "Kaçınılıyor" (onay simgeli).
/// - Diğer listedeki ağ pasiftir ve altında "Kaçınılıyor" / "Tercih ediliyor" yazar.
struct PickerRow: View {
    let network: ChargingNetwork
    let mode: NetworkPickerMode
    let status: NetworkPickerModel.RowStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: network.name)
                        .font(Typography.body)
                        .foregroundStyle(status == .inOtherList ? Theme.textDisabled : Theme.textPrimary)
                    if status == .inOtherList {
                        Text(otherListKey, bundle: .onsarj)
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if status != .inOtherList {
                    capsule
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: Spacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(status == .inOtherList)
        .accessibilityAddTraits(status == .added ? .isSelected : [])
    }

    private var otherListKey: LocalizedStringKey {
        mode == .prefer ? "networks.avoiding" : "networks.preferring"
    }

    private var capsuleKey: LocalizedStringKey {
        switch (mode, status == .added) {
        case (.prefer, false): "networks.add"
        case (.prefer, true): "networks.added"
        case (.avoid, false): "networks.avoid"
        case (.avoid, true): "networks.avoiding"
        }
    }

    private var capsule: some View {
        let isAdded = status == .added
        let filled = mode == .prefer && isAdded
        let foreground = mode == .avoid ? Theme.textError : (filled ? Theme.onActionPrimary : Theme.textPrimary)
        let border = mode == .avoid ? Theme.borderError : Theme.borderSubtle
        return HStack(spacing: Spacing.xs) {
            if isAdded {
                AppIcon.checkmark
            }
            Text(capsuleKey, bundle: .onsarj)
                .lineLimit(1)
        }
        .font(Typography.buttonSmall)
        .foregroundStyle(foreground)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(filled ? Theme.actionPrimary : Color.clear, in: Capsule())
        .overlay {
            if !filled {
                Capsule().strokeBorder(border)
            }
        }
        .fixedSize()
    }
}
