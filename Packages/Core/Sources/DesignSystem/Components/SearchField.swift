import SwiftUI

/// Liste içinde arama alanı: solda büyüteç, kart zemini, `Radius.field` köşe.
///
/// Ağ seçici ve araç markaları gibi listeleri süzer. Otomatik düzeltme kapalıdır; klavyenin dönüş tuşu
/// "Ara"dır. Yer tutucu `Theme.textPlaceholder` rengindedir ve VoiceOver etiketi olarak da okunur.
///
/// ```swift
/// SearchField(query: $model.query, placeholder: Text("common.search", bundle: .onsarj),
///             isFocused: $isFieldFocused)
/// ```
public struct SearchField: View {
    @Binding private var query: String
    private let placeholder: Text
    private let isFocused: FocusState<Bool>.Binding

    public init(query: Binding<String>, placeholder: Text, isFocused: FocusState<Bool>.Binding) {
        _query = query
        self.placeholder = placeholder
        self.isFocused = isFocused
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            AppIcon.search
                .foregroundStyle(Theme.textSecondary)
            TextField(text: $query, prompt: placeholder.foregroundStyle(Theme.textPlaceholder)) {
                placeholder
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
}
