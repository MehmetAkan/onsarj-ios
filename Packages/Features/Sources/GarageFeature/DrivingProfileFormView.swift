import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Profil formu: ad, referans tüketim ve en yüksek hız. Yeni profil veya mevcut profilin düzenlenmesi.
///
/// "Kaydet" değişiklik yoksa veya değerler geçersizse pasiftir. Standart olmayan profilde altta
/// "Profili sil" vardır. Kayıt veya silme başarılıysa form kapanır; başarısızsa açık kalır ve kök
/// görünüm "Değişiklik kaydedilemedi" bildirir.
struct DrivingProfileFormView: View {
    let model: VehicleSettingsModel
    let onDone: () -> Void
    let onClose: () -> Void

    @State private var form: DrivingProfileForm
    @State private var isSaving = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isConsumptionFocused: Bool
    @FocusState private var isMaxSpeedFocused: Bool

    /// - Parameters:
    ///   - vehicle: Profilin aracı; yeni profilin değerleri standart profilinden gelir.
    ///   - profile: Düzenlenen profil; yeni profilde `nil`.
    init(
        model: VehicleSettingsModel,
        vehicle: Vehicle,
        profile: DrivingProfile?,
        locale: Locale = .current,
        onDone: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.onDone = onDone
        self.onClose = onClose
        _form = State(initialValue: DrivingProfileForm(profile: profile, vehicle: vehicle, locale: locale))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                nameField
                labeled("vehicleSettings.consumption") {
                    ValueInputField(
                        label: Text("vehicleSettings.consumption", bundle: .onsarj),
                        editor: $form.consumption,
                        unitKey: "vehicleSettings.unit.consumption",
                        errorText: GarageText.rangeError(form.consumption),
                        isFocused: $isConsumptionFocused
                    )
                }
                labeled("vehicleSettings.maxSpeed") {
                    ValueInputField(
                        label: Text("vehicleSettings.maxSpeed", bundle: .onsarj),
                        editor: $form.maxSpeed,
                        unitKey: "vehicleSettings.unit.speed",
                        errorText: GarageText.rangeError(form.maxSpeed),
                        isFocused: $isMaxSpeedFocused
                    )
                }
                if let profile = form.profile, !profile.isStandard {
                    deleteButton(profile)
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton("common.save", bundle: .onsarj, action: save)
                .disabled(!form.canSave || isSaving)
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.bottom, Spacing.md)
        }
        .garagePage(title, onBack: onDone, onClose: onClose)
    }

    private var title: Text {
        if let profile = form.profile {
            Text(verbatim: profile.name)
        } else {
            Text("drivingProfile.new", bundle: .onsarj)
        }
    }

    @ViewBuilder private var nameField: some View {
        labeled("vehicleSettings.name") {
            if form.isNameEditable {
                ValueInputField(
                    label: Text("drivingProfile.namePlaceholder", bundle: .onsarj),
                    editor: $form.name,
                    unitKey: nil,
                    errorText: nameError,
                    isFocused: $isNameFocused
                )
            } else {
                Text(verbatim: form.profile?.name ?? "")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget, alignment: .leading)
                    .background(Theme.backgroundSubtle, in: RoundedRectangle(cornerRadius: Radius.field))
            }
        }
    }

    private var nameError: String? {
        switch form.nameIssue {
        case .tooLong:
            let format = GarageText.localized("drivingProfile.error.nameTooLong")
            return String.localizedStringWithFormat(format, DrivingProfile.nameMaxLength)
        case .duplicate:
            return GarageText.localized("drivingProfile.error.nameTaken")
        case .empty, nil:
            return nil
        }
    }

    private func labeled(_ key: LocalizedStringKey, @ViewBuilder field: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(key, bundle: .onsarj)
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
            field()
        }
    }

    private func deleteButton(_ profile: DrivingProfile) -> some View {
        Button {
            Task { if await model.deleteProfile(profile.id) { onDone() } }
        } label: {
            Text("drivingProfile.delete", bundle: .onsarj)
                .font(Typography.button)
                .foregroundStyle(Theme.textError)
                .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard let draft = form.draft else { return }
        isSaving = true
        Task {
            if await model.saveProfile(draft) {
                onDone()
            }
            isSaving = false
        }
    }
}
