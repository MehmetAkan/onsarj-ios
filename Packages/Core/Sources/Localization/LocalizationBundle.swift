import Foundation

extension Bundle {

    /// Uygulamanın String Catalog'unu (`Localizable.xcstrings`) taşıyan paket.
    ///
    /// Kullanıcıya görünen metinler tek bir katalogda toplanır. Özellik modülleri
    /// metne bu paket üzerinden erişir:
    ///
    /// ```swift
    /// Text("welcome.action.continue", bundle: .onsarj)
    /// ```
    public static let onsarj = Bundle.module
}
