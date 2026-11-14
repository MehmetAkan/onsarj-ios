/// Aracın şarj soketi türü.
///
/// Ham değer backend sözleşmesindeki dizgedir ve **değiştirilmez**; yeni tür eklenirse yeni
/// durum açılır.
public enum ConnectorType: String, Sendable, CaseIterable {
    case type1
    case type2
    case ccs1
    case ccs2
    case chademo
    case nacs
}
