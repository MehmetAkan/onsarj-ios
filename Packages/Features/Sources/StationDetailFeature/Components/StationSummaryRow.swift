import DesignSystem
import OnsarjDomain
import SwiftUI

/// Başlığın altındaki özet: hız sınıfı şimşekleri ve en yüksek güç, müsaitlik noktası ve boş/toplam soket,
/// en sağda en çok üç olanak simgesi.
struct StationSummaryRow: View {
    let detail: StationDetail
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Spacing.lg) {
            if let speed = detail.speed, let power = detail.maxPowerKw {
                HStack(spacing: Spacing.xs) {
                    bolts(speed)
                    Text(StationDetailText.power(power, locale: locale))
                        .font(Typography.numeric)
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityElement(children: .combine)
            }
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(detail.availability.color)
                    .frame(
                        width: StationDetailMetrics.availabilityDotDiameter,
                        height: StationDetailMetrics.availabilityDotDiameter)
                Text(StationDetailText.ratio(available: detail.availableCount, total: detail.totalCount))
                    .font(Typography.numeric)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                StationDetailText.ratioAccessibility(available: detail.availableCount, total: detail.totalCount))
            Spacer(minLength: 0)
            HStack(spacing: Spacing.sm) {
                ForEach(detail.amenities.prefix(StationDetailMetrics.summaryAmenityLimit), id: \.self) { amenity in
                    amenity.icon
                }
            }
            .font(Typography.body)
            .foregroundStyle(Theme.textPrimary)
            .accessibilityHidden(true)
        }
    }

    private func bolts(_ speed: ChargingSpeed) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<speed.boltCount, id: \.self) { _ in AppIcon.charger }
        }
        .font(Typography.body)
        .foregroundStyle(Theme.availabilityAvailable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            StationDetailText.format("stationDetail.speed.accessibility", StationDetailText.localized(speed.nameKey)))
    }
}
