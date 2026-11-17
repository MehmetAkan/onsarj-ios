import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI
import UIKit

/// Haritada bir pine dokununca açılan istasyon detay sayfası.
///
/// Yukarıdan aşağı: paylaş ve kapat düğmeleri, başlık (ağ ve istasyon adı), özet satırı, "Yol tarifi al",
/// bilgi kartı, soketler, fiyatlandırma, olanaklar, derecelendirme. Başlık pinden bilinen özetle hemen görünür;
/// detay yüklenirken geri kalanı iskelet olarak çizilir, yüklenemezse hata ve "Tekrar dene" gösterilir.
///
/// Sayfa kendi sunumunu yapmaz (CLAUDE.md 5.3 kural 1): kapatma, yol tarifi ve oylar kapanışlarla dışarı
/// bildirilir.
public struct StationDetailView: View {
    @State private var model: StationDetailModel
    private let onClose: () -> Void
    private let onDirections: (Station.ID) -> Void
    private let onShowReviews: (Station.ID) -> Void

    /// - Parameters:
    ///   - station: Pinden bilinen özet; başlık bununla hemen çizilir.
    ///   - repository: Detayın kaynağı.
    ///   - onClose: Kapat (X) düğmesi.
    ///   - onDirections: "Yol tarifi al".
    ///   - onShowReviews: "Oyları göster".
    public init(
        station: Station,
        repository: any StationRepository,
        onClose: @escaping () -> Void,
        onDirections: @escaping (Station.ID) -> Void,
        onShowReviews: @escaping (Station.ID) -> Void
    ) {
        self.init(
            model: StationDetailModel(
                station: station, repository: repository,
                copyToPasteboard: { UIPasteboard.general.string = $0 }),
            onClose: onClose,
            onDirections: onDirections,
            onShowReviews: onShowReviews
        )
    }

    init(
        model: StationDetailModel,
        onClose: @escaping () -> Void = {},
        onDirections: @escaping (Station.ID) -> Void = { _ in },
        onShowReviews: @escaping (Station.ID) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.onClose = onClose
        self.onDirections = onDirections
        self.onShowReviews = onShowReviews
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                content
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.xl)
        }
        .safeAreaInset(edge: .top, spacing: 0) { topButtons }
        .background(Theme.backgroundSheet)
        .sensoryFeedback(.success, trigger: model.copyCount)
        .task { await model.load() }
    }

    private var topButtons: some View {
        HStack {
            ShareLink(item: model.shareText) { AppIcon.share.floatingMapButtonSurface() }
                .buttonStyle(.plain)
                .accessibilityLabel(StationDetailText.localized("stationDetail.share"))
            Spacer()
            FloatingMapButton(icon: .close, accessibilityLabel: "common.close", bundle: .onsarj, action: onClose)
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.sm)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: model.station.network.name)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: model.station.name)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            sections(for: StationDetailPlaceholder.detail(for: model.station))
                .redacted(reason: .placeholder)
                .disabled(true)
                .accessibilityHidden(true)
        case .loaded(let detail):
            sections(for: detail)
        case .failed:
            failure
        }
    }

    private func sections(for detail: StationDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            StationSummaryRow(detail: detail)
            PrimaryButton("stationDetail.directions", icon: .directions, bundle: .onsarj) {
                onDirections(model.station.id)
            }
            TimelineView(.periodic(from: .now, by: 60)) { context in
                StationInfoCard(
                    detail: detail, now: context.date, isAddressCopied: model.isAddressCopied,
                    onCopyAddress: model.copyAddress)
            }
            if !detail.connectorGroups.isEmpty {
                ConnectorsSection(groups: detail.connectorGroups)
            }
            TariffsSection(tariffs: detail.tariffs)
            if !detail.amenities.isEmpty {
                AmenitiesSection(amenities: detail.amenities) { onShowReviews(model.station.id) }
            }
            RatingSection(rating: detail.rating)
        }
    }

    private var failure: some View {
        VStack(spacing: Spacing.md) {
            Text(StationDetailText.localized("stationDetail.loadFailed"))
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await model.load() }
            } label: {
                Text("common.retry", bundle: .onsarj)
                    .font(Typography.button)
                    .foregroundStyle(Theme.brandPrimary)
                    .frame(minHeight: Spacing.minTapTarget)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
    }
}
