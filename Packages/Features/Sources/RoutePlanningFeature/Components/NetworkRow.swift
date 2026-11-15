import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Şarj ağları sayfasındaki satır: ad ve kaldır düğmesi.
///
/// Adı çözülemeyen ağ "Bilinmeyen ağ" olarak gösterilir ve kaldırılabilir.
struct NetworkRow: View {
    let name: String?
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            nameText
                .font(Typography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.md)
            removeButton
        }
        .padding(.leading, Spacing.lg)
        .padding(.trailing, Spacing.xs)
    }

    private var nameText: Text {
        if let name {
            Text(verbatim: name).foregroundStyle(Theme.textPrimary)
        } else {
            Text("networks.unknown", bundle: .onsarj).foregroundStyle(Theme.textSecondary)
        }
    }

    private var removeButton: some View {
        Button(action: onRemove) {
            AppIcon.remove
                .font(Typography.buttonSmall)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: removeLabel))
    }

    private var removeLabel: String {
        let displayName = name ?? String(localized: "networks.unknown", bundle: .onsarj)
        return PlanText.format(String(localized: "networks.accessibility.remove", bundle: .onsarj), displayName)
    }
}
