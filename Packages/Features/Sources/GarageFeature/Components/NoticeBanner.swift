import DesignSystem
import Localization
import SwiftUI

/// Ekranın altında kısa süre görünen bildirim ("Değişiklik kaydedilemedi" gibi).
///
/// Birkaç saniye sonra kendiliğinden kaybolur; VoiceOver metni duyurur.
struct NoticeBanner: View {
    let notice: VehicleSettingsModel.Notice
    let onDismiss: () -> Void

    private static let visibleDuration = Duration.seconds(3)

    var body: some View {
        Text(verbatim: GarageText.localized(messageKey))
            .font(Typography.secondary)
            .foregroundStyle(Theme.onActionPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Theme.actionPrimary, in: Capsule())
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.lg)
            .task(id: notice.id) {
                AccessibilityNotification.Announcement(GarageText.localized(messageKey)).post()
                try? await Task.sleep(for: Self.visibleDuration)
                if !Task.isCancelled { onDismiss() }
            }
    }

    private var messageKey: String {
        switch notice.kind {
        case .saveFailed: "vehicleSettings.saveFailed"
        case .connectorRequired: "vehicleSettings.connectorRequired"
        }
    }
}
