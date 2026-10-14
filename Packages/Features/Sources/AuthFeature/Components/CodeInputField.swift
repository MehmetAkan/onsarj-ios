import DesignSystem
import Localization
import SwiftUI

/// SMS kodu alanı: her hane için ayrı bir kare, yan yana.
///
/// Sıradaki hanenin karesi vurgulanır; kullanıcı yazdıkça vurgu bir sonraki kareye geçer.
/// Hata varken bütün karelerin kenarlığı `Theme.borderError` olur.
///
/// Kareler yalnızca gösterimdir. Üzerlerine metni, imleci ve yer tutucusu görünmeyen bir
/// `TextField` bindirilir: dokunuşu alır, klavyeyi açar, iOS'un SMS kodu önerisini
/// (`.oneTimeCode`) gösterir ve VoiceOver'a tek bir alan olarak sunulur. `opacity(0)`
/// kullanılmaz: saydam görünümler dokunuş ve ekran okuyucu ağacından çıkar.
///
/// Girdinin süzülmesi bağlamanın sahibine aittir. Alan, süzülen değeri kendi metnine geri
/// yazar; böylece kabul edilmeyen bir karakter görünmez alanda birikmez.
struct CodeInputField: View {
    @Binding var code: String
    let length: Int
    var hasError = false
    var focusesOnAppear = false

    @State private var text: String
    @FocusState private var isFocused: Bool

    init(code: Binding<String>, length: Int, hasError: Bool = false, focusesOnAppear: Bool = false) {
        _code = code
        self.length = length
        self.hasError = hasError
        self.focusesOnAppear = focusesOnAppear
        _text = State(initialValue: code.wrappedValue)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<length, id: \.self) { index in
                cell(at: index)
            }
        }
        .accessibilityHidden(true)
        .overlay { inputField }
        .onAppear {
            if focusesOnAppear {
                isFocused = true
            }
        }
    }

    /// Bir hane: genişliği eşit paylaşılan, kare bir kutu.
    private func cell(at index: Int) -> some View {
        let digit = code.dropFirst(index).first
        return Text(verbatim: digit.map(String.init) ?? "")
            .font(Typography.numericLarge)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Theme.backgroundSubtle, in: cellShape)
            .overlay {
                if let border = borderColor(at: index) {
                    cellShape.strokeBorder(border)
                }
            }
    }

    /// Hata varken bütün kareler kırmızı; yoksa yalnızca sıradaki hanenin karesi vurgulu.
    private func borderColor(at index: Int) -> Color? {
        if hasError {
            return Theme.borderError
        }
        let activeIndex = min(code.count, length - 1)
        return isFocused && index == activeIndex ? Theme.actionPrimary : nil
    }

    private var inputField: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .autocorrectionDisabled()
            .foregroundStyle(.clear)
            .tint(.clear)
            .focused($isFocused)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(Text("verification.accessibility.codeField", bundle: .onsarj))
            .onChange(of: text) { _, newValue in
                code = newValue
                if text != code {
                    text = code
                }
            }
            .onChange(of: code) { _, newValue in
                if text != newValue {
                    text = newValue
                }
            }
    }

    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.field)
    }
}
