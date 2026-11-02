import DesignSystem
import Localization
import SwiftUI

/// "Konumuma dön" butonu: harita üzerinde yuvarlak, yükseltilmiş yüzey.
///
/// Kamera kullanıcıyı izlerken simge dolu, izlemiyorken boştur; Apple Haritalar'daki
/// alışkanlıkla aynı.
struct RecenterButton: View {
    let isFollowingUser: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFollowingUser ? "location.fill" : "location")
                .font(Typography.button)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                .background(Theme.backgroundElevated, in: Circle())
                .overlay(Circle().strokeBorder(Theme.borderSubtle))
                .contentShape(Circle())
        }
        .accessibilityLabel(Text("home.map.accessibility.recenter", bundle: .onsarj))
    }
}
