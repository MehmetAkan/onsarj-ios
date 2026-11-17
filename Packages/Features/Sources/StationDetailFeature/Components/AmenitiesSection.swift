import DesignSystem
import OnsarjDomain
import SwiftUI

/// "Olanaklar": başlık, sağda "Oyları göster" bağlantısı ve olanak çipleri. Olanak yoksa bölüm gösterilmez.
struct AmenitiesSection: View {
    let amenities: [Amenity]
    let onShowReviews: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(key: "stationDetail.amenities")
                Spacer(minLength: Spacing.sm)
                Button(action: onShowReviews) {
                    Text(StationDetailText.localized("stationDetail.showReviews"))
                        .font(Typography.body)
                        .foregroundStyle(Theme.brandPrimary)
                        .frame(minHeight: Spacing.minTapTarget)
                }
                .buttonStyle(.plain)
            }
            WrappingHStack(spacing: Spacing.sm) {
                ForEach(amenities, id: \.self) { AmenityChip(amenity: $0) }
            }
        }
    }
}

/// Olanak çipi: simge ve ad. Bilgi gösterir, dokunulamaz.
struct AmenityChip: View {
    let amenity: Amenity

    var body: some View {
        Label(title: { Text(StationDetailText.localized(amenity.nameKey)) }, icon: { amenity.icon })
            .font(Typography.secondary)
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.chip))
    }
}

/// "Derecelendirme": puan varsa "4,6 ★ (23)", yoksa "Değerlendirme yok".
struct RatingSection: View {
    let rating: RatingSummary?
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionTitle(key: "stationDetail.rating")
            if let rating {
                let average = rating.average.formatted(.number.precision(.fractionLength(1)).locale(locale))
                HStack(spacing: Spacing.xs) {
                    Text(verbatim: average).font(Typography.numeric).foregroundStyle(Theme.textPrimary)
                    AppIcon.rating.foregroundStyle(Theme.textPrimary)
                    Text(verbatim: "(\(rating.count.formatted(.number.locale(locale))))")
                        .foregroundStyle(Theme.textSecondary)
                }
                .font(Typography.body)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    StationDetailText.format("stationDetail.rating.accessibility", average, rating.count))
            } else {
                Text(StationDetailText.localized("stationDetail.noRating"))
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
