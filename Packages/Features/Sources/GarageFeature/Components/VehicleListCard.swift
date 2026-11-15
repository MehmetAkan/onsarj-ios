import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// "Araçlarınız"daki araç kartı: solda tek satır "Marka Model Yıl Kapasite" (takma ad varsa o), sağda
/// küçük görsel. Etkin aracın çevresinde belirgin çerçeve; VoiceOver "Seçili araç" okur.
struct VehicleListCard: View {
    let vehicle: Vehicle
    let isActive: Bool
    let isSelecting: Bool
    let locale: Locale
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(verbatim: GarageText.vehicleListTitle(vehicle, locale: locale))
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelecting {
                    ProgressView()
                } else if let url = vehicle.imageURL {
                    VehicleThumbnail(url: url)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: Spacing.minTapTarget)
            .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: Radius.card)
                        .strokeBorder(Theme.textPrimary, lineWidth: Spacing.xs / 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityValue(isActive ? Text("garage.selected", bundle: .onsarj) : Text(verbatim: ""))
    }
}
