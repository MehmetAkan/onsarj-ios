import DesignSystem
import Localization
import SwiftUI

/// Plan seçenekleri modalının üst çubuğu: ortada başlık, solda isteğe bağlı geri oku, sağda bir
/// düğme (kapat).
///
/// Sistem gezinme çubuğu yerine kullanılır; düğmeler iOS sürümünden bağımsız olarak aynı görünür.
/// Başlık her zaman ortadadır: iki yanda geniş olan tarafın genişliği kadar boşluk bırakır.
struct ModalHeader<Trailing: View>: View {
    private let titleKey: LocalizedStringKey
    private let onBack: (() -> Void)?
    private let trailing: Trailing

    @State private var sideWidth: CGFloat = Spacing.minTapTarget

    init(_ titleKey: LocalizedStringKey, onBack: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.titleKey = titleKey
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(titleKey, bundle: .onsarj)
                .font(Typography.headline)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, sideWidth + Spacing.sm)

            HStack(spacing: 0) {
                if let onBack {
                    backButton(onBack).onGeometryChange(for: CGFloat.self, of: \.size.width, action: measure)
                }
                Spacer(minLength: 0)
                trailing.onGeometryChange(for: CGFloat.self, of: \.size.width, action: measure)
            }
        }
        .frame(minHeight: Spacing.minTapTarget)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    private func measure(_ width: CGFloat) {
        sideWidth = max(sideWidth, width)
    }

    /// Ok görsel olarak küçüktür; dokunma alanı `Spacing.minTapTarget` karesidir ve ok bu karenin
    /// soluna yaslanır.
    private func backButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AppIcon.back
                .font(Typography.button)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("signup.phone.accessibility.back", bundle: .onsarj))
    }
}

/// Modalın tamamını kapatan yuvarlak X düğmesi; arama sayfasındaki kapat düğmesiyle aynı görünüm.
struct ModalCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon.close
                .font(Typography.buttonSmall)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                .background(Theme.backgroundCard, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("search.close", bundle: .onsarj))
    }
}
