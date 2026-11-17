import DesignSystem
import OnsarjDomain
import SwiftUI

/// "Üyelikler ve fiyatlandırma": tarifeler kartı; her tarifede ad, ödeme yöntemleri ve fiyat.
struct TariffsSection: View {
    let tariffs: [Tariff]
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTitle(key: "stationDetail.pricing")
            DetailCard {
                Text(StationDetailText.localized("stationDetail.tariffs"))
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Theme.textPrimary)
                if tariffs.isEmpty {
                    Text(StationDetailText.localized("stationDetail.noPrice"))
                        .font(Typography.body)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(Array(tariffs.enumerated()), id: \.offset) { _, tariff in row(tariff) }
                }
            }
        }
    }

    private func row(_ tariff: Tariff) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(verbatim: tariff.name)
                .font(Typography.body)
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: Spacing.xs) {
                ForEach(tariff.paymentMethods, id: \.self) { method in
                    method.icon
                        .accessibilityLabel(StationDetailText.localized(method.nameKey))
                }
            }
            .font(Typography.body)
            .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: Spacing.sm)
            prices(tariff)
        }
        .accessibilityElement(children: .combine)
    }

    private func prices(_ tariff: Tariff) -> some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            if let price = tariff.pricePerKwh {
                Text(formatted(price, tariff, perKey: "stationDetail.price.perKwh"))
                    .font(Typography.numeric)
                    .foregroundStyle(Theme.textPrimary)
            }
            if let price = tariff.pricePerMinute {
                Text(formatted(price, tariff, perKey: "stationDetail.price.perMinute"))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func formatted(_ amount: Decimal, _ tariff: Tariff, perKey key: String) -> String {
        StationDetailText.price(amount, currencyCode: tariff.currencyCode, perKey: key, locale: locale)
    }
}
