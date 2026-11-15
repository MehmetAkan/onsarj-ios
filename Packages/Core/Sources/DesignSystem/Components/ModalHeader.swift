import SwiftUI

/// Yığınlı modalların üst çubuğu: ortada başlık, solda isteğe bağlı geri oku, sağda yuvarlak X.
///
/// Sistem gezinme çubuğu yerine kullanılır; düğmeler iOS sürümünden bağımsız olarak aynı görünür
/// (plan seçenekleri, araç ayarları). X modalın tamamını kapatır. Başlık her zaman ortadadır: iki
/// yanda geniş olan tarafın genişliği kadar boşluk bırakır. Ekran sistem çubuğunu
/// `.hidesNavigationBar()` ile gizler; kenardan kaydırarak geri dönme açık kalır.
///
/// ```swift
/// ModalHeader(Text("plan.title", bundle: .onsarj),
///             backLabel: Text("common.back", bundle: .onsarj), onBack: pop,
///             closeLabel: Text("common.close", bundle: .onsarj), onClose: close)
/// ```
public struct ModalHeader: View {
    private let title: Text
    private let backLabel: Text?
    private let onBack: (() -> Void)?
    private let closeLabel: Text
    private let onClose: () -> Void

    @State private var sideWidth: CGFloat = Spacing.minTapTarget

    /// - Parameters:
    ///   - title: Başlık.
    ///   - backLabel: Geri okunun VoiceOver etiketi; `onBack` verilmezse kullanılmaz.
    ///   - onBack: Geri okuna dokunuldu; `nil` ise ok gösterilmez (yığının kökü).
    ///   - closeLabel: X'in VoiceOver etiketi.
    ///   - onClose: X'e dokunuldu.
    public init(
        _ title: Text,
        backLabel: Text? = nil,
        onBack: (() -> Void)? = nil,
        closeLabel: Text,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.backLabel = backLabel
        self.onBack = onBack
        self.closeLabel = closeLabel
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            title
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
                closeButton.onGeometryChange(for: CGFloat.self, of: \.size.width, action: measure)
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
        .accessibilityLabel(backLabel ?? Text(verbatim: ""))
    }

    private var closeButton: some View {
        Button(action: onClose) {
            AppIcon.close
                .font(Typography.buttonSmall)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                .background(Theme.backgroundCard, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(closeLabel)
    }
}

#if DEBUG
#Preview("ModalHeader") {
    VStack(spacing: Spacing.lg) {
        ModalHeader(Text(verbatim: "Plan options"), closeLabel: Text(verbatim: "Close"), onClose: {})
        ModalHeader(
            Text(verbatim: "Charging networks"),
            backLabel: Text(verbatim: "Back"),
            onBack: {},
            closeLabel: Text(verbatim: "Close"),
            onClose: {}
        )
    }
    .background(Theme.backgroundSheet)
}
#endif
