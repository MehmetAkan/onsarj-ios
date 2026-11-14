import DesignSystem
import Localization
import SwiftUI

/// Arama sayfası (K-25): ana sayfadaki arama alanına dokununca uygulama katmanı bunu büyük bir
/// modal olarak sunar.
///
/// - **Başlangıç (alan boş):** kayıtlı yer çipleri ve geçmiş listesi. Geçmiş satırı sola kaydırılınca
///   silinir.
/// - **Yazma:** çipler ve geçmiş gizlenir; sorguya göre öneri listesi gösterilir.
///
/// Sayfa açılınca arama alanı odaklanır ve klavye açılır; liste kaydırılınca klavye etkileşimli
/// kapanır. Ekran kendi geçişini yapmaz (CLAUDE.md 5.3 kural 1); kullanıcının isteklerini kapanışlarla
/// dışarı bildirir. Satırların kaynağını bilmez; geçmiş ve öneriler kapanışlarla gelir.
public struct SearchView: View {
    @State private var model: SearchModel
    @FocusState private var isFieldFocused: Bool

    private let onClose: () -> Void
    private let onSetHome: () -> Void
    private let onSetWork: () -> Void
    private let onAddSaved: () -> Void

    /// - Parameters:
    ///   - history: Geçmiş satırları (başlangıç hali).
    ///   - suggestions: Kırpılmış sorguya göre öneri satırları (yazma hali).
    ///   - onClose: Kapat düğmesine dokunuldu.
    ///   - onSubmit: "Ara" düğmesi veya klavyenin arama tuşu; kırpılmış, boş olmayan sorguyla çağrılır.
    ///   - onSelect: Bir satıra dokunuldu.
    ///   - onSetHome: "Ev ekle" çipine dokunuldu.
    ///   - onSetWork: "İş ekle" çipine dokunuldu.
    ///   - onAddSaved: "Kayıtlı ekle" düğmesine dokunuldu.
    ///   - onDeleteHistory: Bir geçmiş satırı silindi; satır listeden zaten kalkmıştır.
    public init(
        history: @escaping @Sendable () async -> [SearchRow],
        suggestions: @escaping @Sendable (String) async -> [SearchRow],
        onClose: @escaping () -> Void,
        onSubmit: @escaping (String) -> Void,
        onSelect: @escaping (SearchRow.ID) -> Void,
        onSetHome: @escaping () -> Void,
        onSetWork: @escaping () -> Void,
        onAddSaved: @escaping () -> Void,
        onDeleteHistory: @escaping (SearchRow.ID) -> Void
    ) {
        self.init(
            model: SearchModel(
                history: history,
                suggestions: suggestions,
                onSubmit: onSubmit,
                onSelect: onSelect,
                onDeleteHistory: onDeleteHistory
            ),
            onClose: onClose,
            onSetHome: onSetHome,
            onSetWork: onSetWork,
            onAddSaved: onAddSaved
        )
    }

    init(
        model: SearchModel,
        onClose: @escaping () -> Void = {},
        onSetHome: @escaping () -> Void = {},
        onSetWork: @escaping () -> Void = {},
        onAddSaved: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)
        self.onClose = onClose
        self.onSetHome = onSetHome
        self.onSetWork = onSetWork
        self.onAddSaved = onAddSaved
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            SearchTopBar(
                query: $model.query,
                isFocused: $isFieldFocused,
                isTyping: model.phase == .typing,
                onClear: model.clear,
                onClose: onClose,
                onSubmit: model.submit
            )
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.top, Spacing.xl)

            List {
                switch model.phase {
                case .initial: initialSections
                case .typing: suggestionRows
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .environment(\.defaultMinListRowHeight, Spacing.minTapTarget)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.backgroundSheet)
        .task { await model.loadHistory() }
        .task { isFieldFocused = true }
        .task(id: model.query) { await model.refreshSuggestions() }
    }

    // MARK: - Başlangıç

    @ViewBuilder private var initialSections: some View {
        sectionTitle("search.savedPlaces")
        SavedPlacesChips(onSetHome: onSetHome, onSetWork: onSetWork, onAddSaved: onAddSaved)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

        if !model.history.isEmpty {
            sectionTitle("search.history")
                .padding(.top, Spacing.md)
            ForEach(model.history) { row in
                rowButton(row)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            model.deleteHistory(row.id)
                        } label: {
                            Text("search.delete", bundle: .onsarj)
                        }
                    }
            }
        }
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key, bundle: .onsarj)
            .font(Typography.secondary)
            .foregroundStyle(Theme.textSecondary)
            .accessibilityAddTraits(.isHeader)
            .listRowInsets(rowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    // MARK: - Yazma

    private var suggestionRows: some View {
        ForEach(model.suggestions) { row in
            rowButton(row)
        }
    }

    // MARK: - Satır

    private func rowButton(_ row: SearchRow) -> some View {
        Button {
            model.select(row)
        } label: {
            SearchRowView(row: row)
        }
        .buttonStyle(.plain)
        .listRowInsets(rowInsets)
        .listRowSeparatorTint(Theme.borderSubtle)
        .listRowBackground(Color.clear)
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: Spacing.screenMargin, bottom: 0, trailing: Spacing.screenMargin)
    }
}

#if DEBUG
/// CLAUDE.md 6.7 test matrisi: başlangıç ve yazma halleri, iPhone SE ve Pro Max × `Large` ve
/// `xxxLarge` × açık ve koyu. Satırlar önizleme verisidir.
struct SearchViewPreviews: PreviewProvider {
    private static let rows = [
        SearchRow(id: "place", kind: .place, title: "Gaziantep Şehir Merkezi"),
        SearchRow(id: "history", kind: .history, title: "Raw Coffe Konyaaltı"),
        SearchRow(id: "charger-1", kind: .charger, title: "Trugo • Antalya Dünyagöz Yaşam"),
        SearchRow(id: "charger-2", kind: .charger, title: "En Yakıt • Bolu Wender Avm"),
    ]
    private static let devices = ["iPhone SE (3rd generation)", "iPhone 17 Pro Max"]
    private static let typeSizes: [DynamicTypeSize] = [.large, .xxxLarge]
    private static let schemes: [ColorScheme] = [.light, .dark]
    private static let queries = ["", "Gazi"]

    static var previews: some View {
        ForEach(queries, id: \.self) { query in
            ForEach(devices, id: \.self) { device in
                ForEach(typeSizes, id: \.self) { typeSize in
                    ForEach(schemes, id: \.self) { scheme in
                        SearchPreviewHost(query: query, rows: rows)
                            .environment(\.dynamicTypeSize, typeSize)
                            .preferredColorScheme(scheme)
                            .previewDevice(PreviewDevice(rawValue: device))
                            .previewDisplayName(
                                "\(query.isEmpty ? "Başlangıç" : "Yazma") · \(device) · \(typeSize) · "
                                    + (scheme == .dark ? "koyu" : "açık")
                            )
                    }
                }
            }
        }
    }
}

/// Önizlemede sorguyu hazır yazılmış gösterir.
private struct SearchPreviewHost: View {
    let query: String
    let rows: [SearchRow]

    var body: some View {
        let rows = rows
        let model = SearchModel(
            history: { rows.filter { $0.kind != .place } },
            suggestions: { query in rows.filter { $0.title.localizedStandardContains(query) } },
            onSubmit: { _ in },
            onSelect: { _ in },
            onDeleteHistory: { _ in }
        )
        model.query = query
        return SearchView(model: model)
    }
}
#endif
