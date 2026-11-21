import DesignSystem
import OnsarjDomain
import SwiftUI

/// Listenin üstündeki yatay kaydırılan süzgeç çipleri: Sırala, Hız, Soket, Ağlar. Her çip sistemin açılır
/// menüsüdür (2.9: iOS 17–18'de klasik menü, iOS 26'da cam görünümlü; içerik ve onay işaretleri aynı).
/// Varsayılan dışında bir değer seçiliyse çip dolgulu görünür ve değeri yazar.
struct StationFilterBar: View {
    @Bindable var model: StationListModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                sortMenu
                speedMenu
                stallsMenu
                networksMenu
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
    }

    private var sortMenu: some View {
        let sort = model.filters.sort
        return Menu {
            Picker(selection: $model.filters.sort) {
                ForEach(StationSort.allCases, id: \.self) { option in
                    Text(StationDetailText.localized(option.nameKey)).tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            chip(
                nameKey: "stationList.sort", selectedKey: "stationList.sort.selected",
                value: sort == .distance ? nil : StationDetailText.localized(sort.nameKey),
                accessibilityValue: StationDetailText.localized(sort.nameKey))
        }
    }

    private var speedMenu: some View {
        let speed = model.filters.minimumSpeed
        return Menu {
            Picker(selection: $model.filters.minimumSpeed) {
                ForEach(StationListFilters.speedOptions, id: \.self) { option in
                    Text(StationListText.speedOption(option)).tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            chip(
                nameKey: "stationList.speed", selectedKey: "stationList.speed.selected",
                value: speed.map { StationListText.speedOption($0) },
                accessibilityValue: StationListText.speedOption(speed))
        }
    }

    private var stallsMenu: some View {
        let stalls = model.filters.minimumStalls
        return Menu {
            Picker(selection: $model.filters.minimumStalls) {
                ForEach(StationListFilters.stallOptions, id: \.self) { option in
                    Text(StationListText.stallOption(option)).tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            chip(
                nameKey: "stationList.stalls", selectedKey: "stationList.stalls.selected",
                value: stalls.map { StationListText.stallOption($0) },
                accessibilityValue: StationListText.stallOption(stalls))
        }
    }

    /// Çoklu seçim: menü her seçimde kapanmaz. "Tümü" seçimi temizler.
    private var networksMenu: some View {
        let count = model.filters.networkIDs.count
        return Menu {
            Toggle(isOn: allNetworks) {
                Text(StationDetailText.localized("common.all"))
            }
            Divider()
            ForEach(model.networks, id: \.id) { network in
                Toggle(isOn: networkBinding(network.id)) {
                    Text(verbatim: network.name)
                }
            }
        } label: {
            chip(
                title: count == 0
                    ? StationDetailText.localized("stationList.networks")
                    : StationDetailText.format("stationList.networks.selected", count),
                isSelected: count > 0,
                label: StationDetailText.localized("stationList.networks"),
                value: count == 0
                    ? StationDetailText.localized("common.all")
                    : StationDetailText.format("stationList.networks.selected", count))
        }
        .menuActionDismissBehavior(.disabled)
    }

    private var allNetworks: Binding<Bool> {
        Binding(
            get: { model.filters.networkIDs.isEmpty },
            set: { isOn in if isOn { model.filters.networkIDs = [] } }
        )
    }

    private func networkBinding(_ id: ChargingNetwork.ID) -> Binding<Bool> {
        Binding(
            get: { model.isNetworkSelected(id) },
            set: { model.setNetwork(id, selected: $0) }
        )
    }

    /// Tek seçimli çip: varsayılanda adı ("Sırala"), değilse "Ad: değer" ("Sırala: Güç").
    private func chip(nameKey: String, selectedKey: String, value: String?, accessibilityValue: String) -> some View {
        chip(
            title: StationListText.chipTitle(nameKey: nameKey, selectedKey: selectedKey, value: value),
            isSelected: value != nil, label: StationDetailText.localized(nameKey), value: accessibilityValue)
    }

    /// Çip görünümü (`selectableChipSurface`) ve sağda aşağı ok. VoiceOver adı ve seçili değeri okur.
    private func chip(title: String, isSelected: Bool, label: String, value: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .lineLimit(1)
            AppIcon.dropdown
                .font(Typography.captionSmall)
        }
        .selectableChipSurface(isSelected: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
