import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Katalog listesi: tek kutu, satırlar arasında `InsetDivider`.
struct CatalogList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                row(item)
                if item.id != items.last?.id {
                    InsetDivider()
                }
            }
        }
        .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
    }
}

/// Katalog satırı: solda isteğe bağlı görsel, ad, sağda ikincil bilgi ve ok.
struct CatalogRow<Leading: View>: View {
    let title: String
    let detail: String?
    @ViewBuilder let leading: () -> Leading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                leading()
                Text(verbatim: title)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let detail {
                    Text(verbatim: detail)
                        .font(Typography.secondary)
                        .foregroundStyle(Theme.textSecondary)
                }
                AppIcon.disclosure
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: Spacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Varyant satırı: ad, altında yıl · kapasite · konnektörler; sağda küçük görsel veya ilerleme göstergesi.
struct VariantRow: View {
    let variant: VehicleVariant
    let summary: String
    let isAdding: Bool
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: variant.name)
                        .font(Typography.body)
                        .foregroundStyle(isEnabled || isAdding ? Theme.textPrimary : Theme.textDisabled)
                    Text(verbatim: summary)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isAdding {
                    ProgressView()
                } else if let url = variant.imageURL {
                    VehicleThumbnail(url: url)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: Spacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Satırın sağındaki küçük araç görseli; yüklenemezse alan çizilmez.
struct VehicleThumbnail: View {
    let url: URL

    /// Görselin satır genişliğine oranı.
    private static let widthRatio = 0.24

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .containerRelativeFrame(.horizontal) { width, _ in width * Self.widthRatio }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Liste yerine gösterilen ikincil metin ("Sonuç bulunamadı").
struct CatalogMessage: View {
    let key: LocalizedStringKey

    var body: some View {
        Text(key, bundle: .onsarj)
            .font(Typography.body)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xl)
    }
}

/// Yükleme hatası: açıklama ve "Tekrar dene".
struct LoadFailureView: View {
    let messageKey: LocalizedStringKey
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            CatalogMessage(key: messageKey)
            PrimaryButton("common.retry", bundle: .onsarj, action: onRetry)
        }
        .padding(.horizontal, Spacing.screenMargin)
    }
}
