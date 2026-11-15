import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Plan seçenekleri sayfası: şarj duraklamaları, rotadan kaçınma ve şarj ağları özeti.
///
/// Varış şarj durumu bu sayfada yoktur; değer ana sayfadaki araç kartındadır.
struct PlanOptionsPage: View {
    let model: RoutePreferencesModel
    let onEditNetworks: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            if model.isLoaded {
                content
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ModalHeader("plan.title") { ModalCloseButton(action: onClose) }
                .background(Theme.backgroundSheet)
        }
        .background(Theme.backgroundSheet.ignoresSafeArea())
        .hidesNavigationBar()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            section("plan.chargeStops") {
                SegmentedControl(
                    selection: Binding(get: { model.preferences.chargeStops }, set: model.setChargeStops),
                    segments: ChargeStopStrategy.allCases.map { .init($0, title: $0.titleKey) },
                    bundle: .onsarj
                )
            }
            section("plan.avoid") {
                AvoidanceChips(selected: model.preferences.avoid, onToggle: model.toggle)
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                networksHeader
                NetworkSummary(preferences: model.preferences, name: model.name(for:))
            }
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.lg)
    }

    private func section(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle(titleKey)
            content()
        }
    }

    private func sectionTitle(_ titleKey: LocalizedStringKey) -> some View {
        Text(titleKey, bundle: .onsarj)
            .font(Typography.headline)
            .foregroundStyle(Theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var networksHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            sectionTitle("plan.networks")
            Spacer(minLength: Spacing.sm)
            Button(action: onEditNetworks) {
                Text("plan.networks.edit", bundle: .onsarj)
                    .font(Typography.buttonSmall)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(minWidth: Spacing.minTapTarget, minHeight: Spacing.minTapTarget, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
