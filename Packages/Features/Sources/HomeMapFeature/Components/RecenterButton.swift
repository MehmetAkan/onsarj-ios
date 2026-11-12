import DesignSystem
import Localization
import SwiftUI

/// "Konumuma dön" butonu.
///
/// Kamera kullanıcıyı izlerken simge dolu, izlemiyorken boştur; Apple Haritalar'daki
/// alışkanlıkla aynı.
struct RecenterButton: View {
    let isFollowingUser: Bool
    let action: () -> Void

    var body: some View {
        FloatingMapButton(
            systemImage: isFollowingUser ? "location.fill" : "location",
            accessibilityLabel: "home.map.accessibility.recenter",
            bundle: .onsarj,
            action: action
        )
    }
}
