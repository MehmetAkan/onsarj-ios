import DesignSystem
import OnsarjDomain
import SwiftUI

/// İstasyon özeti: hız sınıfı şimşekleri ve en yüksek güç, müsaitlik noktası ve boş/toplam soket, en sağda en
/// çok üç olanak simgesi. Detay sayfasında başlığın altında ve yakındaki istasyonlar listesindeki kartlarda
/// aynen kullanılır.
struct StationSummaryRow: View {
    let maxPowerKw: Double?
    let availableCount: Int?
    let totalCount: Int
    let amenities: [Amenity]
    @Environment(\.locale) private var locale

    init(detail: StationDetail) {
        maxPowerKw = detail.maxPowerKw
        availableCount = detail.availableCount
        totalCount = detail.totalCount
        amenities = detail.amenities
    }

    init(item: StationListItem) {
        maxPowerKw = item.maxPowerKw
        availableCount = item.availableCount
        totalCount = item.totalCount
        amenities = item.amenities
    }

    private var availability: StationAvailability {
        StationAvailability(available: availableCount, total: totalCount)
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            if let power = maxPowerKw {
                let speed = ChargingSpeed(powerKw: power)
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
                    .fill(availability.color)
                    .frame(
                        width: StationDetailMetrics.availabilityDotDiameter,
                        height: StationDetailMetrics.availabilityDotDiameter)
                Text(StationDetailText.ratio(available: availableCount, total: totalCount))
                    .font(Typography.numeric)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                StationDetailText.ratioAccessibility(available: availableCount, total: totalCount))
            Spacer(minLength: 0)
            HStack(spacing: Spacing.sm) {
                ForEach(amenities.prefix(StationDetailMetrics.summaryAmenityLimit), id: \.self) { amenity in
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
