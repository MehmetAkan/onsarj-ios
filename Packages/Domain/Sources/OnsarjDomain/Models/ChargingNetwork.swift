/// Bir şarj ağı (işletmeci), örneğin "ZES".
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

    public init(id: ID, name: String) {
        self.id = id
        self.name = name
    }
}
