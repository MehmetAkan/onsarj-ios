import DesignSystem
import Localization
import PhoneNumbers
import SwiftUI

/// Telefon numarası giriş ekranı: kayıt akışının ilk adımı.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1). Geri dönüş `onBack`, geçerli
/// numara `onContinue` ile dışarı bildirilir. Ekran uygulama katmanında bir `NavigationStack`
/// içinde gösterilmelidir; sistem gezinme çubuğunu gizler, yerine `ScreenHeader` kullanır.
public struct PhoneEntryView: View {
    private let onBack: () -> Void
    private let onContinue: (_ phoneNumber: String) -> Void

    @State private var model: PhoneEntryModel

    /// - Parameters:
    ///   - formatter: Uygulama boyunca paylaşılan telefon numarası biçimleyicisi.
    ///   - onBack: Kullanıcı geri okuna dokunduğunda çağrılır.
    ///   - onContinue: Geçerli numarayla "Devam"a dokunulduğunda çağrılır. Numara E.164
    ///     biçimindedir: `"+905537359394"`.
    public init(
        formatter: PhoneNumberFormatter,
        onBack: @escaping () -> Void,
        onContinue: @escaping (_ phoneNumber: String) -> Void
    ) {
        self.init(model: PhoneEntryModel(formatter: formatter), onBack: onBack, onContinue: onContinue)
    }

    init(
        model: PhoneEntryModel,
        onBack: @escaping () -> Void,
        onContinue: @escaping (_ phoneNumber: String) -> Void
    ) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.onContinue = onContinue
    }

    public var body: some View {
        ScrollView {
            content
        }
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
        .safeAreaInset(edge: .top) {
            ScreenHeader(
                "signup.phone.navTitle",
                backLabel: "signup.phone.accessibility.back",
                bundle: .onsarj,
                onBack: onBack
            )
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $model.isCountryPickerPresented) {
            CountryPicker(countries: model.formatter.countries, selected: model.country) { country in
                model.select(country)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            IconBadge(image: Image("phone-entry-icon", bundle: .module))

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("signup.phone.title", bundle: .onsarj)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Text("signup.phone.body", bundle: .onsarj)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            PhoneNumberField(
                formatter: model.formatter,
                number: $model.number,
                placeholder: model.placeholder,
                focusesOnAppear: true,
                onCountryTap: { model.isCountryPickerPresented = true }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.lg)
    }

    /// Klavyenin üstünde kalır: `safeAreaInset` klavye açıldığında yukarı taşınır.
    private var continueButton: some View {
        PrimaryButton("signup.phone.action.continue", bundle: .onsarj) {
            if let e164 = model.number.e164 {
                onContinue(e164)
            }
        }
        .disabled(!model.number.isValid)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.sm)
        .background(Theme.backgroundPrimary)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi (iPhone SE ve Pro Max × Large ve xxxLarge), boş ve dolu alanla;
/// ayrıca her durumun koyu tema görünümü.
struct PhoneEntryViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let numbers = ["", "5537359394"]

    @MainActor private static let formatter = PhoneNumberFormatter()

    static var previews: some View {
        ForEach(numbers, id: \.self) { number in
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    screen(number: number)
                        .dynamicTypeSize(typeSize)
                        .previewDevice(PreviewDevice(rawValue: device))
                        .previewDisplayName("\(device) · \(typeSize) · \(stateName(number))")
                }
            }

            screen(number: number)
                .preferredColorScheme(.dark)
                .previewDevice(PreviewDevice(rawValue: devices[1]))
                .previewDisplayName("\(devices[1]) · koyu · \(stateName(number))")
        }
    }

    @MainActor
    private static func screen(number: String) -> some View {
        NavigationStack {
            PhoneEntryView(
                model: PhoneEntryModel(
                    formatter: formatter,
                    country: formatter.country(forRegionCode: "TR"),
                    input: number
                ),
                onBack: {},
                onContinue: { _ in }
            )
        }
    }

    private static func stateName(_ number: String) -> String {
        number.isEmpty ? "boş" : "dolu"
    }
}
#endif
