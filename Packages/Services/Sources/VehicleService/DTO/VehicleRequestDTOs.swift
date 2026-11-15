import OnsarjDomain

/// `PATCH /vehicles/{id}` gövdesi. Yalnızca dolu alanlar JSON'a yazılır ve yalnızca onlar değişir.
/// `nickname` boş dizgeyse takma ad kaldırılır.
struct UpdateVehicleRequestDTO: Encodable, Equatable {
    var nickname: String?
    var connectors: [String]?
    var batteryHealthPercent: Int?
    var colorHex: String?
    var activeProfileId: String?

    init(update: VehicleUpdate) {
        nickname = update.nickname
        connectors = update.connectors?.map(\.rawValue)
        batteryHealthPercent = update.batteryHealthPercent
        colorHex = update.colorHex
    }

    init(activeProfileID: DrivingProfile.ID) {
        activeProfileId = activeProfileID.rawValue
    }
}

/// `POST /vehicles/{id}/driving-profiles` ve `PUT /vehicles/{id}/driving-profiles/{profileId}` gövdesi.
struct DrivingProfileRequestDTO: Encodable, Equatable {
    let name: String
    let consumptionKwhPer100Km: Double
    let maxSpeedKmh: Int

    init(draft: DrivingProfileDraft) {
        name = draft.name
        consumptionKwhPer100Km = draft.consumptionKwhPer100Km
        maxSpeedKmh = draft.maxSpeedKmh
    }
}
