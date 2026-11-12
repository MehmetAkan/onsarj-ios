import DesignSystem
import Localization
import SwiftUI

/// "Kod gelmedi mi?" sorusu ve yanında geri sayımlı "Kodu tekrar gönder" düğmesi.
///
/// Süre dolana kadar kalan saniyeyi gösterir ve dokunulamaz; süre dolunca dokunulabilir
/// olur. Kalan süre her yenilemede bitiş zamanından hesaplanır (`remainingSeconds`);
/// uygulama arka plandan döndüğünde de doğru değeri gösterir.
struct ResendCodeButton: View {
    /// Geri sayımın başladığı an. Yenilemeler bu andan itibaren tam saniyelere hizalanır.
    let countdownStart: Date
    /// Verilen anda kalan tam saniye; süre dolduysa 0.
    let remainingSeconds: (Date) -> Int
    let action: () -> Void

    var body: some View {
        TimelineView(.periodic(from: countdownStart, by: 1)) { context in
            // Büyük yazı boyutunda soru ve düğme yan yana sığmazsa alt alta geçer.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    question
                    button(remaining: remainingSeconds(context.date))
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    question
                    button(remaining: remainingSeconds(context.date))
                }
            }
        }
    }

    private var question: some View {
        Text("verification.resend.question", bundle: .onsarj)
            .font(Typography.secondary)
            .foregroundStyle(Theme.textSecondary)
    }

    private func button(remaining: Int) -> some View {
        Button(action: action) {
            label(remaining: remaining)
                // Metin alanın üstüne yaslanır: dokunma alanı 44pt kalır ama aşağı doğru
                // uzar, metin kod alanından uzaklaşmaz.
                .frame(minHeight: Spacing.minTapTarget, alignment: .top)
                .contentShape(Rectangle())
        }
        .disabled(remaining > 0)
        // Geri sayım sürerken VoiceOver metni her saniye yeniden seslendirmez.
        .accessibilityAddTraits(remaining > 0 ? .updatesFrequently : [])
    }

    /// Geri sayım sürerken soluk düz metin; süre dolunca altı çizili, metin renginde bağlantı.
    @ViewBuilder
    private func label(remaining: Int) -> some View {
        if remaining > 0 {
            Text(verbatim: countdownText(remaining: remaining))
                .font(Typography.secondary)
                .monospacedDigit()
                .foregroundStyle(Theme.textSecondary)
        } else {
            Text("verification.resend.action", bundle: .onsarj)
                .font(Typography.secondary)
                .underline()
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func countdownText(remaining: Int) -> String {
        let format = String(localized: "verification.resend.countdown", bundle: .onsarj)
        return String.localizedStringWithFormat(format, remaining)
    }
}
