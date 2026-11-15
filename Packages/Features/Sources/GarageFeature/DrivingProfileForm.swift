import Foundation
import OnsarjDomain

/// Profil formunun durumu: ad, tüketim ve hız alanları ile doğrulama.
///
/// Yeni profilde değerler standart profilden gelir, ad boş başlar. Standart profilin adı salt
/// okunurdur. Doğrulama sınırları Domain'dedir.
struct DrivingProfileForm: Equatable {
    /// Düzenlenen profil; yeni profilde `nil`.
    let profile: DrivingProfile?
    private let profiles: [DrivingProfile]
    var name: ValueEditor
    var consumption: ValueEditor
    var maxSpeed: ValueEditor

    init(profile: DrivingProfile?, vehicle: Vehicle, locale: Locale) {
        self.profile = profile
        profiles = vehicle.drivingProfiles
        let values = profile ?? vehicle.standardProfile
        name = ValueEditor(kind: .text, text: profile?.name ?? "", locale: locale)
        consumption = .consumption(values.consumptionKwhPer100Km, locale: locale)
        maxSpeed = .maxSpeed(values.maxSpeedKmh, locale: locale)
    }

    var isNew: Bool {
        profile == nil
    }

    var isNameEditable: Bool {
        profile?.isStandard != true
    }

    var nameIssue: DrivingProfile.NameIssue? {
        DrivingProfile.nameIssue(name.text, among: profiles, editing: profile?.id)
    }

    var hasChanges: Bool {
        isNew || name.hasChanges || consumption.hasChanges || maxSpeed.hasChanges
    }

    var canSave: Bool {
        nameIssue == nil && consumption.isValid && maxSpeed.isValid && hasChanges
    }

    /// Kaydedilecek taslak; form kaydedilemezse `nil`.
    var draft: DrivingProfileDraft? {
        guard canSave, let consumption = consumption.decimalValue, let speed = maxSpeed.integerValue else {
            return nil
        }
        return DrivingProfileDraft(
            id: profile?.id,
            name: isNameEditable ? name.trimmed : profile?.name ?? name.trimmed,
            consumptionKwhPer100Km: consumption,
            maxSpeedKmh: speed
        )
    }
}
