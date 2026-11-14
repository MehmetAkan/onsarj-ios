import DesignSystem
import Localization
import SwiftUI

/// Arama sayfasındaki bir satır: solda türünün simgesi, yanında başlık.
///
/// Şarj istasyonunun simgesi dolu bir dairenin içindedir; diğer türlerin simgesi aynı genişlikte
/// bir sütunda durur, böylece başlıklar hizalı kalır. VoiceOver başlığı ve satır türünü okur.
struct SearchRowView: View {
    let row: SearchRow

    /// Simge sütununun genişliği; yazı boyutuyla büyür.
    @ScaledMetric(relativeTo: .body) private var iconColumn = Spacing.xxl

    var body: some View {
        HStack(spacing: Spacing.md) {
            icon
                .frame(width: iconColumn, height: iconColumn)
            Text(row.title)
                .font(Typography.body)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.sm)
        .frame(minHeight: Spacing.minTapTarget)
        .contentShape(Rectangle())
        // Ayırıcı satır içeriğinin sağ kenarında biter; iOS 18 varsayılan olarak ekran kenarına uzatır.
        .alignmentGuide(.listRowSeparatorTrailing) { dimensions in dimensions[.trailing] }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.title))
        .accessibilityValue(kindDescription)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder private var icon: some View {
        switch row.kind {
        case .place:
            AppIcon.place
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
        case .history:
            AppIcon.history
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
        case .charger:
            AppIcon.charger
                .font(Typography.secondary)
                .foregroundStyle(Theme.onActionPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.actionPrimary, in: Circle())
        }
    }

    private var kindDescription: Text {
        switch row.kind {
        case .place: Text("search.accessibility.kind.place", bundle: .onsarj)
        case .history: Text("search.accessibility.kind.history", bundle: .onsarj)
        case .charger: Text("search.accessibility.kind.charger", bundle: .onsarj)
        }
    }
}
