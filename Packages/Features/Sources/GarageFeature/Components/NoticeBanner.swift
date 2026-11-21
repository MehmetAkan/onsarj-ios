import DesignSystem
import Foundation
import Localization
import SwiftUI

/// Garaj ekranlarının altında kısa süre görünen bildirim. Her bildirimin kimliği yenidir; aynı bildirim
/// art arda da gösterilir.
struct GarageNotice: Equatable, Identifiable {
    enum Kind: Equatable {
        /// Yazma başarısız; ekrandaki değer eski haline döndü.
        case saveFailed
        /// Son konnektör kaldırılmak istendi.
        case connectorRequired
        /// Katalogdan araç eklenemedi.
        case addFailed
    }

    let id = UUID()
    let kind: Kind
}

/// Ekranın altında kısa süre görünen bildirim ("Değişiklik kaydedilemedi" gibi).
///
/// Birkaç saniye sonra kendiliğinden kaybolur; VoiceOver metni duyurur.
struct NoticeBanner: View {
    let notice: GarageNotice
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
        case .saveFailed: "common.saveFailed"
        case .connectorRequired: "vehicleSettings.connectorRequired"
        case .addFailed: "garage.addFailed"
        }
    }
}
