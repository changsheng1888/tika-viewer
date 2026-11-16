import Foundation
import Combine

final class AppModel: ObservableObject {
    @Published private(set) var cards: [CardDump] = []
    @Published var errorMessage: String?
    @Published var selectedCardID: UUID?
    @Published var compareAID: UUID?
    @Published var compareBID: UUID?
    @Published var showDiffOnly: Bool = true

    private let storeFileName = "library.json"

    init() {
        load()
        if selectedCardID == nil { selectedCardID = cards.first?.id }
        if compareAID == nil { compareAID = cards.first?.id }
        if compareBID == nil { compareBID = cards.count > 1 ? cards[1].id : cards.first?.id }
    }

    // MARK: - 存取

    private var storeURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(storeFileName)
    }

    func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        if let decoded = try? JSONDecoder().decode([CardDump].self, from: data) {
            cards = decoded
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(cards)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            errorMessage = "保存列表失败：\(error.localizedDescription)"
        }
    }

    // MARK: - 导入

    func importURL(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let bytes = try DumpParser.parse(data: data)
            add(bytes: bytes, name: url.deletingPathExtension().lastPathComponent)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func add(bytes: [UInt8], name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let card = CardDump(name: trimmed.isEmpty ? "未命名卡" : trimmed, bytes: bytes)
        cards.insert(card, at: 0)

        if selectedCardID == nil { selectedCardID = card.id }
        if compareAID == nil {
            compareAID = card.id
        } else if compareBID == nil || compareBID == compareAID {
            compareBID = card.id
        }
        save()
    }

    func delete(_ card: CardDump) {
        cards.removeAll { $0.id == card.id }
        if selectedCardID == card.id { selectedCardID = cards.first?.id }
        if compareAID == card.id { compareAID = cards.first?.id }
        if compareBID == card.id { compareBID = cards.first(where: { $0.id != compareAID })?.id }
        save()
    }

    // MARK: - 查询

    func card(id: UUID?) -> CardDump? {
        guard let id = id else { return nil }
        return cards.first(where: { $0.id == id })
    }

    var selectedCard: CardDump? {
        card(id: selectedCardID) ?? cards.first
    }

    var cardA: CardDump? {
        card(id: compareAID) ?? cards.first
    }

    var cardB: CardDump? {
        if let candidate = card(id: compareBID), candidate.id != cardA?.id {
            return candidate
        }
        return cards.first(where: { $0.id != cardA?.id })
    }

    var currentDiff: CardDiff? {
        guard let a = cardA, let b = cardB else { return nil }
        return CardDiff.make(a: a, b: b)
    }

    /// 某个卡片在「当前对比对」里的差异（用于扇区条着色），不在对比对里返回 nil
    func diff(for card: CardDump) -> CardDiff? {
        guard let diff = currentDiff else { return nil }
        guard diff.a.id == card.id || diff.b.id == card.id else { return nil }
        return diff
    }
}
