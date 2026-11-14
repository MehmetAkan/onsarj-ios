import Testing

@testable import SearchFeature

@MainActor
@Suite("SearchModel")
struct SearchModelTests {
    private static let rows = [
        SearchRow(id: "place", kind: .place, title: "Gaziantep Şehir Merkezi"),
        SearchRow(id: "history", kind: .history, title: "Raw Coffe Konyaaltı"),
        SearchRow(id: "charger", kind: .charger, title: "Trugo • Antalya Dünyagöz Yaşam"),
    ]

    private final class Calls {
        var submitted: [String] = []
        var selected: [SearchRow.ID] = []
        var deleted: [SearchRow.ID] = []
    }

    private func makeModel(_ calls: Calls) -> SearchModel {
        let rows = Self.rows
        return SearchModel(
            history: { rows.filter { $0.kind != .place } },
            suggestions: { query in rows.filter { $0.title.localizedStandardContains(query) } },
            onSubmit: { calls.submitted.append($0) },
            onSelect: { calls.selected.append($0) },
            onDeleteHistory: { calls.deleted.append($0) }
        )
    }

    @Test("Boş sorgu başlangıç halidir; metin girilince yazma; temizleyince geri döner")
    func phases() async {
        let model = makeModel(Calls())
        #expect(model.phase == .initial)

        model.query = "Gazi"
        await model.refreshSuggestions()
        #expect(model.phase == .typing)
        #expect(model.suggestions.map(\.id) == ["place"])

        model.clear()
        #expect(model.phase == .initial)
        #expect(model.query.isEmpty)
        #expect(model.suggestions.isEmpty)
    }

    @Test("Yalnızca boşluktan oluşan sorgu başlangıç hali sayılır")
    func whitespaceIsInitial() {
        let model = makeModel(Calls())
        model.query = "   "
        #expect(model.phase == .initial)
    }

    @Test("Ara: kırpılmış sorguyla çağrılır")
    func submitTrims() {
        let calls = Calls()
        let model = makeModel(calls)
        model.query = "  Gaziantep \n"

        model.submit()

        #expect(calls.submitted == ["Gaziantep"])
    }

    @Test("Ara: boş veya yalnızca boşluk sorguda çağrılmaz", arguments: ["", "   ", "\n\t"])
    func submitIgnoresBlank(query: String) {
        let calls = Calls()
        let model = makeModel(calls)
        model.query = query

        model.submit()

        #expect(calls.submitted.isEmpty)
    }

    @Test("Geçmiş satırı silinince listeden kalkar ve bildirilir")
    func deleteHistory() async {
        let calls = Calls()
        let model = makeModel(calls)
        await model.loadHistory()
        #expect(model.history.map(\.id) == ["history", "charger"])

        model.deleteHistory("history")

        #expect(model.history.map(\.id) == ["charger"])
        #expect(calls.deleted == ["history"])
    }

    @Test("Satır seçimi kimliğiyle bildirilir")
    func select() {
        let calls = Calls()
        let model = makeModel(calls)

        model.select(Self.rows[2])

        #expect(calls.selected == ["charger"])
    }
}
