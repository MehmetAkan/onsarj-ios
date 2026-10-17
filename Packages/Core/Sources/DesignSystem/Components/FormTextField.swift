#if canImport(UIKit)
import SwiftUI
import UIKit

/// Tek satırlık form metin alanı: ad, soyad, e-posta gibi serbest metin girişleri.
///
/// Görünümü telefon ekranındaki numara alanıyla aynıdır: `Theme.backgroundSubtle` zemin,
/// `Radius.field` köşe, aynı yükseklik. Hata varken kenarlık `Theme.borderError` olur.
///
/// Girdinin süzülmesi ve kısaltılması bağlamanın sahibine aittir. Alan, bağlamaya yazdığı
/// değer sahibi tarafından değiştirilirse (ör. üst sınırda kesilirse) bu değeri kendi
/// metnine geri yazar; böylece kabul edilmeyen karakter alanda görünmez.
///
/// Otomatik düzeltme ve odak gibi davranışlar SwiftUI'ın standart değiştiricileriyle dışarıdan
/// verilir (`.autocorrectionDisabled()`, `.focused(_:equals:)`, `.onSubmit`).
///
/// Dosyanın tamamı iOS'a özeldir (CLAUDE.md 6.8, üçüncü durum): içerik tipi ve büyük harf
/// davranışı yalnızca iOS'ta vardır.
///
/// ```swift
/// FormTextField(
///     "signup.name.placeholder.first",
///     text: $firstName,
///     bundle: .onsarj,
///     contentType: .givenName,
///     capitalization: .words,
///     submitLabel: .next
/// )
/// ```
public struct FormTextField: View {
    @Binding private var value: String
    private let placeholderKey: LocalizedStringKey
    private let bundle: Bundle?
    private let contentType: UITextContentType?
    private let capitalization: TextInputAutocapitalization?
    private let submitLabel: SubmitLabel
    private let hasError: Bool

    @State private var text: String

    /// - Parameters:
    ///   - placeholder: Yer tutucunun String Catalog anahtarı. VoiceOver etiketi olarak da kullanılır.
    ///   - text: Alanın metni.
    ///   - bundle: Metnin bulunduğu paket; özellik modülleri `.onsarj` verir.
    ///   - contentType: Otomatik doldurma için içerik tipi (`.givenName`, `.emailAddress`...).
    ///   - capitalization: Büyük harf davranışı; verilmezse sistem varsayılanı.
    ///   - submitLabel: Klavyenin dönüş tuşu.
    ///   - hasError: Kenarlığın hata rengiyle çizilip çizilmeyeceği.
    public init(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        bundle: Bundle? = nil,
        contentType: UITextContentType? = nil,
        capitalization: TextInputAutocapitalization? = nil,
        submitLabel: SubmitLabel = .return,
        hasError: Bool = false
    ) {
        _value = text
        self.placeholderKey = placeholder
        self.bundle = bundle
        self.contentType = contentType
        self.capitalization = capitalization
        self.submitLabel = submitLabel
        self.hasError = hasError
        _text = State(initialValue: text.wrappedValue)
    }

    public var body: some View {
        TextField(text: $text, prompt: prompt) {
            Text(placeholderKey, bundle: bundle)
        }
        .font(Typography.body)
        .foregroundStyle(Theme.textPrimary)
        .textContentType(contentType)
        .textInputAutocapitalization(capitalization)
        .submitLabel(submitLabel)
        // Telefon ekranındaki numara alanıyla aynı yükseklik: en az dokunma alanı, üstte ve
        // altta `Spacing.xs`.
        .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Theme.backgroundSubtle, in: shape)
        .overlay {
            if hasError {
                shape.strokeBorder(Theme.borderError)
            }
        }
        .onChange(of: text) { _, newValue in
            value = newValue
            if text != value {
                text = value
            }
        }
        .onChange(of: value) { _, newValue in
            if text != newValue {
                text = newValue
            }
        }
    }

    private var prompt: Text {
        Text(placeholderKey, bundle: bundle)
            .foregroundStyle(Theme.textPlaceholder)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.field)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: iPhone SE ve Pro Max × Large ve xxxLarge; boş, dolu ve hatalı.
struct FormTextFieldPreviews: PreviewProvider {
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]

    static var previews: some View {
        ForEach(devices, id: \.self) { device in
            ForEach(typeSizes, id: \.self) { typeSize in
                VStack(spacing: Spacing.md) {
                    FormTextField("First name", text: .constant(""))
                    FormTextField("Last name", text: .constant("Yılmaz"))
                    FormTextField("Last name", text: .constant("Y"), hasError: true)
                }
                .padding(.horizontal, Spacing.screenMargin)
                .dynamicTypeSize(typeSize)
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName("\(device) · \(typeSize)")
            }
        }
    }
}
#endif
#endif
