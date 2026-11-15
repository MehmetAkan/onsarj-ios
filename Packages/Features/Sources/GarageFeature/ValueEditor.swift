import Foundation

/// Bir değer alanının düzenleme durumu: metin, yerel ayara göre ayrıştırma ve doğrulama.
///
/// Değer modalı ve profil formu aynı mantığı kullanır. Sayılar yerel ayarın ondalık ayırıcısıyla
/// yazılır (Türkçede virgül). Boş alan hata satırı göstermez ama kaydedilemez.
struct ValueEditor: Equatable {
    enum Kind: Equatable {
        /// Ondalıklı sayı; bir ondalığa yuvarlanarak denetlenir.
        case decimal(ClosedRange<Double>)
        case integer(ClosedRange<Int>)
        /// Serbest metin; boş bırakılabilir.
        case text
    }

    let kind: Kind
    let locale: Locale
    private let initialText: String
    var text: String

    init(kind: Kind, text: String, locale: Locale) {
        self.kind = kind
        self.locale = locale
        initialText = text
        self.text = text
    }

    /// Ondalıklı değer; ayrıştırılamıyorsa `nil`.
    var decimalValue: Double? {
        guard let number = Self.formatter(locale).number(from: trimmed) else { return nil }
        return (number.doubleValue * 10).rounded() / 10
    }

    /// Tam sayı değeri; ayrıştırılamıyorsa veya kesirliyse `nil`.
    var integerValue: Int? {
        guard let number = Self.formatter(locale).number(from: trimmed),
            number.doubleValue.rounded() == number.doubleValue,
            let value = Int(exactly: number.doubleValue)
        else { return nil }
        return value
    }

    /// Kırpılmış metin.
    var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Alan dolu ama değer ayrıştırılamıyor veya aralık dışında: hata satırı gösterilir.
    var isOutOfRange: Bool {
        !trimmed.isEmpty && !isValid
    }

    var isValid: Bool {
        switch kind {
        case .decimal(let range): decimalValue.map(range.contains) ?? false
        case .integer(let range): integerValue.map(range.contains) ?? false
        case .text: true
        }
    }

    var hasChanges: Bool {
        switch kind {
        case .decimal: decimalValue != Self(kind: kind, text: initialText, locale: locale).decimalValue
        case .integer: integerValue != Self(kind: kind, text: initialText, locale: locale).integerValue
        case .text: trimmed != initialText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var canSave: Bool {
        isValid && hasChanges
    }

    /// Aralığın sınırları, yerel biçimde ("5" ve "50"); hata metni için.
    var rangeBounds: (lower: String, upper: String)? {
        switch kind {
        case .decimal(let range):
            let style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1)).locale(locale)
            return (range.lowerBound.formatted(style), range.upperBound.formatted(style))
        case .integer(let range):
            let style = IntegerFormatStyle<Int>.number.locale(locale)
            return (range.lowerBound.formatted(style), range.upperBound.formatted(style))
        case .text:
            return nil
        }
    }

    private static func formatter(_ locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }
}
