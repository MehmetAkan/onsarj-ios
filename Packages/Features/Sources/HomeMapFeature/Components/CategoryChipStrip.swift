import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Ana sayfadaki yatay kayan kategori şeridi.
///
/// Şerit ekranın iki kenarına dayanır; ilk çipin solundaki `Spacing.screenMargin` boşluk
/// içeriğin parçasıdır, bu yüzden çipler kayarken kenara kadar gider ve sağ kenarda kesilen çip
/// şeridin kaydırılabildiğini gösterir.
///
/// Yatay sürükleme şeridi kaydırır; dikey sürükleme alt sayfaya kalır (`DetentSheet` yatay
/// başlayan sürüklemeyi yok sayar).
struct CategoryChipStrip: View {
    let onSelect: (PlaceCategory) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.sm) {
                ForEach(PlaceCategory.allCases) { category in
                    CategoryChip(category.titleKey, icon: category.icon, bundle: .onsarj) {
                        onSelect(category)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
    }
}
