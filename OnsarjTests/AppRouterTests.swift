import Testing

@testable import Onsarj

@MainActor
@Suite("AppRouter")
struct AppRouterTests {
    @Test("Kod doğrulanınca SMS ekranı yığından çıkar: telefon → ad-soyad")
    func verifiedCodeLeavesStack() {
        let router = AppRouter()
        router.push(.phoneEntry)
        router.push(.verificationCode(phoneNumber: "+905321234567"))

        router.replaceTop(with: .nameEntry)

        #expect(router.path == [.phoneEntry, .nameEntry])
    }

    @Test("Ad-soyad ekranından geri dönüş telefon ekranına gider")
    func backFromNameEntryReachesPhoneEntry() {
        let router = AppRouter()
        router.push(.phoneEntry)
        router.push(.verificationCode(phoneNumber: "+905321234567"))
        router.replaceTop(with: .nameEntry)

        router.pop()

        #expect(router.path == [.phoneEntry])
    }

    @Test("Boş yığında en üstü değiştirmek ekranı ekler")
    func replaceTopOnEmptyStackPushes() {
        let router = AppRouter()

        router.replaceTop(with: .phoneEntry)

        #expect(router.path == [.phoneEntry])
    }

    @Test("Açılış kayıt akışıyla başlar")
    func launchStartsWithSignUp() {
        let router = AppRouter()

        #expect(router.flow == .signUp)
        #expect(router.path.isEmpty)
    }

    @Test("Kayıt bitince ana haritaya geçilir ve kayıt ekranları yığından çıkar")
    func completingSignUpOpensHome() {
        let router = AppRouter()
        router.push(.phoneEntry)
        router.push(.verificationCode(phoneNumber: "+905321234567"))
        router.replaceTop(with: .nameEntry)

        router.completeSignUp()

        #expect(router.flow == .home)
        #expect(router.path.isEmpty)
    }

    @Test("Boş yığında geri dönmek hiçbir şey yapmaz")
    func popOnEmptyStackDoesNothing() {
        let router = AppRouter()

        router.pop()

        #expect(router.path.isEmpty)
    }
}
