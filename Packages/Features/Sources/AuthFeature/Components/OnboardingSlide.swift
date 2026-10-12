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

    /// Başlığın harf aralığı: punto büyüklüğünün %1'i kadar daraltma.
    /// Yazı boyutuyla birlikte ölçeklenir.
    @ScaledMetric(relativeTo: .largeTitle) private var titleTracking: CGFloat = -0.34

    var body: some View {
        VStack(spacing: Spacing.xl) {
            illustration

            VStack(spacing: Spacing.xs) {
                Text(slide.title, bundle: .onsarj)
                    .font(Typography.display)
                    .tracking(titleTracking)
                    .foregroundStyle(Theme.textPrimary)

                Text(slide.body, bundle: .onsarj)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
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
