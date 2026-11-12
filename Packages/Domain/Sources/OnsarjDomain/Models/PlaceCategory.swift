/// Kullanıcının haritada aradığı yer türü: restoran, kafe, cami gibi.
///
/// Ham değer (`id`) kararlıdır; analitik olaylarında ve API isteklerinde bu değer gider.
/// Bir durumun ham değeri **değiştirilmez**, yeni tür eklenirse yeni durum açılır.
///
/// `allCases` sırası ana sayfadaki kategori şeridinin sırasıdır.
public enum PlaceCategory: String, CaseIterable, Hashable, Sendable, Identifiable {
    case restaurant
    case cafe
    case mosque
    case market
    case pharmacy
    case atm
    case hotel

    /// Kararlı tanımlayıcı; analitikte ve API'de kullanılır.
    public var id: String { rawValue }
}
