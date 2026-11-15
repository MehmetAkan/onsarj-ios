/// `GET /vehicle-catalog/brands` yanıtı (`Docs/Backend/vehicle-catalog.md`).
struct VehicleBrandListDTO: Decodable {
    let brands: [VehicleBrandDTO]
}

struct VehicleBrandDTO: Decodable {
    let id: String?
    let name: String?
    let logoUrl: String?
    let modelCount: Int?
}

/// `GET /vehicle-catalog/brands/{brandId}/models` yanıtı.
struct VehicleModelListDTO: Decodable {
    let models: [VehicleModelDTO]
}

struct VehicleModelDTO: Decodable {
    let id: String?
    let brandId: String?
    let name: String?
    let bodyType: String?
}

/// `GET /vehicle-catalog/models/{modelId}/variants` yanıtı.
struct VehicleVariantListDTO: Decodable {
    let variants: [VehicleVariantDTO]
}

struct VehicleVariantDTO: Decodable {
    let id: String?
    let modelId: String?
    let name: String?
    let modelYear: Int?
    let batteryCapacityKwh: Double?
    let connectors: [String]?
    let maxAcPowerKw: Double?
    let maxDcPowerKw: Double?
    let referenceConsumptionKwhPer100Km: Double?
    let imageUrl: String?
}
