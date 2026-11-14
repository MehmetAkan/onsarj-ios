/// Aracın kasa tipi.
///
/// Ham değer backend sözleşmesindeki dizgedir ve **değiştirilmez**. Tanınmayan değerler
/// `other` olarak eşlenir.
public enum BodyType: String, Sendable, CaseIterable {
    case hatchback
    case sedan
    case suv
    case crossover
    case wagon
    case coupe
    case van
    case pickup
    case other
}
