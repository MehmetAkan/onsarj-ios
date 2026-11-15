import DesignSystem
import SwiftUI

/// Ayarlar kutusundaki satır: solda etiket, sağda değer ve (dokunulabilirse) ok.
///
/// Büyük yazıda değer etiketin altına iner; taşmaz.
struct SettingsRow: View {
    let label: Text
    let value: Text
    /// `nil`: salt okunur satır, ok yok.
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) {
                content(showsChevron: true)
            }
            .buttonStyle(.plain)
        } else {
            content(showsChevron: false)
                .accessibilityElement(children: .combine)
        }
    }

    private func content(showsChevron: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.sm) {
                    label.foregroundStyle(Theme.textPrimary)
                    Spacer(minLength: Spacing.sm)
                    value.foregroundStyle(Theme.textSecondary).lineLimit(1)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    label.foregroundStyle(Theme.textPrimary)
                    value.foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if showsChevron {
                AppIcon.disclosure
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .font(Typography.body)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(minHeight: Spacing.minTapTarget)
        .contentShape(Rectangle())
    }
}

/// Bölüm: başlık (ve isteğe bağlı sağ düğme) ile kart zeminli içerik.
struct SettingsSection<Content: View, Accessory: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let accessory: () -> Accessory
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(title, bundle: .onsarj)
                    .font(Typography.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.sm)
                accessory()
            }
            VStack(spacing: 0) {
                content()
            }
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
        }
    }
}

extension SettingsSection where Accessory == EmptyView {
    init(title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, accessory: { EmptyView() }, content: content)
    }
}
