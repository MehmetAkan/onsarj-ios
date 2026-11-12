import DesignSystem
import PhoneNumbers
import SwiftUI
import UIKit

/// Yazılırken biçimlenen telefon numarası alanı.
///
/// SwiftUI `TextField` yerine `UITextField` kullanılır: SwiftUI'da metni yazılırken
/// düzeltmek imleci sona atar ve kabul edilmeyen karakter önce ekrana basılıp sonra
/// silinir. `shouldChangeCharactersIn` her tuş vuruşunu metne girmeden önce yakalar.
///
/// Alan yalnızca gösterim ve giriştir; kurallar `PhoneNumberFormatter`'dan gelir:
/// rakam dışı karakter, ulusal ön ek (`0`) ve fazla basamak alana hiç girmez.
struct PhoneNumberTextField: UIViewRepresentable {
    let formatter: PhoneNumberFormatter
    @Binding var number: ParsedPhoneNumber
    let placeholder: String
    let accessibilityLabel: String

    /// Alan ekrana geldiğinde klavye açılsın mı.
    var focusesOnAppear = false

    func makeUIView(context: Context) -> FocusingTextField {
        let field = FocusingTextField()
        field.delegate = context.coordinator
        field.keyboardType = .phonePad
        field.textContentType = .telephoneNumber
        field.font = UITypography.numeric
        field.adjustsFontForContentSizeCategory = true
        field.textColor = UIColor(Theme.textPrimary)
        field.wantsFocusOnAppear = focusesOnAppear
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: FocusingTextField, context: Context) {
        context.coordinator.parent = self
        if field.text != number.formatted {
            field.text = number.formatted
        }
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(Theme.textPlaceholder), .font: UITypography.numeric]
        )
        field.accessibilityLabel = accessibilityLabel
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberTextField

        init(parent: PhoneNumberTextField) {
            self.parent = parent
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let current = textField.text ?? ""
            guard let replacedRange = Range(range, in: current) else { return false }

            let editRange = Self.expandedDeletionRange(replacedRange, in: current, replacement: string)
            let proposed = current.replacingCharacters(in: editRange, with: string)
            let parsed = parent.formatter.parse(proposed, for: parent.number.country)

            // Ekleme hiçbir rakam kazandırmadıysa (fazla basamak, ulusal ön ek, harf)
            // alan değişmez.
            let gainedNothing =
                parsed.nationalDigits == parent.number.nationalDigits && parsed.country == parent.number.country
            if !string.isEmpty, gainedNothing {
                return false
            }

            let typedPrefix = String(current[..<editRange.lowerBound]) + string
            apply(parsed, to: textField, digitsBeforeCursor: typedPrefix.digitCount, proposed: proposed)
            return false
        }

        private func apply(
            _ parsed: ParsedPhoneNumber,
            to textField: UITextField,
            digitsBeforeCursor: Int,
            proposed: String
        ) {
            textField.text = parsed.formatted
            parent.number = parsed

            // Baştan atılan rakamlar (ulusal ön ek) imleç hesabından düşülür.
            let removedLeading = max(0, proposed.digitCount - parsed.nationalDigits.count)
            let targetDigits = min(max(0, digitsBeforeCursor - removedLeading), parsed.nationalDigits.count)
            let offset = parsed.formatted.utf16Offset(afterDigit: targetDigits)
            if let position = textField.position(from: textField.beginningOfDocument, offset: offset) {
                textField.selectedTextRange = textField.textRange(from: position, to: position)
            }
        }

        /// Silme yalnızca ayraçları (boşluk, parantez, tire) kapsıyorsa önündeki rakam da
        /// silinir. Aksi halde biçimlendirme ayracı geri koyar ve silme işe yaramaz görünür.
        private static func expandedDeletionRange(
            _ range: Range<String.Index>,
            in text: String,
            replacement: String
        ) -> Range<String.Index> {
            guard replacement.isEmpty, !text[range].contains(where: \.isPhoneDigit) else { return range }
            guard let digitIndex = text[..<range.lowerBound].lastIndex(where: \.isPhoneDigit) else { return range }
            return digitIndex..<range.upperBound
        }
    }
}

/// Pencereye eklendiğinde klavyeyi açabilen metin alanı.
///
/// `becomeFirstResponder` alan bir pencerede değilken etkisizdir; bu yüzden odak isteği
/// alan ekrana geldiği ana ertelenir.
final class FocusingTextField: UITextField {
    var wantsFocusOnAppear = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard wantsFocusOnAppear, window != nil else { return }
        wantsFocusOnAppear = false
        becomeFirstResponder()
    }
}

extension Character {
    fileprivate var isPhoneDigit: Bool {
        isASCII && isNumber
    }
}

extension String {
    fileprivate var digitCount: Int {
        count(where: \.isPhoneDigit)
    }

    /// `count` rakamın hemen arkasındaki konum (UTF-16). `count` sıfırsa başlangıç.
    fileprivate func utf16Offset(afterDigit count: Int) -> Int {
        guard count > 0 else { return 0 }
        var seen = 0
        for position in indices where self[position].isPhoneDigit {
            seen += 1
            if seen == count {
                return index(after: position).utf16Offset(in: self)
            }
        }
        return utf16.count
    }
}
