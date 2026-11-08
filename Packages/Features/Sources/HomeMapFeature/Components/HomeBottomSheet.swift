import DesignSystem
import Localization
import SwiftUI

/// Ana haritanın alt sayfası: `DetentSheet` (K-22) ve ana sayfanın içeriği.
///
/// Başlıkta arama çubuğu durur; küçük kademede yalnızca o görünür. Kullanıcı sayfayı küçük ve
/// orta kademe arasında sürükler; büyük kademeye yalnızca aramaya dokunarak gidilir. Sayfa
/// mekaniği (kademeler, sürükleme, erişilebilirlik) `DetentSheet`'tedir.
struct HomeBottomSheet<Accessory: View>: View {
    @Binding var detent: SheetDetent
    let onSearch: () -> Void
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        DetentSheet(
            detent: $detent,
            draggableDetents: [.collapsed, .medium],
            accessibilityLabel: Text("home.sheet.accessibility.label", bundle: .onsarj),
            accessibilityValue: Self.accessibilityValue
        ) {
            MapSearchBar(action: onSearch)
                .padding(.horizontal, Spacing.screenMargin)
        } content: {
            EmptyView()
        } accessory: {
            accessory()
        }
    }

    private static func accessibilityValue(for detent: SheetDetent) -> Text {
        switch detent {
        case .collapsed: Text("home.sheet.accessibility.collapsed", bundle: .onsarj)
        case .medium: Text("home.sheet.accessibility.medium", bundle: .onsarj)
        case .expanded: Text("home.sheet.accessibility.expanded", bundle: .onsarj)
        }
    }
}
