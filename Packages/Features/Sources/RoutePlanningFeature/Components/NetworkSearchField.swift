import DesignSystem
import Localization
import SwiftUI

/// Ağ seçicinin arama alanı; arama sayfasındaki alanla aynı görünüm.
struct NetworkSearchField: View {
    @Binding var query: String
    let isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: Spacing.sm) {
            AppIcon.search
                .foregroundStyle(Theme.textSecondary)
            TextField(text: $query, prompt: placeholder) {
                Text("common.search", bundle: .onsarj)
            }
            .foregroundStyle(Theme.textPrimary)
            .focused(isFocused)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .padding(.vertical, Spacing.md)
        }
        .font(Typography.body)
        .padding(.horizontal, Spacing.lg)
        .frame(minHeight: Spacing.minTapTarget)
        .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.field))
    }

    private var placeholder: Text {
        Text("common.search", bundle: .onsarj).foregroundStyle(Theme.textPlaceholder)
    }
}
