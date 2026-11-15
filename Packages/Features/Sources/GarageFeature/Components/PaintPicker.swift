import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Boya rengi seçici: 8 kapsül, iki satır; seçili olanın çevresinde halka.
///
/// Aracın rengi hazır boyalardan biri değilse hiçbiri seçili görünmez. VoiceOver renk adını ve
/// seçili olduğunu okur.
struct PaintPicker: View {
    let selected: VehiclePaint?
    let onSelect: (VehiclePaint) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(VehiclePaint.allCases, id: \.self) { paint in
                swatch(paint)
            }
        }
        .padding(Spacing.lg)
    }

    private func swatch(_ paint: VehiclePaint) -> some View {
        let isSelected = paint == selected
        return Button {
            onSelect(paint)
        } label: {
            Capsule()
                .fill(paint.color)
                .overlay { Capsule().strokeBorder(Theme.borderSubtle) }
                .padding(Spacing.xs)
                .overlay {
                    if isSelected {
                        Capsule().strokeBorder(Theme.textPrimary, lineWidth: Spacing.xs / 2)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(paint.nameKey, bundle: .onsarj))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
