import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Araç ayarları sayfası: görsel, sürüş profili, ayrıntılar, boya rengi ve "Aracı sil".
struct VehicleSettingsPage: View {
    let model: VehicleSettingsModel
    let onEdit: (ValueEditTarget) -> Void
    let onOpen: (VehicleSettingsView.Destination) -> Void
    let onClose: () -> Void

    @Environment(\.locale) private var locale
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        ScrollView {
            switch model.phase {
            case .loading:
                ProgressView().padding(.top, Spacing.xxl)
            case .failed:
                failure
            case .loaded:
                if let vehicle = model.vehicle {
                    content(vehicle)
                }
            }
        }
        .garagePage(Text(verbatim: model.vehicle?.displayName ?? ""), onClose: onClose)
        .alert(
            Text("vehicleSettings.delete.confirm", bundle: .onsarj),
            isPresented: $isDeleteConfirmationPresented
        ) {
            Button(role: .destructive) {
                Task { if await model.deleteVehicle() { onClose() } }
            } label: {
                Text("common.delete", bundle: .onsarj)
            }
            Button(role: .cancel) {
            } label: {
                Text("common.cancel", bundle: .onsarj)
            }
        }
    }

    private func content(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if let url = vehicle.imageURL {
                VehicleImage(url: url)
            }
            profileSection(vehicle)
            detailsSection(vehicle)
            SettingsSection(title: "vehicleSettings.paint") {
                PaintPicker(selected: model.colorHex.flatMap(VehiclePaint.init(hex:))) { paint in
                    Task { await model.selectPaint(paint) }
                }
            }
            deleteButton
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.lg)
    }

    private func profileSection(_ vehicle: Vehicle) -> some View {
        let profile = vehicle.drivingProfiles.first { $0.id == model.activeProfileID } ?? vehicle.activeProfile
        return SettingsSection(title: "vehicleSettings.drivingProfile") {
            editProfilesButton
        } content: {
            profileChips(vehicle, selected: profile.id)
            InsetDivider()
            SettingsRow(
                label: Text("vehicleSettings.consumption", bundle: .onsarj),
                value: Text(verbatim: GarageText.consumption(profile.consumptionKwhPer100Km, locale: locale))
            ) { onEdit(.consumption) }
            InsetDivider()
            SettingsRow(
                label: Text("vehicleSettings.maxSpeed", bundle: .onsarj),
                value: Text(verbatim: GarageText.speed(profile.maxSpeedKmh, locale: locale))
            ) { onEdit(.maxSpeed) }
        }
    }

    private var editProfilesButton: some View {
        Button {
            onOpen(.profiles)
        } label: {
            Text("vehicleSettings.edit", bundle: .onsarj)
                .font(Typography.buttonSmall)
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: Spacing.minTapTarget, minHeight: Spacing.minTapTarget, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Her profil bir çip; etkin olan dolgulu. Dokununca anında etkin olur.
    private func profileChips(_ vehicle: Vehicle, selected: DrivingProfile.ID) -> some View {
        WrappingHStack(spacing: Spacing.sm) {
            ForEach(vehicle.drivingProfiles) { item in
                SelectableChip(Text(verbatim: item.name), isSelected: item.id == selected) {
                    Task { await model.selectProfile(item.id) }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailsSection(_ vehicle: Vehicle) -> some View {
        SettingsSection(title: "vehicleSettings.details") {
            SettingsRow(
                label: Text("vehicleSettings.name", bundle: .onsarj),
                value: Text(verbatim: vehicle.nickname ?? vehicle.displayName)
            ) { onEdit(.nickname) }
            InsetDivider()
            SettingsRow(
                label: Text("vehicleSettings.vehicle", bundle: .onsarj),
                value: Text(verbatim: GarageText.vehicleDescription(vehicle))
            )
            InsetDivider()
            SettingsRow(
                label: Text("vehicleSettings.connectors", bundle: .onsarj),
                value: Text(verbatim: GarageText.connectors(model.connectors))
            ) { onOpen(.connectors) }
            InsetDivider()
            SettingsRow(
                label: Text("vehicleSettings.batteryDegradation", bundle: .onsarj),
                value: Text(verbatim: GarageText.degradation(vehicle.batteryDegradationPercent, locale: locale))
            ) { onEdit(.batteryDegradation) }
        }
    }

    private var deleteButton: some View {
        Button {
            isDeleteConfirmationPresented = true
        } label: {
            Text("vehicleSettings.delete", bundle: .onsarj)
                .font(Typography.button)
                .foregroundStyle(Theme.textError)
                .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var failure: some View {
        VStack(spacing: Spacing.md) {
            Text("vehicleSettings.loadFailed", bundle: .onsarj)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton("common.retry", bundle: .onsarj) {
                Task { await model.load() }
            }
        }
        .padding(Spacing.screenMargin)
        .padding(.top, Spacing.xl)
    }
}

/// Aracın görseli. Yüklenemezse alan hiç çizilmez; büyük yazıda küçülür.
private struct VehicleImage: View {
    let url: URL

    /// Görselin sayfa genişliğine oranı; büyük yazıda içerik için yer açılır.
    private static let regularWidthRatio = 0.75
    private static let largeTypeWidthRatio = 0.45

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .containerRelativeFrame(.horizontal) { width, _ in
                        width * (dynamicTypeSize >= .xxLarge ? Self.largeTypeWidthRatio : Self.regularWidthRatio)
                    }
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}
