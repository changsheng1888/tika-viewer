import Foundation

/// 一张卡的完整 dump：1024 字节（1K）或 4096 字节（4K），每 16 字节一块
struct CardDump: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bytes: [UInt8]
    var importedAt: Date
    var sourceLabel: String

    init(id: UUID = UUID(),
         name: String,
         bytes: [UInt8],
         importedAt: Date = Date(),
         sourceLabel: String = "文件导入") {
        self.id = id
        self.name = name
        self.bytes = bytes
        self.importedAt = importedAt
        self.sourceLabel = sourceLabel
    }

    var blockCount: Int { bytes.count / 16 }

    var uid: String { Hex.uid(Array(bytes.prefix(4))) }

    var typeLabel: String {
        switch bytes.count {
        case 1024: return "1K"
        case 4096: return "4K"
        default: return "\(bytes.count) B"
        }
    }

    var sizeLabel: String { "\(bytes.count) B" }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: importedAt)
    }

    func block(_ index: Int) -> [UInt8] {
        guard index >= 0, index < blockCount else { return [] }
        let start = index * 16
        return Array(bytes[start..<(start + 16)])
    }

    /// 1K 卡的第 3、7、11… 块是尾块（KEY A / 访问位 / KEY B）
    func isTrailer(_ index: Int) -> Bool { index % 4 == 3 }

    func sectorNumber(_ index: Int) -> Int { index / 4 }

    func sectorLabel(_ index: Int) -> String {
        if blockCount == 64 {
            return String(format: "S%02d", sectorNumber(index))
        }
        return String(format: "B%03d", index)
    }

    /// 是否与另一张卡尺寸一致（不一致时只比对较短的部分，并在界面显式提示）
    func hasSameSize(as other: CardDump) -> Bool { bytes.count == other.bytes.count }
}
