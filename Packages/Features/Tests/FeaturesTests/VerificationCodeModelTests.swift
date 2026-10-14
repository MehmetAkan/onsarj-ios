import Foundation
import Testing

@testable import AuthFeature

@MainActor
@Suite("VerificationCodeModel")
struct VerificationCodeModelTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    /// Gönderilen kodları kaydeder; istenirse hata fırlatır ya da serbest bırakılana kadar bekler.
    @MainActor
    private final class SubmitRecorder {
        var codes: [String] = []
        var error: VerificationCodeError?
        private var gate: CheckedContinuation<Void, Never>?
        var holdsSubmission = false

        func submit(_ code: String) async throws(VerificationCodeError) {
            codes.append(code)
            if holdsSubmission {
                await withCheckedContinuation { gate = $0 }
            }
            if let error {
                throw error
            }
        }

        func release() {
            gate?.resume()
            gate = nil
        }
    }

    private func makeModel(
        code: String = "",
        error: VerificationCodeError? = nil,
        recorder: SubmitRecorder = SubmitRecorder()
    ) -> VerificationCodeModel {
        VerificationCodeModel(
            phoneNumber: "+90 553 735 93 94",
            resendInterval: 60,
            startedAt: start,
            code: code,
            error: error,
            onSubmit: recorder.submit
        )
    }

    // MARK: - Geri sayım

    @Test("Kalan süre bitiş zamanından hesaplanır, arada geçen süre de sayılır")
    func countdownIsComputedFromDeadline() {
        let model = makeModel()

        #expect(model.remainingResendSeconds(at: start) == 60)
        #expect(model.remainingResendSeconds(at: start.addingTimeInterval(0.4)) == 60)
        #expect(model.remainingResendSeconds(at: start.addingTimeInterval(1)) == 59)
        // Uygulama 45 saniye arka planda kaldı.
        #expect(model.remainingResendSeconds(at: start.addingTimeInterval(45)) == 15)
        #expect(model.remainingResendSeconds(at: start.addingTimeInterval(60)) == 0)
        #expect(model.remainingResendSeconds(at: start.addingTimeInterval(600)) == 0)
    }

    @Test("Süre dolmadan tekrar gönderilmez; dolunca geri sayım yeniden başlar")
    func resendRestartsCountdownOnlyAfterDeadline() {
        let model = makeModel()

        #expect(model.resend(at: start.addingTimeInterval(59)) == false)
        #expect(model.resendCountdownStart == start)

        let later = start.addingTimeInterval(75)
        #expect(model.resend(at: later) == true)
        #expect(model.resendCountdownStart == later)
        #expect(model.remainingResendSeconds(at: later) == 60)
    }

    // MARK: - Kod girişi

    @Test("Rakam dışı karakterler atılır, en fazla 6 hane kalır")
    func inputIsSanitized() {
        let model = makeModel()

        model.updateCode("1a2-3 ")
        #expect(model.code == "123")

        model.updateCode("١٢٣")
        #expect(model.code.isEmpty)
    }

    @Test("Fazla haneler kesilir")
    func extraDigitsAreDropped() async {
        let recorder = SubmitRecorder()
        let model = makeModel(recorder: recorder)

        model.updateCode("12345678")
        await model.submission?.value

        #expect(model.code == "123456")
        #expect(recorder.codes == ["123456"])
    }

    @Test("6 hane dolduğunda kod kendiliğinden gönderilir")
    func completeCodeIsSubmittedAutomatically() async {
        let recorder = SubmitRecorder()
        let model = makeModel(recorder: recorder)

        model.updateCode("12345")
        #expect(model.submission == nil)

        model.updateCode("123456")
        await model.submission?.value

        #expect(recorder.codes == ["123456"])
        #expect(model.isSubmitting == false)
    }

    @Test("Gönderim sürerken ikinci gönderim yapılmaz")
    func duplicateSubmissionIsPrevented() async {
        let recorder = SubmitRecorder()
        recorder.holdsSubmission = true
        let model = makeModel(recorder: recorder)

        model.updateCode("123456")
        #expect(model.canSubmit == false)
        model.submit()
        // İlk gönderim kapanışa ulaşıp beklemeye geçene kadar ilerlet.
        while recorder.codes.isEmpty {
            await Task.yield()
        }
        model.submit()

        let submission = model.submission
        recorder.release()
        await submission?.value

        #expect(recorder.codes == ["123456"])
        #expect(model.canSubmit == true)
    }

    @Test("Eksik kod gönderilmez")
    func incompleteCodeIsNotSubmitted() {
        let model = makeModel(code: "123")

        model.submit()

        #expect(model.submission == nil)
    }

    // MARK: - Hata

    @Test("Doğrulama hatası modele yansır; buton tekrar denemek için etkin kalır")
    func submissionErrorIsShown() async {
        let recorder = SubmitRecorder()
        recorder.error = .invalidCode
        let model = makeModel(recorder: recorder)

        model.updateCode("123456")
        await model.submission?.value

        #expect(model.error == .invalidCode)
        #expect(model.canSubmit == true)
    }

    @Test("Yeni bir rakam yazıldığında hata temizlenir, silmek temizlemez")
    func newDigitClearsError() {
        let model = makeModel(code: "123456", error: .invalidCode)

        model.updateCode("12345")
        #expect(model.error == .invalidCode)

        model.updateCode("1234")
        #expect(model.error == .invalidCode)

        model.updateCode("12347")
        #expect(model.error == nil)
    }
}
