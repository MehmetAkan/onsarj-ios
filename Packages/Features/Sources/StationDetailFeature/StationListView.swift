import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Ana haritadaki şimşek düğmesiyle açılan yakındaki istasyonlar listesi. Harita pinleri VoiceOver'da
/// okunmadığı için VoiceOver kullanıcılarının istasyon bulma yoludur.
///
/// Üstte ek filtreler düğmesi, başlık ve X; altında süzgeç çipleri; sonra kartlar. Konum yoksa harita
/// merkezine göre aranır ve listenin üstünde not çıkar. Karta dokununca detay aynı modal içinde itilir
/// (geri ile listeye dönülür) ve seçim dışarı bildirilir.
///
/// Liste kendi sunumunu yapmaz (CLAUDE.md 5.3 kural 1): kapatma, yol tarifi, oylar, seçim ve süzgeç
/// değişiklikleri kapanışlarla dışarı bildirilir.
public struct StationListView: View {
    @State private var model: StationListModel
    @State private var isExtraFiltersPresented = false
    private let stationRepository: any StationRepository
    private let onClose: () -> Void
    private let onDirections: (Station.ID) -> Void
    private let onShowReviews: (Station.ID) -> Void

    /// - Parameters:
    ///   - origin: Kullanıcının konumu ya da (konum yoksa) harita merkezi.
    ///   - filters: Açılıştaki süzgeçler (oturum boyunca uygulama katmanında tutulur).
    ///   - stationRepository: Liste ve detayın kaynağı.
    ///   - vehicleRepository: "Aracımla uyumlu" için etkin araç.
    ///   - networkCatalog: "Ağlar" çipinin seçenekleri.
    ///   - onFiltersChange: Süzgeçler değişti.
    ///   - onSelectionChange: Detayı açık istasyon değişti (karta dokunuldu, geri dönüldü); haritada seçilir.
    ///   - onClose: X.
    ///   - onDirections: Karttaki veya detaydaki yol tarifi.
    ///   - onShowReviews: Detaydaki "Oyları göster".
    public init(
        origin: StationListOrigin,
        filters: StationListFilters,
        stationRepository: any StationRepository,
        vehicleRepository: any VehicleRepository,
        networkCatalog: any ChargingNetworkCatalog,
        onFiltersChange: @escaping (StationListFilters) -> Void,
        onSelectionChange: @escaping (Station?) -> Void,
        onClose: @escaping () -> Void,
        onDirections: @escaping (Station.ID) -> Void,
        onShowReviews: @escaping (Station.ID) -> Void
    ) {
        self.init(
            model: StationListModel(
                origin: origin, filters: filters, repository: stationRepository,
                vehicleRepository: vehicleRepository, networkCatalog: networkCatalog,
                onFiltersChange: onFiltersChange, onSelectionChange: onSelectionChange),
            stationRepository: stationRepository,
            onClose: onClose,
            onDirections: onDirections,
            onShowReviews: onShowReviews
        )
    }

    init(
        model: StationListModel,
        stationRepository: any StationRepository,
        onClose: @escaping () -> Void = {},
        onDirections: @escaping (Station.ID) -> Void = { _ in },
        onShowReviews: @escaping (Station.ID) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.stationRepository = stationRepository
        self.onClose = onClose
        self.onDirections = onDirections
        self.onShowReviews = onShowReviews
    }

    public var body: some View {
        NavigationStack(path: $model.path) {
            list
                .hidesNavigationBar()
                .navigationDestination(for: Station.self, destination: detail)
        }
        .task { await model.start() }
    }

    private var list: some View {
        VStack(spacing: 0) {
            ModalHeader(
                Text("stationList.title", bundle: .onsarj),
                leadingAction: .init(
                    icon: .options,
                    label: Text("stationList.moreFilters", bundle: .onsarj),
                    showsIndicator: model.filters.hasExtraFilters
                ) { isExtraFiltersPresented = true },
                closeLabel: Text("common.close", bundle: .onsarj),
                onClose: onClose
            )
            StationFilterBar(model: model)
                .padding(.bottom, Spacing.sm)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    if model.origin.isMapCenter {
                        Text(StationDetailText.localized("stationList.mapCenterNote"))
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    content
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(Theme.backgroundSheet)
        .sheet(isPresented: $isExtraFiltersPresented) {
            ExtraFiltersSheet(model: model)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LazyVStack(spacing: Spacing.md) {
                ForEach(StationListPlaceholder.items, content: card)
            }
            .redacted(reason: .placeholder)
            .disabled(true)
            .accessibilityHidden(true)
        case .loaded(let items) where items.isEmpty:
            message("stationList.empty", action: "stationList.clearFilters", perform: model.clearFilters)
        case .loaded(let items):
            LazyVStack(spacing: Spacing.md) {
                ForEach(items, content: card)
            }
        case .failed:
            message("stationList.loadFailed", action: "common.retry", perform: model.retry)
        }
    }

    private func card(_ item: StationListItem) -> some View {
        StationListCard(item: item, onSelect: { model.select(item) }, onDirections: { onDirections(item.id) })
    }

    /// Boş ve hata durumu: açıklama ve altında bir eylem.
    private func message(_ key: String, action: LocalizedStringKey, perform: @escaping () -> Void) -> some View {
        VStack(spacing: Spacing.md) {
            Text(StationDetailText.localized(key))
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: perform) {
                Text(action, bundle: .onsarj)
                    .font(Typography.button)
                    .foregroundStyle(Theme.brandPrimary)
                    .frame(minHeight: Spacing.minTapTarget)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
    }

    private func detail(_ station: Station) -> some View {
        StationDetailView(
            model: StationDetailModel(
                station: station, repository: stationRepository,
                copyToPasteboard: StationDetailView.copyToPasteboard),
            onBack: { model.path.removeLast() },
            onClose: onClose,
            onDirections: onDirections,
            onShowReviews: onShowReviews
        )
        .hidesNavigationBar()
    }
}
