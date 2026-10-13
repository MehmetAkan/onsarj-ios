import DesignSystem
import Localization
import SwiftUI

/// Ülke kodu bloğu ve numara alanı, yan yana ve aynı yükseklikte.
///
/// Ülke dışarıdan verilir. Ülke kodu bloğu MVP'de yalnızca gösterimdir: aşağı ok,
/// ileride açılacak ülke listesinin yerini işaret eder, dokunulduğunda bir şey olmaz.
struct PhoneNumberField: View {
    let country: PhoneCountry
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: Spacing.sm) {
            countryCode
            numberField
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var countryCode: some View {
        HStack(spacing: Spacing.xs) {
            Text(country.displayDialCode)
                .font(Typography.numeric)
                .foregroundStyle(Theme.textPrimary)
            Image(systemName: "chevron.down")
                .font(Typography.captionSmall)
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Spacing.md)
        .frame(maxHeight: .infinity)
        .background(Theme.backgroundSubtle, in: fieldShape)
    }

    private var numberField: some View {
        HStack(spacing: Spacing.sm) {
            TextField(text: $text, prompt: placeholder) {
                Text("signup.phone.placeholder", bundle: .onsarj)
            }
            .font(Typography.numeric)
            .foregroundStyle(Theme.textPrimary)
            .focused(isFocused)
            .phoneNumberInputTraits()

            if !text.isEmpty {
                clearButton
            }
        }
        .padding(.leading, Spacing.md)
        .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
        .padding(.vertical, Spacing.xs)
        .background(Theme.backgroundSubtle, in: fieldShape)
    }

    private var placeholder: Text {
        Text("signup.phone.placeholder", bundle: .onsarj)
            .foregroundStyle(Theme.textPlaceholder)
    }

    private var clearButton: some View {
        Button {
            text = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(Typography.body)
                .foregroundStyle(Theme.textPlaceholder)
                .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("signup.phone.accessibility.clear", bundle: .onsarj))
    }

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.field)
    }
}

extension View {
    /// Telefon tuş takımı ve otomatik doldurma ipucu. Yalnızca iOS'ta vardır; macOS'taki
    /// `swift build` geri bildirim döngüsü için koruma altındadır.
    @ViewBuilder
    fileprivate func phoneNumberInputTraits() -> some View {
        #if os(iOS)
        keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
        #else
        self
        #endif
    }
}
