import Foundation
import Observation

/// Arama sayfasının durumu: sorgu, geçmiş ve öneriler.
///
/// İki hal vardır: **başlangıç** (sorgu boş veya yalnızca boşluk) ve **yazma**. Geçmiş ve öneriler
/// dışarıdan verilen kapanışlarla gelir; model kaynağını bilmez.
@MainActor
@Observable
final class SearchModel {
    enum Phase: Equatable {
        case initial
        case typing
    }

    /// Arama alanındaki metin.
    var query = ""
    private(set) var history: [SearchRow] = []
    private(set) var suggestions: [SearchRow] = []

    @ObservationIgnored private let historySource: @Sendable () async -> [SearchRow]
    @ObservationIgnored private let suggestionSource: @Sendable (String) async -> [SearchRow]
    @ObservationIgnored private let onSubmit: (String) -> Void
    @ObservationIgnored private let onSelect: (SearchRow.ID) -> Void
    @ObservationIgnored private let onDeleteHistory: (SearchRow.ID) -> Void

    init(
        history: @escaping @Sendable () async -> [SearchRow],
        suggestions: @escaping @Sendable (String) async -> [SearchRow],
        onSubmit: @escaping (String) -> Void,
        onSelect: @escaping (SearchRow.ID) -> Void,
        onDeleteHistory: @escaping (SearchRow.ID) -> Void
    ) {
        historySource = history
        suggestionSource = suggestions
        self.onSubmit = onSubmit
        self.onSelect = onSelect
        self.onDeleteHistory = onDeleteHistory
    }

    var phase: Phase {
        trimmedQuery.isEmpty ? .initial : .typing
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func loadHistory() async {
        history = await historySource()
    }

    /// Sorguya göre önerileri yeniler. Yanıt gelene kadar sorgu değiştiyse eski yanıt yok sayılır.
    func refreshSuggestions() async {
        let query = trimmedQuery
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        let rows = await suggestionSource(query)
        guard query == trimmedQuery else { return }
        suggestions = rows
    }

    /// Temizle düğmesi: sayfa başlangıç haline döner.
    func clear() {
        query = ""
        suggestions = []
    }

    /// "Ara" düğmesi veya klavyenin arama tuşu. Boş sorguda bir şey yapmaz.
    func submit() {
        let query = trimmedQuery
        guard !query.isEmpty else { return }
        onSubmit(query)
    }

    func select(_ row: SearchRow) {
        onSelect(row.id)
    }

    /// Geçmiş satırı silinir; satır listeden hemen kalkar.
    func deleteHistory(_ id: SearchRow.ID) {
        history.removeAll { $0.id == id }
        onDeleteHistory(id)
    }
}
