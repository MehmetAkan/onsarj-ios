import OnsarjDomain
import Testing

@Suite("RoutePreferences")
struct RoutePreferencesTests {
    private let zes = ChargingNetwork.ID("zes")
    private let trugo = ChargingNetwork.ID("trugo")
    private let esarj = ChargingNetwork.ID("esarj")

    @Test("Varsayılan: optimal, kaçınma ve ağ listeleri boş")
    func defaults() {
        let preferences = RoutePreferences.default
        #expect(preferences.chargeStops == .optimal)
        #expect(preferences.avoid.isEmpty)
        #expect(preferences.preferredNetworks.isEmpty)
        #expect(preferences.avoidedNetworks.isEmpty)
    }

    @Test("prefer, ağı kaçınılanlardan çıkarır")
    func preferRemovesFromAvoided() {
        var preferences = RoutePreferences.default
        preferences.avoid(zes)
        preferences.prefer(zes)
        #expect(preferences.preferredNetworks == [zes])
        #expect(preferences.avoidedNetworks.isEmpty)
    }

    @Test("avoid, ağı tercih edilenlerden çıkarır")
    func avoidRemovesFromPreferred() {
        var preferences = RoutePreferences.default
        preferences.prefer(zes)
        preferences.avoid(zes)
        #expect(preferences.preferredNetworks.isEmpty)
        #expect(preferences.avoidedNetworks == [zes])
    }

    @Test("Aynı ağı tekrar eklemek çoğaltmaz")
    func addingTwiceDoesNotDuplicate() {
        var preferences = RoutePreferences.default
        preferences.prefer(zes)
        preferences.prefer(zes)
        preferences.avoid(trugo)
        preferences.avoid(trugo)
        #expect(preferences.preferredNetworks == [zes])
        #expect(preferences.avoidedNetworks == [trugo])
    }

    @Test("Ekleme sırası korunur")
    func orderIsPreserved() {
        var preferences = RoutePreferences.default
        preferences.prefer(trugo)
        preferences.prefer(zes)
        preferences.prefer(esarj)
        preferences.remove(zes)
        #expect(preferences.preferredNetworks == [trugo, esarj])

        preferences.avoid(zes)
        preferences.avoid(trugo)
        #expect(preferences.avoidedNetworks == [zes, trugo])
        #expect(preferences.preferredNetworks == [esarj])
    }

    @Test("remove ağı hangi listedeyse oradan çıkarır")
    func removeFromEitherList() {
        var preferences = RoutePreferences(
            preferredNetworks: [zes],
            avoidedNetworks: [trugo]
        )
        preferences.remove(zes)
        preferences.remove(trugo)
        #expect(preferences == .default)
    }

    @Test("toggle kaçınmayı açar ve kapatır")
    func toggleAvoidance() {
        var preferences = RoutePreferences.default
        preferences.toggle(.tolls)
        preferences.toggle(.ferries)
        #expect(preferences.avoid == [.tolls, .ferries])
        preferences.toggle(.tolls)
        #expect(preferences.avoid == [.ferries])
    }

    @Test("init değişmezi kurar: tekrar edenlerden ilki, çakışmada tercih edilen kalır")
    func initNormalizes() {
        let preferences = RoutePreferences(
            preferredNetworks: [zes, esarj, zes],
            avoidedNetworks: [trugo, zes, trugo]
        )
        #expect(preferences.preferredNetworks == [zes, esarj])
        #expect(preferences.avoidedNetworks == [trugo])
    }
}
