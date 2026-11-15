import SwiftUI

/// Birbirini dışlayan birkaç seçenekten birini seçtiren parçalı denetim.
///
/// Sistem `Picker(.segmented)` yerine kullanılır (CLAUDE.md 2.9): seçili parça tasarımda belirgin
/// dolguludur (`Theme.actionPrimary` üzerinde `Theme.onActionPrimary`). Sistem denetiminde seçili
/// parçanın dolgusu ve yazı tipi yalnızca `UISegmentedControl.appearance()` ile, uygulamanın tamamında
/// değiştirilebilir; iOS 26'da görünümü de sürümden sürüme değişir ve büyük yazıda metin sarmaz.
///
/// Parçalar eşit genişliktedir; uzun etiket büyük yazıda alt satıra sarar ve tüm parçalar aynı
/// yükseklikte kalır. Her parça bir düğmedir; VoiceOver seçili parçayı "seçili" diye okur.
///
/// ```swift
/// SegmentedControl(selection: $strategy, segments: [
///     .init(.optimal, title: "plan.chargeStops.optimal"),
///     .init(.fewer, title: "plan.chargeStops.fewer"),
/// ], bundle: .onsarj)
/// ```
public struct SegmentedControl<Value: Hashable>: View {
    /// Tek bir parça: değeri ve etiketinin String Catalog anahtarı.
    public struct Segment {
        let value: Value
        let titleKey: LocalizedStringKey

        public init(_ value: Value, title titleKey: LocalizedStringKey) {
            self.value = value
            self.titleKey = titleKey
        }
    }

    @Binding private var selection: Value
    private let segments: [Segment]
    private let bundle: Bundle?

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - selection: Seçili değer.
    ///   - segments: Soldan sağa parçalar.
    ///   - bundle: Etiketlerin bulunduğu paket; özellik modülleri `.onsarj` verir.
    public init(selection: Binding<Value>, segments: [Segment], bundle: Bundle? = nil) {
        _selection = selection
        self.segments = segments
        self.bundle = bundle
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(segments.indices, id: \.self) { index in
                segmentButton(segments[index])
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(Spacing.xs)
        .background(Theme.backgroundCard, in: RoundedRectangle(cornerRadius: Radius.field))
        .animation(reduceMotion ? nil : .snappy, value: selection)
        .accessibilityElement(children: .contain)
    }

    private func segmentButton(_ segment: Segment) -> some View {
        let isSelected = segment.value == selection
        return Button {
            selection = segment.value
        } label: {
            Text(segment.titleKey, bundle: bundle)
                .font(Typography.buttonSmall)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? Theme.onActionPrimary : Theme.textPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: Spacing.minTapTarget - 2 * Spacing.xs)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Radius.chip)
                            .fill(Theme.actionPrimary)
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu.
struct SegmentedControlPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let schemes: [ColorScheme] = [.light, .dark]

    static var previews: some View {
        ForEach(devices, id: \.self) { device in
            ForEach(typeSizes, id: \.self) { typeSize in
                ForEach(schemes, id: \.self) { scheme in
                    Host()
                        .environment(\.dynamicTypeSize, typeSize)
                        .preferredColorScheme(scheme)
                        .previewDevice(PreviewDevice(rawValue: device))
                        .previewDisplayName("\(device) · \(typeSize) · \(scheme == .dark ? "koyu" : "açık")")
                }
            }
        }
    }

    private struct Host: View {
        @State private var selection = 0

        var body: some View {
            SegmentedControl(
                selection: $selection,
                segments: [.init(0, title: "Optimal"), .init(1, title: "Fewer"), .init(2, title: "Fewest")]
            )
            .padding(Spacing.screenMargin)
            .frame(maxHeight: .infinity)
            .background(Theme.backgroundSheet)
        }
    }
}
#endif
