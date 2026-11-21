import DesignSystem
import Localization
import SwiftUI
import UIKit

/// Değer giriş alanı: metin, sağında birim ve altında hata satırı.
///
/// Klavye türü değere göre seçilir (ondalık, tam sayı, metin). `selectsAllOnFocus` açıkken alan
/// odaklanınca mevcut değer seçili gelir; yazmaya başlayınca yerine geçer.
struct ValueInputField: View {
    let label: Text
    @Binding var editor: ValueEditor
    let unitKey: LocalizedStringKey?
    /// Alanın altındaki hata satırı; `nil` ise satır yok.
    let errorText: String?
    var isFocused: FocusState<Bool>.Binding
    var selectsAllOnFocus = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                TextField(text: $editor.text) { label }
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled(editor.kind != .text)
                    .focused(isFocused)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.vertical, Spacing.md)
                if let unitKey {
                    Text(unitKey, bundle: .onsarj)
                        .foregroundStyle(Theme.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .font(Typography.body)
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: Spacing.minTapTarget)
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.field))
            .overlay {
                if errorText != nil {
                    RoundedRectangle(cornerRadius: Radius.field).strokeBorder(Theme.borderError)
                }
            }
            if let errorText {
                Text(verbatim: errorText)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textError)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { note in
            guard selectsAllOnFocus, let field = note.object as? UITextField else { return }
            Task { @MainActor in field.selectAll(nil) }
        }
    }

    private var keyboardType: UIKeyboardType {
        switch editor.kind {
        case .decimal: .decimalPad
        case .integer: .numberPad
        case .text: .default
        }
    }
}
