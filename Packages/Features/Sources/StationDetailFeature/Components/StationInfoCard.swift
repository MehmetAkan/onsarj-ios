import DesignSystem
import OnsarjDomain
import SwiftUI

/// Bilgi kartı: çalışma durumu, erişim rozeti, son başarılı şarj ve kopyalanabilen adres.
struct StationInfoCard: View {
    let detail: StationDetail
    let now: Date
    let isAddressCopied: Bool
    let onCopyAddress: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        DetailCard {
            openingStatus
            accessBadge
            if let lastCharge = detail.lastSuccessfulChargeAt {
                Label {
                    Text(
                        StationDetailText.format(
                            "stationDetail.lastCharge", StationDetailText.relative(lastCharge, now: now, locale: locale)
                        ))
                } icon: {
                    AppIcon.time
                }
                .foregroundStyle(Theme.textPrimary)
            }
            address
        }
        .font(Typography.body)
    }

    private var openingStatus: some View {
        let status = detail.openingHours.status(at: now)
        return Text(StationDetailText.openingStatus(status, in: detail.openingHours, now: now, locale: locale))
            .font(Typography.bodyStrong)
            .foregroundStyle(status.isOpen ? Theme.availabilityAvailable : Theme.availabilityUnavailable)
    }

    @ViewBuilder
    private var accessBadge: some View {
        switch detail.access {
        case .public:
            badge(
                Text(StationDetailText.localized("stationDetail.access.public")), icon: .checkmark,
                background: Theme.positiveSubtle, foreground: Theme.onPositiveSubtle)
        case .restricted(let note):
            badge(
                Text(verbatim: note), icon: .warning, background: Theme.cautionSubtle,
                foreground: Theme.onCautionSubtle
            )
            .accessibilityLabel(StationDetailText.format("stationDetail.access.restricted", note))
        }
    }

    private func badge(_ text: Text, icon: AppIcon, background: Color, foreground: Color) -> some View {
        Label(title: { text }, icon: { icon })
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.field))
    }

    private var address: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Label(title: { Text(verbatim: detail.address) }, icon: { AppIcon.address })
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
            Spacer(minLength: Spacing.sm)
            if isAddressCopied {
                Label {
                    Text(StationDetailText.localized("stationDetail.addressCopied"))
                } icon: {
                    AppIcon.checkmark
                }
                .font(Typography.caption)
                .foregroundStyle(Theme.availabilityAvailable)
                .transition(.opacity)
            } else {
                Button(action: onCopyAddress) {
                    AppIcon.copy
                        .foregroundStyle(Theme.brandPrimary)
                        .frame(minWidth: Spacing.minTapTarget, minHeight: Spacing.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(StationDetailText.localized("stationDetail.copyAddress"))
            }
        }
        .animation(.default, value: isAddressCopied)
    }
}
