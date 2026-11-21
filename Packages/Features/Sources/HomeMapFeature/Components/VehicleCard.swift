import DesignSystem
import Localization
import OnsarjDomain
import SwiftUI

/// Ana sayfadaki araç kartı: etkin araç, batarya yüzdesi, tahmini menzil ve yüzde çubuğu.
///
/// Haller (`VehicleCardModel.State`):
/// - **Yükleniyor:** kartın alanı korunur, içerik görünmez.
/// - **Araç var:** üstte araç adı (dokununca araç değiştirme) ve ayarlar; ortada yüzde, menzil ve
///   araç görseli; altta çubuk. Görsel yoksa, yüklenemezse veya yazı boyutu `xxxLarge` ve
///   üstündeyse görsel alanı hiç çizilmez, yazılar tüm genişliği kullanır.
/// - **Araç yok:** boş garaj görseli soluk ve bulanık (`Effects.Muted`), üstünde "Araç ekle".
/// - **Hata:** kısa açıklama ve "Tekrar dene".
///
/// Tüm haller aynı yüksekliği korur: kart, dolu halin satırlarıyla aynı yazı tiplerinden oluşan
/// görünmez bir ölçü iskeletinin (`sizer`) boyutunu alır; böylece haller arasında yer atlamaz ve
/// yükseklik yazı boyutuyla birlikte değişir.
///
/// Kart ekran açmaz; kullanıcının isteği kapanışlarla dışarı bildirilir.
struct VehicleCard: View {
    let model: VehicleCardModel
    let onSwitchVehicle: () -> Void
    let onVehicleSettings: (Vehicle.ID) -> Void
    let onAddVehicle: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    /// Yüzde ve menzil bloğunun yüksekliği; araç görseli bu yüksekliğe sığdırılır.
    @State private var readoutHeight: CGFloat = 0

