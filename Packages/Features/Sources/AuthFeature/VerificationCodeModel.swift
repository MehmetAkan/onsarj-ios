import Foundation
import Observation

/// SMS kodu ekranının durumu: girilen kod, gönderim, hata ve tekrar gönderme süresi.
@MainActor
@Observable
final class VerificationCodeModel {
    /// Doğrulamayı yapan kapanış. Kod yanlışsa `VerificationCodeError` fırlatır.
    typealias SubmitHandler = @MainActor (_ code: String) async throws(VerificationCodeError) -> Void

    /// SMS kodunun hane sayısı.
    static let codeLength = 6

    /// Kodun gönderildiği numara, ekrandaki biçimiyle: `"+90 553 735 93 94"`.
    let phoneNumber: String

    /// Girilen kod; yalnızca rakam, en fazla `codeLength` hane.
    private(set) var code: String

    /// Son gönderimin hatası. Yeni bir rakam yazıldığında temizlenir.
    private(set) var error: VerificationCodeError?

    /// Süren gönderim. Varken ikinci bir gönderim başlatılmaz.
    private(set) var submission: Task<Void, Never>?

    /// Geri sayımın son başladığı an.
    private(set) var resendCountdownStart: Date

    /// Tekrar gönderme için beklenecek süre, saniye.
    @ObservationIgnored let resendInterval: TimeInterval

    @ObservationIgnored private let onSubmit: SubmitHandler

    /// - Parameters:
    ///   - phoneNumber: Kodun gönderildiği numara, ekrandaki biçimiyle.
    ///   - resendInterval: Tekrar gönderme için beklenecek süre, saniye.
    ///   - startedAt: Geri sayımın başladığı an; ekranın açıldığı an.
    ///   - code: Başlangıç kodu.
    ///   - error: Başlangıç hatası.
    ///   - onSubmit: Doğrulamayı yapan kapanış.
    init(
        phoneNumber: String,
        resendInterval: TimeInterval,
        startedAt: Date = .now,
        code: String = "",
        error: VerificationCodeError? = nil,
        onSubmit: @escaping SubmitHandler
    ) {
        self.phoneNumber = phoneNumber
        self.resendInterval = resendInterval
        self.resendCountdownStart = startedAt
        self.code = Self.sanitized(code)
        self.error = error
        self.onSubmit = onSubmit
    }

    var isComplete: Bool {
        code.count == Self.codeLength
    }

    var isSubmitting: Bool {
        submission != nil
    }

    /// "Devam" butonu: kod tamken ve gönderim sürmüyorken etkin.
    var canSubmit: Bool {
        isComplete && !isSubmitting
    }

    // MARK: - Kod girişi

    /// Alandaki metni süzer ve kodu günceller.
    ///
    /// Rakam dışı karakterler atılır, fazla haneler kesilir. Yeni bir rakam eklendiyse
    /// önceki hata temizlenir. Kod tamamlandığında kendiliğinden gönderilir.
    func updateCode(_ input: String) {
        let digits = Self.sanitized(input)
        guard digits != code else { return }
        if digits.count > code.count {
            error = nil
        }
        code = digits
        if isComplete {
            submit()
        }
    }

    /// Kodu gönderir. Kod eksikse ya da bir gönderim sürüyorsa hiçbir şey yapmaz;
    /// otomatik gönderim ile butonun aynı anda tetiklenmesi böyle engellenir.
    func submit() {
        guard canSubmit else { return }
        let code = code
        submission = Task {
            await perform(code)
        }
    }

    private func perform(_ code: String) async {
        defer { submission = nil }
        do {
            try await onSubmit(code)
        } catch {
            self.error = error
        }
    }

    private static func sanitized(_ input: String) -> String {
        String(input.filter { $0.isASCII && $0.isNumber }.prefix(codeLength))
    }

    // MARK: - Tekrar gönderme

    /// Tekrar göndermenin mümkün olacağı an.
    ///
    /// Geri sayım sayaç azaltarak değil bu andan hesaplanır; uygulama arka plandayken
    /// geçen süre de böylece sayılır.
    var resendAvailableAt: Date {
        resendCountdownStart.addingTimeInterval(resendInterval)
    }

    /// Verilen anda tekrar göndermeye kalan tam saniye, yukarı yuvarlanmış. Süre dolduysa 0.
    func remainingResendSeconds(at date: Date) -> Int {
        let remaining = resendAvailableAt.timeIntervalSince(date)
        return remaining > 0 ? Int(remaining.rounded(.up)) : 0
    }

    /// Süre dolduysa geri sayımı yeniden başlatır ve `true` döner; dolmadıysa `false`.
    func resend(at date: Date = .now) -> Bool {
        guard remainingResendSeconds(at: date) == 0 else { return false }
        resendCountdownStart = date
        return true
    }
}
