import DesignSystem
import Localization
import SwiftUI

/// Alt sayfanın altındaki iki eşit genişlikte buton: Seçenekler ve Kayıtlı planlar.
///
/// Yazı büyüyüp bir etiket alt satıra geçerse iki buton da en uzununun yüksekliğini alır.
struct HomeBottomActions: View {
    let onOptions: () -> Void
    let onSavedPlans: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ActionTileButton("home.action.options", icon: .options, bundle: .onsarj, action: onOptions)
            ActionTileButton("home.action.savedPlans", icon: .savedPlans, bundle: .onsarj, action: onSavedPlans)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
