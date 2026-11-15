import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Ağ seçici: tek bileşen, iki kip (`prefer`, `avoid`).
///
/// Açılınca arama alanı odaklanır; boş sorguda tüm liste gösterilir. Yazım ≈300 ms bekledikten sonra
/// aranır, eski istek iptal edilir. Liste kaydırılınca klavye kapanır.
struct NetworkPickerView: View {
    @State private var model: NetworkPickerModel
    @FocusState private var isFieldFocused: Bool
    private let onBack: () -> Void
    private let onClose: () -> Void

    init(model: NetworkPickerModel, onBack: @escaping () -> Void, onClose: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            NetworkSearchField(query: $model.query, isFocused: $isFieldFocused)
                .padding(.horizontal, Spacing.screenMargin)
            results
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ModalHeader(
                Text(model.mode.titleKey, bundle: .onsarj),
                backLabel: Text("common.back", bundle: .onsarj),
                onBack: onBack,
                closeLabel: Text("common.close", bundle: .onsarj),
                onClose: onClose
            )
            .background(Theme.backgroundSheet)
        }
        .background(Theme.backgroundSheet.ignoresSafeArea())
        .hidesNavigationBar()
        .task { isFieldFocused = true }
        .task(id: model.request) { await model.search() }
    }

    @ViewBuilder private var results: some View {
        switch model.phase {
        case .loading:
            ProgressView()
                .padding(.top, Spacing.xl)
        case .failed:
            failure
        case .loaded(let networks) where networks.isEmpty:
            message("networks.noResults")
        case .loaded(let networks):
            list(networks)
        }
    }

    private func list(_ networks: [ChargingNetwork]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(networks) { network in
                    PickerRow(
                        network: network,
                        mode: model.mode,
                        status: model.status(of: network)
                    ) { model.toggle(network) }
                    if network.id != networks.last?.id {
                        InsetDivider()
                    }
                }
            }
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.lg)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var failure: some View {
        VStack(spacing: Spacing.md) {
            message("networks.loadFailed")
            Button(action: model.retry) {
                Text("common.retry", bundle: .onsarj)
                    .font(Typography.buttonSmall)
                    .foregroundStyle(Theme.onActionPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .frame(minHeight: Spacing.minTapTarget)
                    .background(Theme.actionPrimary, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func message(_ key: LocalizedStringKey) -> some View {
        Text(key, bundle: .onsarj)
            .font(Typography.body)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.top, Spacing.xl)
    }
}
