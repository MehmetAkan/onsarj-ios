#if DEBUG
import DesignSystem
import SwiftUI

/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu tema, dolu liste
/// (üçüncü kart fotoğraflı). Ayrıca boş, hata, yükleniyor ve konum kapalı notu en zor durumda, SE + `xxxLarge`,
/// iki temada.
struct StationListViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let schemes: [ColorScheme] = [.light, .dark]
    /// Durum önizlemesi: ad, depo içeriği ve listenin merkezi.
    private struct StatePreview {
        let name: String
        let content: PreviewStationList.Content
        let origin: StationListOrigin
    }

    private static let states = [
        StatePreview(name: "boş", content: .empty, origin: .userLocation(PreviewStationList.origin)),
        StatePreview(name: "hata", content: .failure, origin: .userLocation(PreviewStationList.origin)),
        StatePreview(name: "yükleniyor", content: .loading, origin: .userLocation(PreviewStationList.origin)),
        StatePreview(name: "konum kapalı", content: .full, origin: .mapCenter(PreviewStationList.origin)),
    ]

    static var previews: some View {
        Group {
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    ForEach(schemes, id: \.self) { scheme in
                        screen(.full, origin: .userLocation(PreviewStationList.origin))
                            .environment(\.dynamicTypeSize, typeSize)
                            .preferredColorScheme(scheme)
                            .previewDevice(PreviewDevice(rawValue: device))
                            .previewDisplayName("\(device) · \(typeSize) · \(scheme == .dark ? "koyu" : "açık")")
                    }
                }
            }
            ForEach(states, id: \.name) { state in
                ForEach(schemes, id: \.self) { scheme in
                    screen(state.content, origin: state.origin)
                        .environment(\.dynamicTypeSize, .xxxLarge)
                        .preferredColorScheme(scheme)
                        .previewDevice(PreviewDevice(rawValue: devices[0]))
                        .previewDisplayName("\(state.name) · SE · xxxLarge · \(scheme == .dark ? "koyu" : "açık")")
                }
            }
        }
    }

    @MainActor
    private static func screen(_ content: PreviewStationList.Content, origin: StationListOrigin) -> some View {
        let repository = PreviewStationRepository(content: .rich, list: content)
        return StationListView(
            model: StationListModel(
                origin: origin, filters: StationListFilters(), repository: repository,
                vehicleRepository: PreviewNoVehicleRepository(), networkCatalog: PreviewNetworkCatalog()),
            stationRepository: repository)
    }
}
#endif
