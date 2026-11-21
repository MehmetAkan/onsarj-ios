import SwiftUI

/// Yığınlı modalların üst çubuğu: ortada başlık, solda isteğe bağlı geri oku veya yuvarlak bir eylem düğmesi
/// (`LeadingAction`), sağda yuvarlak X.
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
    /// Solda X ile aynı görünen yuvarlak eylem düğmesi (ör. ek filtreler). Geri okuyla birlikte verilmez;
    /// yığının kök sayfasında kullanılır.
    public struct LeadingAction {
        let icon: AppIcon
        let label: Text
        let showsIndicator: Bool
        let action: () -> Void

        /// - Parameters:
        ///   - icon: Düğmenin simgesi.
        ///   - label: VoiceOver etiketi.
        ///   - showsIndicator: Sağ üstte küçük nokta (ör. bir filtre açık). VoiceOver'a ayrıca bildirilmez;
        ///     durumu etiket veya değer anlatır.
        ///   - action: Dokunulduğunda.
        public init(icon: AppIcon, label: Text, showsIndicator: Bool = false, action: @escaping () -> Void) {
            self.icon = icon
            self.label = label
            self.showsIndicator = showsIndicator
            self.action = action
        }
    }

    /// Nokta işaretinin çapı; yazı boyutuyla ölçeklenmez.
    private static let indicatorDiameter: CGFloat = 8

    private let title: Text
    private let backLabel: Text?
    private let onBack: (() -> Void)?
    private let leadingAction: LeadingAction?
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
        leadingAction = nil
        self.closeLabel = closeLabel
        self.onClose = onClose
    }

    /// Solda yuvarlak eylem düğmesi olan üst çubuk (yığının kökü).
    /// - Parameters:
    ///   - title: Başlık.
    ///   - leadingAction: Soldaki düğme.
    ///   - closeLabel: X'in VoiceOver etiketi.
    ///   - onClose: X'e dokunuldu.
    public init(_ title: Text, leadingAction: LeadingAction, closeLabel: Text, onClose: @escaping () -> Void) {
        self.title = title
        backLabel = nil
        onBack = nil
        self.leadingAction = leadingAction
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
                } else if let leadingAction {
                    leadingButton(leadingAction)
                        .onGeometryChange(for: CGFloat.self, of: \.size.width, action: measure)
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
            Self.circle(.close)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(closeLabel)
    }

    private func leadingButton(_ leading: LeadingAction) -> some View {
        Button(action: leading.action) {
            Self.circle(leading.icon)
                .overlay(alignment: .topTrailing) {
                    if leading.showsIndicator {
                        Circle()
                            .fill(Theme.actionPrimary)
                            .frame(width: Self.indicatorDiameter, height: Self.indicatorDiameter)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(leading.label)
    }

    /// X ve soldaki eylem düğmesinin ortak yüzeyi: kart zemininde daire.
    private static func circle(_ icon: AppIcon) -> some View {
        icon
            .font(Typography.buttonSmall)
            .foregroundStyle(Theme.textPrimary)
            .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
            .background(Theme.backgroundCard, in: Circle())
            .contentShape(Circle())
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
        ModalHeader(
            Text(verbatim: "Charging stations"),
            leadingAction: .init(icon: .options, label: Text(verbatim: "More filters"), showsIndicator: true) {},
            closeLabel: Text(verbatim: "Close"),
            onClose: {}
        )
    }
    .background(Theme.backgroundSheet)
}
#endif
