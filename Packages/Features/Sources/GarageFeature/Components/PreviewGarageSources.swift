#if DEBUG
import DesignSystem
import Foundation
import OnsarjDomain
import SwiftUI

/// Önizleme için araç deposu: verilen aracı döner, yazma işlemlerini kabul etmez (CLAUDE.md 2.3).
struct PreviewGarageRepository: VehicleRepository {
    let vehicle: Vehicle

    func vehicles() async throws -> [Vehicle] { [vehicle] }
    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle { vehicle }
    func deleteVehicle(_ id: Vehicle.ID) async throws {}
    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle { vehicle }
    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle { vehicle }
    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle { vehicle }

    static let standard = DrivingProfile(
        id: DrivingProfile.ID("std"), name: "Standart", consumptionKwhPer100Km: 17.8, maxSpeedKmh: 120, isStandard: true
    )
    static let highway = DrivingProfile(
        id: DrivingProfile.ID("hwy"), name: "Otoyol", consumptionKwhPer100Km: 20.5, maxSpeedKmh: 130, isStandard: false)

    /// Görselli araç. Adres önizlemede yüklenmezse alan gizlenir (görselsiz hal).
    static func dolphin(imageURL: URL?) -> Vehicle {
        Vehicle(
            id: Vehicle.ID("preview_dolphin"),
            make: "BYD",
            model: "Dolphin",
            variant: "Standart",
            modelYear: 2023,
            nickname: nil,
            batteryCapacityKwh: 60.5,
            connectors: [.type2, .ccs2],
            maxAcPowerKw: 11,
            maxDcPowerKw: 88,
            colorHex: VehiclePaint.white.hex,
            bodyType: .hatchback,
            imageURL: imageURL,
            batteryHealthPercent: 95,
            isDefault: true,
            drivingProfiles: [standard, highway],
            activeProfileID: standard.id
        )
    }
}

/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu.
struct GaragePreviewMatrix<Content: View>: View {
    private static var devices: [String] { ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"] }
    private static var typeSizes: [DynamicTypeSize] { [.large, .xxxLarge] }
    private static var schemes: [ColorScheme] { [.light, .dark] }

    let name: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ForEach(Self.devices, id: \.self) { device in
            ForEach(Self.typeSizes, id: \.self) { typeSize in
                ForEach(Self.schemes, id: \.self) { scheme in
                    content()
                        .environment(\.dynamicTypeSize, typeSize)
                        .preferredColorScheme(scheme)
                        .previewDevice(PreviewDevice(rawValue: device))
                        .previewDisplayName("\(name) · \(device) · \(typeSize) · \(scheme == .dark ? "koyu" : "açık")")
                }
            }
        }
    }
}

/// Alt sayfaları, modelin yüklenmiş haliyle gösterir.
private struct GaragePageHost<Content: View>: View {
    @State private var model = VehicleSettingsModel(
        repository: PreviewGarageRepository(vehicle: PreviewGarageRepository.dolphin(imageURL: nil)),
        vehicleID: Vehicle.ID("preview_dolphin")
    )
    @ViewBuilder let content: (VehicleSettingsModel) -> Content

    var body: some View {
        NavigationStack { content(model) }
            .task { await model.load() }
    }
}

struct VehicleSettingsViewPreviews: PreviewProvider {
    static var previews: some View {
        ForEach([true, false], id: \.self) { hasImage in
            GaragePreviewMatrix(name: hasImage ? "Görselli" : "Görselsiz") {
                let url = hasImage ? URL(string: "https://example.com/dolphin.png") : nil
                let vehicle = PreviewGarageRepository.dolphin(imageURL: url)
                VehicleSettingsView(
                    repository: PreviewGarageRepository(vehicle: vehicle),
                    vehicleID: vehicle.id,
                    onClose: {}
                )
            }
        }
    }
}

struct DrivingProfilesViewPreviews: PreviewProvider {
    static var previews: some View {
        GaragePreviewMatrix(name: "Profiller") {
            GaragePageHost { model in
                DrivingProfilesView(model: model, onOpen: { _ in }, onBack: {}, onClose: {})
            }
        }
    }
}

struct DrivingProfileFormViewPreviews: PreviewProvider {
    private static let cases: [(String, DrivingProfile?)] = [
        ("Yeni", nil), ("Standart", PreviewGarageRepository.standard), ("Diğer", PreviewGarageRepository.highway),
    ]

    static var previews: some View {
        ForEach(cases, id: \.0) { name, profile in
            GaragePreviewMatrix(name: "Form · \(name)") {
                GaragePageHost { model in
                    DrivingProfileFormView(
                        model: model,
                        vehicle: PreviewGarageRepository.dolphin(imageURL: nil),
                        profile: profile,
                        onDone: {},
                        onClose: {}
                    )
                }
            }
        }
    }
}

struct ValueEditorSheetPreviews: PreviewProvider {
    static var previews: some View {
        ForEach(["17,8", "60"], id: \.self) { text in
            GaragePreviewMatrix(name: text == "60" ? "Değer · geçersiz" : "Değer · geçerli") {
                ValueEditorPreviewHost(text: text)
            }
        }
    }
}

/// Değer modalını, alana hazır yazılmış bir değerle gösterir.
private struct ValueEditorPreviewHost: View {
    let text: String

    var body: some View {
        Theme.backgroundPrimary
            .sheet(isPresented: .constant(true)) {
                ValueEditorSheet(
                    target: .consumption,
                    vehicle: PreviewGarageRepository.dolphin(imageURL: nil),
                    initialText: text,
                    onSave: { _ in }
                )
            }
    }
}
#endif
