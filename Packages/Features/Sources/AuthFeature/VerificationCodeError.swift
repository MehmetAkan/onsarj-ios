import Foundation
import Localization

/// SMS kodu doğrulamasında kullanıcıya gösterilebilecek hatalar.
///
/// Ekrana ham ağ hatası taşınmaz (CLAUDE.md 6.3); doğrulamayı yapan katman sonucu bu
/// tipe çevirir ve `VerificationCodeView`'ın gönderim kapanışından fırlatır.
public enum VerificationCodeError: Error, Equatable, Sendable {
    /// Girilen kod doğru değil.
    case invalidCode

    /// Kullanıcıya gösterilen mesaj: ne olduğunu ve ne yapılabileceğini söyler.
    var message: String {
        switch self {
        case .invalidCode:
            String(localized: "verification.error.invalidCode", bundle: .onsarj)
        }
    }
}
