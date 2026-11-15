/// Eklenebilecek araçların kataloğu: marka → model → varyant.
public protocol VehicleCatalog: Sendable {
    /// Tüm markalar, ada göre sıralı.
    func brands() async throws -> [VehicleBrand]

    /// Markanın modelleri.
    func models(of brandID: VehicleBrand.ID) async throws -> [VehicleModel]

    /// Modelin varyantları.
    func variants(of modelID: VehicleModel.ID) async throws -> [VehicleVariant]
}
