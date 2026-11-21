import Foundation

/// Kullanıcının seçebildiği hazır boya renkleri.
///
/// Hex değerleri aracın **boya verisidir**, arayüz rengi değildir; backend'e `colorHex` olarak gider.
/// Aracın `colorHex`'i bunlardan biri değilse hiçbir boya seçili sayılmaz.
public enum VehiclePaint: String, Sendable, CaseIterable {
    case black
    case gray
    case white
    case blue
    case red
    case orange
    case yellow
    case green

    /// `#RRGGBB`, büyük harf.
    public var hex: String {
        switch self {
        case .black: "#121212"
        case .gray: "#9AA0A6"
        case .white: "#F2F2F2"
        case .blue: "#2A5CAA"
        case .red: "#D7303A"
        case .orange: "#E8641B"
        case .yellow: "#F5C518"
        case .green: "#2E8B3A"
        }
    }

    /// Hex değeri bu boyalardan birine eşitse o boya (büyük/küçük harf duyarsız); değilse `nil`.
    public init?(hex: String) {
        guard let paint = Self.allCases.first(where: { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }) else {
            return nil
        }
        self = paint
    }

    /// `#` ve ardından altı onaltılık rakam.
    public static func isValidHex(_ value: String) -> Bool {
        let digits = value.dropFirst()
        return value.first == "#" && digits.count == 6 && digits.allSatisfy(\.isHexDigit)
    }
}
