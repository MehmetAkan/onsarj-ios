import Foundation

/// Bir şarj ağı (işletmeci), örneğin "ZES". İstasyonlar bir ağa bağlıdır (`Station.network`).
public struct ChargingNetwork: Sendable, Equatable, Hashable, Identifiable {
    /// Ağın tip güvenli kimliği.
    public struct ID: Sendable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    /// Kullanıcıya gösterilen ad.
    public let name: String
    /// Ağın logosu; yoksa veya bilinmiyorsa `nil`. Harita pininde logo yerine şimşek çizilir.
    public let logoURL: URL?

    public init(id: ID, name: String, logoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
    }
}
