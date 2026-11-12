import DesignSystem
import OnsarjDomain
import SwiftUI

/// Kategorinin ana sayfadaki görünümü: simgesi ve etiketi.
///
/// Domain simge ve metin bilmez; eşleme burada yapılır.
extension PlaceCategory {
    var icon: AppIcon {
        switch self {
        case .restaurant: .categoryRestaurant
        case .cafe: .categoryCafe
        case .mosque: .categoryMosque
        case .market: .categoryMarket
        case .pharmacy: .categoryPharmacy
        case .atm: .categoryATM
        case .hotel: .categoryHotel
        }
    }

    /// Etiketin String Catalog anahtarı.
    var titleKey: LocalizedStringKey {
        switch self {
        case .restaurant: "category.restaurant"
        case .cafe: "category.cafe"
        case .mosque: "category.mosque"
        case .market: "category.market"
        case .pharmacy: "category.pharmacy"
        case .atm: "category.atm"
        case .hotel: "category.hotel"
        }
    }
}
