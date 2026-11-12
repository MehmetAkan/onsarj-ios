import DesignSystem
import Localization
import PhoneNumbers
import SwiftUI

/// Ülke kodu düğmesi ve numara alanı, yan yana ve aynı yükseklikte.
///
/// Ülke kodu düğmesi ülke seçiciyi açma isteğini dışarı bildirir; seçiciyi ekran açar.
struct PhoneNumberField: View {
    let formatter: PhoneNumberFormatter
    @Binding var number: ParsedPhoneNumber
    let placeholder: String
    var focusesOnAppear = false
    let onCountryTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            countryButton
            numberField
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var countryButton: some View {
        Button(action: onCountryTap) {
            HStack(spacing: Spacing.xs) {
                Text(number.country.displayDialCode)
                    .font(Typography.numeric)
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: "chevron.down")
                    .font(Typography.captionSmall)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .frame(maxHeight: .infinity)
            .background(Theme.backgroundSubtle, in: fieldShape)
            .contentShape(fieldShape)
        }
        .accessibilityLabel(Text("signup.phone.accessibility.country", bundle: .onsarj))
        .accessibilityValue(Text(verbatim: "\(number.country.localizedName()) \(number.country.displayDialCode)"))
    }

    private var numberField: some View {
        HStack(spacing: Spacing.sm) {
            PhoneNumberTextField(
                formatter: formatter,
                number: $number,
                placeholder: placeholder,
                accessibilityLabel: String(localized: "signup.phone.placeholder", bundle: .onsarj),
                focusesOnAppear: focusesOnAppear
            )

            if !number.nationalDigits.isEmpty {
                clearButton
            }
        }
        .padding(.leading, Spacing.md)
        .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
        .padding(.vertical, Spacing.xs)
        .background(Theme.backgroundSubtle, in: fieldShape)
    }

    private var clearButton: some View {
        Button {
            number = formatter.parse("", for: number.country)
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
