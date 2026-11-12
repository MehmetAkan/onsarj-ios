import DesignSystem
import Localization
import SwiftUI

/// Ana haritanın alt sayfası: `DetentSheet` (K-22) ve ana sayfanın içeriği.
///
/// Başlıkta arama satırı durur; küçük kademede yalnızca o görünür. İçerik yukarıdan aşağıya:
/// kategori şeridi, alt butonlar. Kullanıcı sayfayı küçük ve orta kademe arasında sürükler;
/// büyük kademeye yalnızca aramaya dokunarak gidilir. Sayfa mekaniği (kademeler, sürükleme,
/// erişilebilirlik) `DetentSheet`'tedir.
///
/// Hiçbir öğe ekran açmaz; kullanıcının isteği `actions` ile dışarı bildirilir.
struct HomeBottomSheet<Accessory: View>: View {
    @Binding var detent: SheetDetent
    let actions: HomeSheetActions
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        DetentSheet(
            detent: $detent,
            draggableDetents: [.collapsed, .medium],
            accessibilityLabel: Text("home.sheet.accessibility.label", bundle: .onsarj),
            accessibilityValue: Self.accessibilityValue
        ) {
            MapSearchBar(onSearch: actions.search, onAssistant: actions.assistant)
                .padding(.horizontal, Spacing.screenMargin)
        } content: {
            VStack(spacing: Spacing.lg) {
                CategoryChipStrip(onSelect: actions.category)
                HomeBottomActions(onOptions: actions.options, onSavedPlans: actions.savedPlans)
                    .padding(.horizontal, Spacing.screenMargin)
            }
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
