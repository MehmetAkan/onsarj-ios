import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Tek değer düzenleme modalı: başlık, birimli giriş alanı, hata satırı ve "Kaydet".
///
/// Sistem `.sheet`'i olarak, içeriğin yüksekliğinde açılır. Açılınca alan odaklanır ve mevcut değer
/// seçili gelir. "Kaydet" değer geçersizse veya değişmemişse pasiftir; yarım yazılmış bir sayı kaydedilmez.
struct ValueEditorSheet: View {
    let target: ValueEditTarget
    let onSave: (ValueEditor) async -> Void

    @State private var editor: ValueEditor
    @State private var height: CGFloat = 0
    @State private var isSaving = false
    @FocusState private var isFocused: Bool

    init(
        target: ValueEditTarget,
        vehicle: Vehicle,
        locale: Locale = .current,
        onSave: @escaping (ValueEditor) async -> Void
    ) {
        self.target = target
        self.onSave = onSave
        _editor = State(initialValue: target.editor(for: vehicle, locale: locale))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(target.titleKey, bundle: .onsarj)
                .font(Typography.headline)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ValueInputField(
                label: Text(target.titleKey, bundle: .onsarj),
                editor: $editor,
                unitKey: target.unitKey,
                errorText: GarageText.rangeError(editor),
                isFocused: $isFocused,
                selectsAllOnFocus: true
            )
            PrimaryButton("common.save", bundle: .onsarj) {
                isSaving = true
                Task { await onSave(editor) }
            }
            .disabled(!editor.canSave || isSaving)
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents(height > 0 ? [.height(height)] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.backgroundSheet)
        .task { isFocused = true }
    }
}
