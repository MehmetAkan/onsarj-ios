import DesignSystem
import Localization
import SwiftUI

/// Arama sayfasının üst satırı: arama alanı ve sağında kapat ya da "Ara" düğmesi.
///
/// - **Başlangıç:** alanın sağında yuvarlak kapat düğmesi.
/// - **Yazma:** alanın içinde sağda temizle düğmesi; kapat düğmesinin yerine "Ara" kapsülü gelir ve
///   alan buna göre daralır. Geçiş hareketlidir; "Hareketi Azalt" açıkken hareketsiz.
///
/// Klavyenin arama tuşu "Ara" düğmesiyle aynı işi yapar.
struct SearchTopBar: View {
    @Binding var query: String
    let isFocused: FocusState<Bool>.Binding
    let isTyping: Bool
    let onClear: () -> Void
    let onClose: () -> Void
    let onSubmit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// "Ara" kapsülünün arayüz testi kimliği; klavyenin aynı etiketli arama tuşundan ayırır.
    static let submitButtonIdentifier = "search.submitButton"

    /// Arama alanının ölçülen yüksekliği; sağdaki düğmeler aynı yükseklikte çizilir.
    @State private var fieldHeight: CGFloat = Spacing.minTapTarget

    var body: some View {
        HStack(spacing: Spacing.sm) {
            field
            if isTyping {
                submitButton
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                closeButton
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: isTyping)
    }

    private var field: some View {
        HStack(spacing: Spacing.sm) {
            AppIcon.search
                .foregroundStyle(Theme.textSecondary)
            TextField(text: $query, prompt: placeholder) {
                Text("home.search.placeholder", bundle: .onsarj)
            }
            .foregroundStyle(Theme.textPrimary)
            .focused(isFocused)
            .submitLabel(.search)
            .onSubmit(onSubmit)
            .padding(.vertical, Spacing.md)
            if isTyping {
                Button(action: onClear) {
                    AppIcon.clearText
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("search.clearText", bundle: .onsarj))
            }
        }
        .font(Typography.body)
        .padding(.leading, Spacing.lg)
        .padding(.trailing, isTyping ? Spacing.xs : Spacing.lg)
        .frame(minHeight: Spacing.minTapTarget)
        .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.field))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            fieldHeight = height
        }
    }

    private var placeholder: Text {
        Text("home.search.placeholder", bundle: .onsarj).foregroundStyle(Theme.textPlaceholder)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            AppIcon.close
                .font(Typography.button)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: fieldHeight, height: fieldHeight)
                .background(Theme.backgroundCard, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("common.close", bundle: .onsarj))
    }

    private var submitButton: some View {
        Button(action: onSubmit) {
            Text("common.search", bundle: .onsarj)
                .font(Typography.button)
                .foregroundStyle(Theme.onActionPrimary)
                .padding(.horizontal, Spacing.lg)
                .frame(minHeight: fieldHeight)
                .background(Theme.actionPrimary, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(Self.submitButtonIdentifier)
    }
}
