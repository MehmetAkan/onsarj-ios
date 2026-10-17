import DesignSystem
import Localization
import SwiftUI

/// Ad ve soyad ekranı: kayıt akışının son adımı, SMS kodu doğrulandıktan sonra gelir.
///
/// Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1). Geri dönüş `onBack`, geçerli ad ve
/// soyad `onContinue` ile dışarı bildirilir. Ekran uygulama katmanında bir `NavigationStack`
/// içinde gösterilmelidir; sistem gezinme çubuğunu gizler, yerine `ScreenHeader` kullanır.
public struct NameEntryView: View {
    private enum Field {
        case first
        case last
    }

    private let onBack: () -> Void
    private let onContinue: (_ firstName: String, _ lastName: String) -> Void

    @State private var model: NameEntryModel
    @FocusState private var focusedField: Field?

    /// - Parameters:
    ///   - onBack: Kullanıcı geri okuna dokunduğunda çağrılır.
    ///   - onContinue: İki alan da geçerliyken "Devam"a dokunulduğunda çağrılır. Değerlerin
    ///     başındaki ve sonundaki boşluklar kırpılmıştır.
    public init(
        onBack: @escaping () -> Void,
        onContinue: @escaping (_ firstName: String, _ lastName: String) -> Void
    ) {
        self.init(model: NameEntryModel(), onBack: onBack, onContinue: onContinue)
    }

    init(
        model: NameEntryModel,
        onBack: @escaping () -> Void,
        onContinue: @escaping (_ firstName: String, _ lastName: String) -> Void
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
                "signup.name.navTitle",
                backLabel: "signup.phone.accessibility.back",
                bundle: .onsarj,
                onBack: onBack
            )
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            focusedField = .first
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            IconBadge(image: Image("user-entry-icon", bundle: .module))

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("signup.name.title", bundle: .onsarj)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Text("signup.name.body", bundle: .onsarj)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            fields
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.lg)
    }

    /// Otomatik düzeltme kapalıdır: isimleri "düzelterek" bozar. SwiftUI'da akıllı tırnağı
    /// ayrıca kapatan bir değiştirici yoktur.
    private var fields: some View {
        VStack(spacing: Spacing.md) {
            FormTextField(
                "signup.name.placeholder.first",
                text: Binding(get: { model.firstName }, set: { model.updateFirstName($0) }),
                bundle: .onsarj,
                contentType: .givenName,
                capitalization: .words,
                submitLabel: .next
            )
            .focused($focusedField, equals: .first)
            .onSubmit { focusedField = .last }

            FormTextField(
                "signup.name.placeholder.last",
                text: Binding(get: { model.lastName }, set: { model.updateLastName($0) }),
                bundle: .onsarj,
                contentType: .familyName,
                capitalization: .words,
                submitLabel: .done
            )
            .focused($focusedField, equals: .last)
            .onSubmit { focusedField = nil }
        }
        .autocorrectionDisabled()
    }

    /// Klavyenin üstünde kalır: `safeAreaInset` klavye açıldığında yukarı taşınır.
    private var continueButton: some View {
        PrimaryButton("signup.name.action.continue", bundle: .onsarj) {
            if let name = model.validName {
                onContinue(name.firstName, name.lastName)
            }
        }
        .disabled(!model.canContinue)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.sm)
        .background(Theme.backgroundPrimary)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi (iPhone SE ve Pro Max × Large ve xxxLarge), boş ve dolu alanlarla;
/// ayrıca her durumun koyu tema görünümü.
struct NameEntryViewPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private struct PreviewState {
        let name: String
        let firstName: String
        let lastName: String
    }

    private static let states = [
        PreviewState(name: "boş", firstName: "", lastName: ""),
        PreviewState(name: "dolu", firstName: "Ayşe Nur", lastName: "O'Connor-Yılmaz"),
    ]

    static var previews: some View {
        ForEach(states, id: \.name) { state in
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    screen(state)
                        .dynamicTypeSize(typeSize)
                        .previewDevice(PreviewDevice(rawValue: device))
                        .previewDisplayName("\(device) · \(typeSize) · \(state.name)")
                }
            }

            screen(state)
                .preferredColorScheme(.dark)
                .previewDevice(PreviewDevice(rawValue: devices[1]))
                .previewDisplayName("\(devices[1]) · koyu · \(state.name)")
        }
    }

    @MainActor
    private static func screen(_ state: PreviewState) -> some View {
        NavigationStack {
            NameEntryView(
                model: NameEntryModel(firstName: state.firstName, lastName: state.lastName),
                onBack: {},
                onContinue: { _, _ in }
            )
        }
    }
}
#endif
