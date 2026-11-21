import DesignSystem
import OnsarjDomain
import SwiftUI

/// Yakındaki istasyonlar listesinde bir istasyon: ağ ve istasyon adı, sağda yol tarifi düğmesi ve uzaklık,
/// altta detay sayfasındaki özet satırı (`StationSummaryRow`), fotoğraf varsa en altta.
///
/// Kartın tamamı tek bir düğmedir (VoiceOver'da tek öğe); yol tarifi düğmesi kartın üstünde ayrı bir öğedir.
struct StationListCard: View {
    let item: StationListItem
    let onSelect: () -> Void
    let onDirections: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: onSelect) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(StationListText.cardAccessibility(item, locale: locale))
        .accessibilityAddTraits(.isButton)
        .overlay(alignment: .topTrailing) {
            directions.padding([.top, .trailing], Spacing.lg)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: item.station.network.name)
                        .font(Typography.bodyStrong)
                        .foregroundStyle(Theme.textPrimary)
                    Text(verbatim: item.station.name)
                        .font(Typography.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Yerleşim için yer tutucu; asıl düğme kartın üstünde durur.
                directions.hidden()
            }
            StationSummaryRow(item: item)
            if let url = item.photoURL {
                StationPhoto(url: url)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
        .contentShape(RoundedRectangle(cornerRadius: Radius.card))
    }

    private var directions: some View {
        VStack(spacing: Spacing.xs) {
            Button(action: onDirections) {
                AppIcon.directions
                    .font(Typography.button)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                    .background(Theme.backgroundSubtle, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(StationDetailText.localized("stationDetail.directions"))
            if let kilometers = item.distanceKm {
                Text(StationListText.distance(kilometers, width: .abbreviated, locale: locale))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// İstasyonun fotoğrafı: 16:9, yuvarlak köşeli. Yüklenirken ve yüklenemezse sade zemin görünür.
struct StationPhoto: View {
    let url: URL

    var body: some View {
        Color.clear
            .aspectRatio(StationDetailMetrics.photoAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(Theme.backgroundSubtle)
            .overlay {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .accessibilityHidden(true)
    }
}
