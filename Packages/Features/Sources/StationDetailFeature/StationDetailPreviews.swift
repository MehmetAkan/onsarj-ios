#if DEBUG
import DesignSystem
import SwiftUI

/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu tema, zengin detayla.
/// Ayrıca diğer haller (kısıtlı erişim, tarifesiz/olanaksız/puansız, yükleniyor, hata) en zor durumda,
/// SE + `xxxLarge`, iki temada.
struct StationDetailViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let schemes: [ColorScheme] = [.light, .dark]
    private static let states: [(String, PreviewStationDetails.Content)] = [
        ("kısıtlı", .restricted), ("sade", .bare), ("yükleniyor", .loading), ("hata", .failure),
    ]

    static var previews: some View {
        Group {
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    ForEach(schemes, id: \.self) { scheme in
                        screen(.rich)
                            .environment(\.dynamicTypeSize, typeSize)
                            .preferredColorScheme(scheme)
                            .previewDevice(PreviewDevice(rawValue: device))
                            .previewDisplayName("\(device) · \(typeSize) · \(scheme == .dark ? "koyu" : "açık")")
                    }
                }
            }
            ForEach(states, id: \.0) { name, content in
                ForEach(schemes, id: \.self) { scheme in
                    screen(content)
                        .environment(\.dynamicTypeSize, .xxxLarge)
                        .preferredColorScheme(scheme)
                        .previewDevice(PreviewDevice(rawValue: devices[0]))
                        .previewDisplayName("\(name) · SE · xxxLarge · \(scheme == .dark ? "koyu" : "açık")")
                }
            }
        }
    }

    @MainActor
    private static func screen(_ content: PreviewStationDetails.Content) -> some View {
        StationDetailView(
            model: StationDetailModel(
                station: PreviewStationDetails.station,
                repository: PreviewStationRepository(content: content),
                copyToPasteboard: { _ in }))
    }
}
#endif
