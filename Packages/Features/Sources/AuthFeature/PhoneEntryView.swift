import DesignSystem
import Localization
import SwiftUI

/// Telefon numarası giriş ekranı: kayıt akışının ilk adımı.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1). Geri dönüş `onBack`, geçerli
/// numara `onContinue` ile dışarı bildirilir. Gezinme çubuğu öğeleri `toolbar` ile
/// verilir; ekran uygulama katmanında bir `NavigationStack` içinde gösterilmelidir.
public struct PhoneEntryView: View {
    private let onBack: () -> Void
    private let onContinue: (_ phoneNumber: String) -> Void

    @State private var model: PhoneEntryModel
    @FocusState private var isNumberFocused: Bool

    /// - Parameters:
    ///   - onBack: Kullanıcı geri okuna dokunduğunda çağrılır.
    ///   - onContinue: Geçerli numarayla "Devam"a dokunulduğunda çağrılır. Numara ülke
    ///     kodu dahil, yalnızca rakamlardan oluşur: `"905537359394"`.
    public init(onBack: @escaping () -> Void, onContinue: @escaping (_ phoneNumber: String) -> Void) {
        self.init(model: PhoneEntryModel(country: .turkey), onBack: onBack, onContinue: onContinue)
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
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .onAppear { isNumberFocused = true }
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
                country: model.country,
                text: $model.formattedNumber,
                isFocused: $isNumberFocused
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.lg)
    }

    /// Klavyenin üstünde kalır: `safeAreaInset` klavye açıldığında yukarı taşınır.
    private var continueButton: some View {
        PrimaryButton("signup.phone.action.continue", bundle: .onsarj) {
            onContinue(model.fullNumber)
        }
        .disabled(!model.isValid)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.sm)
        .background(Theme.backgroundPrimary)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(Typography.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            .accessibilityLabel(Text("signup.phone.accessibility.back", bundle: .onsarj))
        }
        ToolbarItem(placement: .principal) {
            Text("signup.phone.navTitle", bundle: .onsarj)
                .font(Typography.headline)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi (iPhone SE ve Pro Max × Large ve xxxLarge), boş ve dolu alanla.
struct PhoneEntryViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let numbers = ["", "5537359394"]

    static var previews: some View {
        ForEach(numbers, id: \.self) { number in
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    NavigationStack {
                        PhoneEntryView(
                            model: PhoneEntryModel(country: .turkey, digits: number),
                            onBack: {},
                            onContinue: { _ in }
                        )
                    }
                    .dynamicTypeSize(typeSize)
                    .previewDevice(PreviewDevice(rawValue: device))
                    .previewDisplayName("\(device) · \(typeSize) · \(number.isEmpty ? "boş" : "dolu")")
                }
            }
        }
    }
}
#endif
