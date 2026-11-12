import DesignSystem
import Localization
import SwiftUI

/// Tek bir tanıtım slaydı: illüstrasyon, başlık ve açıklama.
///
/// İllüstrasyon ekranın iki kenarına dayanır. Dikey alan yetmezse küçülmez, üstten ve
/// alttan kırpılır (CSS `object-fit: cover` gibi). Metin her zaman tam görünür.
struct OnboardingSlide: View {
    let slide: WelcomeModel.Slide

    /// İllüstrasyonların en-boy oranı (genişlik / yükseklik). Görseller kare çizilir.
    private static let illustrationAspectRatio: CGFloat = 1

    /// Başlığın harf aralığı: punto büyüklüğünün %2'si kadar daraltma.
    /// Yazı boyutuyla birlikte ölçeklenir.
    @ScaledMetric(relativeTo: .title) private var titleTracking: CGFloat = -0.56

    /// Açıklama metninin en az kaç satırlık yer kaplayacağı. Kısa açıklama tek satıra
    /// sığsa bile slaytlar arasında görsel ve başlık aynı hizada kalır.
    private static let minimumBodyLines = 2

    /// Açıklama sütununun en büyük genişliği. Geniş ekranlarda kısa bir açıklamanın tek
    /// uzun satıra yayılmasını önler; açıklamalar dengeli iki satıra bölünür. Yazı
    /// boyutuyla ölçeklenir, dar ekranda ekran genişliği zaten daha küçük kalır.
    @ScaledMetric(relativeTo: .subheadline) private var bodyMaxWidth: CGFloat = 300

    var body: some View {
        VStack(spacing: Spacing.xl) {
            illustration

            VStack(spacing: Spacing.xs) {
                Text(slide.title, bundle: .onsarj)
                    .font(Typography.title)
                    .tracking(titleTracking)
                    .foregroundStyle(Theme.textPrimary)

                Text(slide.body, bundle: .onsarj)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(Self.minimumBodyLines...)
                    .frame(maxWidth: bodyMaxWidth)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .padding(.horizontal, Spacing.screenMargin)
        }
    }

    /// Genişliği ekranla eşitlenen illüstrasyon. Yüksekliği doğal oranını aşmaz;
    /// alan doğal yükseklikten kısaysa görsel kırpılır.
    private var illustration: some View {
        GeometryReader { proxy in
            let naturalHeight = proxy.size.width / Self.illustrationAspectRatio
            Image(slide.imageName, bundle: .module)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: min(proxy.size.height, naturalHeight))
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}
