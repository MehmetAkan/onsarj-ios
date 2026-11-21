import Foundation

/// Bir istasyonda geçerli fiyat seçeneği (ör. "Doğrudan ödeme", bir üyelik).
public struct Tariff: Sendable, Hashable {
    public let name: String
    public let paymentMethods: [PaymentMethod]
    /// kWh başına fiyat; yoksa `nil`.
    public let pricePerKwh: Decimal?
    /// Dakika başına ücret; yoksa `nil`.
    public let pricePerMinute: Decimal?
    /// ISO 4217 para birimi kodu (ör. `TRY`).
    public let currencyCode: String

    public init(
        name: String,
        paymentMethods: [PaymentMethod],
        pricePerKwh: Decimal?,
        pricePerMinute: Decimal?,
        currencyCode: String
    ) {
        self.name = name
        self.paymentMethods = paymentMethods
        self.pricePerKwh = pricePerKwh
        self.pricePerMinute = pricePerMinute
        self.currencyCode = currencyCode
    }
}

/// Tarifede kabul edilen ödeme yolu.
public enum PaymentMethod: String, Sendable, Hashable, CaseIterable {
    /// Temassız (NFC) kart veya telefon.
    case contactless
    /// Kartı takarak ödeme.
    case card
    /// Ağın uygulaması.
    case app
    /// Ağın RFID kartı.
    case rfid
}
