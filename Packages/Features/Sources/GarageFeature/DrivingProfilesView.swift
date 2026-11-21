import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Sürüş profilleri listesi. Satıra dokunmak profil formunu açar; standart dışındaki profiller sola
/// kaydırılınca onaysız silinir. En altta "+ Profil ekle".
struct DrivingProfilesView: View {
    let model: VehicleSettingsModel
    /// Profil formunu açar; `nil` yeni profil.
    let onOpen: (DrivingProfile.ID?) -> Void
    let onBack: () -> Void
    let onClose: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        List {
            Section {
                ForEach(model.vehicle?.drivingProfiles ?? []) { profile in
                    profileRow(profile)
                }
                AddRowButton(Text("drivingProfile.add", bundle: .onsarj)) { onOpen(nil) }
                    .listRowInsets(EdgeInsets())
            }
            .listRowBackground(Theme.backgroundCard)
            .listRowSeparatorTint(Theme.borderSubtle)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, Spacing.screenMargin, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, Spacing.minTapTarget)
        .garagePage(Text("drivingProfile.title", bundle: .onsarj), onBack: onBack, onClose: onClose)
    }

    private func profileRow(_ profile: DrivingProfile) -> some View {
        Button {
            onOpen(profile.id)
        } label: {
            HStack(spacing: Spacing.sm) {
                profileLabel(profile)
                    .frame(maxWidth: .infinity, alignment: .leading)
                AppIcon.disclosure
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !profile.isStandard {
                Button(role: .destructive) {
                    Task { await model.deleteProfile(profile.id) }
                } label: {
                    Text("common.delete", bundle: .onsarj)
                }
            }
        }
    }

    private func profileLabel(_ profile: DrivingProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Text(verbatim: profile.name)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                if profile.isStandard {
                    StandardTag()
                }
            }
            Text(verbatim: GarageText.profileSummary(profile, locale: locale))
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

/// Standart profilin yanındaki küçük etiket.
struct StandardTag: View {
    var body: some View {
        Text("drivingProfile.standard", bundle: .onsarj)
            .font(Typography.captionSmall)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs / 2)
            .background(Theme.backgroundSubtle, in: Capsule())
    }
}
