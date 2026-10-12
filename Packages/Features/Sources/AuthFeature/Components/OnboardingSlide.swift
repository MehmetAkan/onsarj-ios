import DesignSystem
import Localization
import SwiftUI

/// Tek bir tanıtım slaydı: illüstrasyon, başlık ve açıklama.
///
/// İllüstrasyon kalan dikey alanı doldurur ve gerektiğinde küçülür. Metin her zaman
/// tam görünür; büyük yazı boyutlarında yer açan illüstrasyondur.
struct OnboardingSlide: View {
    let slide: WelcomeModel.Slide

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(slide.imageName, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text(slide.title, bundle: .onsarj)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Text(slide.body, bundle: .onsarj)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, Spacing.screenMargin)
    }
}
