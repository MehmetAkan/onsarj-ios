import Testing

@testable import AuthFeature

@MainActor
@Suite("NameEntryModel")
struct NameEntryModelTests {
    @Test("Değerler baştaki ve sondaki boşluklar kırpılarak verilir")
    func trimsWhitespace() {
        let model = NameEntryModel(firstName: "  Ayşe Nur ", lastName: "\tYılmaz\n")

        #expect(model.validName?.firstName == "Ayşe Nur")
        #expect(model.validName?.lastName == "Yılmaz")
    }

    @Test("Kırpıldıktan sonra 2 karakterden kısa alan geçersizdir", arguments: ["", " ", "A", "  A  "])
    func rejectsShorterThanMinimum(firstName: String) {
        let model = NameEntryModel(firstName: firstName, lastName: "Yılmaz")

        #expect(model.validName == nil)
        #expect(!model.canContinue)
    }

    @Test("Kırpıldıktan sonra 2 karakter yeterlidir")
    func acceptsMinimumLength() {
        let model = NameEntryModel(firstName: " Al ", lastName: "Wu")

        #expect(model.canContinue)
    }

    @Test(
        "Yalnızca noktalama, rakam ve boşluktan oluşan alan geçersizdir",
        arguments: ["--", "''", "-' -", "12", ". ."]
    )
    func rejectsInputWithoutLetters(lastName: String) {
        let model = NameEntryModel(firstName: "Ayşe", lastName: lastName)

        #expect(!model.canContinue)
    }

    @Test("Kesme işareti, tire ve boşluk içeren isimler kabul edilir")
    func acceptsPunctuationInsideNames() {
        let model = NameEntryModel(firstName: "Jean-Luc", lastName: "O'Connor de la Cruz")

        #expect(model.validName?.firstName == "Jean-Luc")
        #expect(model.validName?.lastName == "O'Connor de la Cruz")
    }

    @Test("Bir alan en fazla 50 karakter alır; fazlası kesilir")
    func limitsToMaximumLength() {
        let model = NameEntryModel()

        model.updateFirstName(String(repeating: "a", count: 50))
        #expect(model.firstName.count == 50)

        model.updateFirstName(String(repeating: "b", count: 60))
        #expect(model.firstName == String(repeating: "b", count: 50))

        model.updateLastName(String(repeating: "ç", count: 51))
        #expect(model.lastName.count == 50)

        let initial = NameEntryModel(firstName: String(repeating: "x", count: 70))
        #expect(initial.firstName.count == 50)
    }

    @Test("Buton iki alan da geçerli olunca etkinleşir")
    func enablesContinueWhenBothFieldsAreValid() {
        let model = NameEntryModel()
        #expect(!model.canContinue)

        model.updateFirstName("Ayşe")
        #expect(!model.canContinue)

        model.updateLastName("Y")
        #expect(!model.canContinue)

        model.updateLastName("Yı")
        #expect(model.canContinue)

        model.updateFirstName(" ")
        #expect(!model.canContinue)
    }
}
