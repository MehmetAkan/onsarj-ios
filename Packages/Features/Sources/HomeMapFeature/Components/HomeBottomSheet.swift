import DesignSystem
import Localization
import SwiftUI

/// Ana haritanın alt sayfası: `DetentSheet` (K-22) ve ana sayfanın içeriği.
///
/// Başlıkta arama satırı durur; küçük kademede yalnızca o görünür. İçerik yukarıdan aşağıya:
/// kategori şeridi, araç kartı, alt butonlar. Kullanıcı sayfayı küçük ve orta kademe arasında sürükler
/// (K-25); aramaya dokunmak sayfayı büyütmez, arama ayrı bir ekranda açılır. Sayfa mekaniği
/// (kademeler, sürükleme, erişilebilirlik) `DetentSheet`'tedir.
///
/// Hiçbir öğe ekran açmaz; kullanıcının isteği `actions` ile dışarı bildirilir.
struct HomeBottomSheet<Accessory: View>: View {
    @Binding var detent: SheetDetent
    let actions: HomeSheetActions
    let vehicleCard: VehicleCardModel
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        DetentSheet(
            detent: $detent,
            accessibilityLabel: Text("home.sheet.accessibility.label", bundle: .onsarj),
            accessibilityValue: Self.accessibilityValue
        ) {
            MapSearchBar(onSearch: actions.search, onAssistant: actions.assistant)
                .padding(.horizontal, Spacing.screenMargin)
        } content: {
            VStack(spacing: Spacing.lg) {
                CategoryChipStrip(onSelect: actions.category)
                VStack(spacing: Spacing.sm) {
                    VehicleCard(
                        model: vehicleCard,
                        onSwitchVehicle: actions.switchVehicle,
                        onVehicleSettings: actions.vehicleSettings,
                        onAddVehicle: actions.addVehicle
                    )
                    HomeBottomActions(onOptions: actions.options, onSavedPlans: actions.savedPlans)
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.bottom, Spacing.md)
            }
        } accessory: {
            accessory()
        }
    }

    private static func accessibilityValue(for detent: SheetDetent) -> Text {
        switch detent {
        case .collapsed: Text("home.sheet.accessibility.collapsed", bundle: .onsarj)
        case .medium: Text("home.sheet.accessibility.medium", bundle: .onsarj)
        }
    }
}