    var body: some View {
        content
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.backgroundCard, in: cardShape)
            .clipShape(cardShape)
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .loading:
            sizer
        case .loaded(let vehicle, let level):
            ZStack(alignment: .topLeading) {
                sizer
                loaded(vehicle, level: level)
            }
        case .empty:
            sizer.overlay { empty }
        case .failed:
            sizer.overlay { failed }
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.card)
    }

    // MARK: - Ölçü iskeleti

    /// Dolu halin satır yapısı, görünmez. Satırlar boş bir boşluk karakteriyle ölçülür; metin göstermez.
    private var sizer: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Self.measuringLine(Typography.headline)
                Self.measuringLine(Typography.secondary)
            }
            .frame(minHeight: Spacing.minTapTarget)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Self.measuringLine(Typography.numericLarge)
                Self.measuringLine(Typography.numeric)
            }
            Color.clear.frame(height: Spacing.minTapTarget)
        }
        .frame(maxWidth: .infinity)
        .hidden()
        .accessibilityHidden(true)
    }

    private static func measuringLine(_ font: Font) -> some View {
        Text(verbatim: " ").font(font)
    }

    // MARK: - Araç var

    private func loaded(_ vehicle: Vehicle, level: BatteryLevel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header(vehicle)
            HStack(alignment: .center, spacing: Spacing.md) {
                readout(vehicle, level: level)
                if dynamicTypeSize < .xxxLarge, let url = vehicle.imageURL {
                    vehicleImage(url)
                }
            }
            BatteryLevelSlider(level: level, onChange: model.updateLevel) {
                Task { await model.commitLevel() }
            }
        }
    }

    private func header(_ vehicle: Vehicle) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            switchVehicleButton(vehicle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onVehicleSettings(vehicle.id)
            } label: {
                AppIcon.settings
                    .font(Typography.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("vehicleCard.settings", bundle: .onsarj))
        }
    }

    /// Araç adının altındaki satır: etkin sürüş profilinin adı. Donanım paketi araç ayarlarında görünür.
    static func subtitle(for vehicle: Vehicle) -> String {
        vehicle.activeProfile.name
    }

    /// Araç adı, aşağı ok ve hemen altındaki etkin profil adı tek düğmedir; iki satır birlikte dokunma
    /// alanını sağlar.
    private func switchVehicleButton(_ vehicle: Vehicle) -> some View {
        Button(action: onSwitchVehicle) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Text(vehicle.displayName)
                        .font(Typography.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    AppIcon.dropdown
                        .font(Typography.secondary)
                        .foregroundStyle(Theme.textSecondary)
                }
                Text(Self.subtitle(for: vehicle))
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: Spacing.minTapTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("vehicleCard.switchVehicle", bundle: .onsarj))
    }

    private func readout(_ vehicle: Vehicle, level: BatteryLevel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(percentText(level))
                .font(Typography.numericLarge)
                .foregroundStyle(Theme.textPrimary)
            Text(rangeText(vehicle, level: level))
                .font(Typography.numeric)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            readoutHeight = height
        }
        .accessibilityElement(children: .combine)
    }

    /// Görsel yalnızca yüklendiğinde yer kaplar; yüklenirken ve başarısız olunca alan hiç çizilmez.
    private func vehicleImage(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: readoutHeight)
            }
        }
        .accessibilityHidden(true)
    }

    /// Yüzde, yerel biçimde ("30%", Türkçede "%30"); yüzde işareti rakamlardan küçük.
    private func percentText(_ level: BatteryLevel) -> AttributedString {
        var text = level.percent.formatted(.percent.locale(locale).attributed)
        let symbolRanges = text.runs.filter { $0.numberSymbol == .percent }.map(\.range)
        for range in symbolRanges {
            text[range].font = Typography.sectionTitle
        }
        return text
    }

    private func rangeText(_ vehicle: Vehicle, level: BatteryLevel) -> String {
        let format = String(localized: "vehicleCard.range", bundle: .onsarj)
        return String.localizedStringWithFormat(format, vehicle.estimatedRangeKm(at: level))
    }

    // MARK: - Araç yok, hata

    private var empty: some View {
        ZStack {
            Illustration.vehicleEmptyState
                .resizable()
                .scaledToFit()
                .blur(radius: Effects.Muted.blurRadius)
                .opacity(Effects.Muted.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            PrimaryButton("vehicleCard.addVehicle", bundle: .onsarj, action: onAddVehicle)
        }
    }

    private var failed: some View {
        VStack(spacing: Spacing.md) {
            Text("vehicleCard.loadFailed", bundle: .onsarj)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton("common.retry", bundle: .onsarj) {
                Task { await model.reload() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: her hal, iPhone SE ve Pro Max × `Large` ve `xxxLarge` × açık ve koyu.
///
/// Dolu haller görselsizdir: araç görseli backend'den gelir (K-24), önizlemede gerçek bir adres yok.
struct VehicleCardPreviews: PreviewProvider {
    private struct Case: Identifiable {
        let name: String
        let content: PreviewVehicleRepository.Content
        let percent: Int?
        var id: String { name }
    }

    private static let cases = [
        Case(name: "Dolu · %15", content: .vehicle(PreviewVehicleRepository.dolphin), percent: 15),
        Case(name: "Dolu · %30 (başlangıç)", content: .vehicle(PreviewVehicleRepository.dolphin), percent: nil),
        Case(name: "Dolu · %80", content: .vehicle(PreviewVehicleRepository.dolphin), percent: 80),
        Case(name: "Araç yok", content: .noVehicles, percent: nil),
        Case(name: "Hata", content: .failure, percent: nil),
        Case(name: "Yükleniyor", content: .pending, percent: nil),
    ]
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let schemes: [ColorScheme] = [.light, .dark]

    static var previews: some View {
        ForEach(cases) { item in
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    ForEach(schemes, id: \.self) { scheme in
                        card(item)
                            .environment(\.dynamicTypeSize, typeSize)
                            .preferredColorScheme(scheme)
                            .previewDevice(PreviewDevice(rawValue: device))
                            .previewDisplayName(
                                "\(item.name) · \(device) · \(typeSize) · \(scheme == .dark ? "koyu" : "açık")"
                            )
                    }
                }
            }
        }
    }

    @MainActor
    private static func card(_ item: Case) -> some View {
        let model = VehicleCardModel(
            repository: PreviewVehicleRepository(content: item.content),
            batteryStore: PreviewBatteryLevelStore(percent: item.percent)
        )
        return VehicleCard(model: model, onSwitchVehicle: {}, onVehicleSettings: { _ in }, onAddVehicle: {})
            .task { await model.load() }
            .padding(Spacing.screenMargin)
            .frame(maxHeight: .infinity)
            .background(Theme.backgroundSheet)
    }
}
#endif
