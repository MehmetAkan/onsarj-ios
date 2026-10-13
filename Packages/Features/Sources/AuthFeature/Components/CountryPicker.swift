import DesignSystem
import Localization
import PhoneNumbers
import SwiftUI

/// Aranabilir ülke listesi. Her satırda bayrak, ülke adı ve arama kodu.
///
/// Liste dışarıdan verilir (`PhoneNumberFormatter.countries`); seçici ülke verisi tutmaz.
/// Arama ülke adında, bölge kodunda (`TR`) ve arama kodunda (`90`, `+90`) yapılır.
struct CountryPicker: View {
    let countries: [PhoneCountry]
    let selected: PhoneCountry
    let onSelect: (PhoneCountry) -> Void

    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button {
                    onSelect(country)
                    dismiss()
                } label: {
                    CountryRow(country: country, isSelected: country == selected)
                }
            }
            .listStyle(.plain)
            .overlay {
                if filteredCountries.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("signup.country.search", bundle: .onsarj)
            )
            .navigationTitle(Text("signup.country.title", bundle: .onsarj))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var filteredCountries: [PhoneCountry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return countries }
        let dialQuery = trimmed.filter(\.isNumber)
        return countries.filter { country in
            country.localizedName().localizedStandardContains(trimmed)
                || country.regionCode.caseInsensitiveCompare(trimmed) == .orderedSame
                || (!dialQuery.isEmpty && country.dialCode.hasPrefix(dialQuery))
        }
    }
}

private struct CountryRow: View {
    let country: PhoneCountry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(country.flag)
                .font(Typography.titleSmall)
                .accessibilityHidden(true)

            Text(country.localizedName())
                .font(Typography.body)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(country.displayDialCode)
                .font(Typography.numeric)
                .foregroundStyle(Theme.textSecondary)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(minHeight: Spacing.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
