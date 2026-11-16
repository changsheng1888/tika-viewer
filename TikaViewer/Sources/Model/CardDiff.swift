import Foundation

struct BlockDiff: Identifiable, Hashable {
    let block: Int
    let offsets: [Int]

    var id: Int { block }
}

/// 两张卡逐块逐字节的比对结果
struct CardDiff {
    let a: CardDump
    let b: CardDump
    let blocks: [BlockDiff]
    let sizeMismatch: Bool

    var byteCount: Int { blocks.reduce(0) { $0 + $1.offsets.count } }
    var blockCount: Int { blocks.count }
    var isEmpty: Bool { blocks.isEmpty }

    var sectorCount: Int {
        Set(blocks.map { $0.block / 4 }).count
    }

    func offsets(for block: Int) -> [Int] {
        blocks.first(where: { $0.block == block })?.offsets ?? []
    }

    func hasDiff(block: Int) -> Bool {
        blocks.contains(where: { $0.block == block })
    }

    func trailerDiffCount(using card: CardDump) -> Int {
        blocks.filter { card.isTrailer($0.block) }.count
    }

    static func make(a: CardDump, b: CardDump) -> CardDiff {
        let limit = min(a.bytes.count, b.bytes.count)
        var blocks: [BlockDiff] = []
        var currentBlock = -1
        var offsets: [Int] = []

        var index = 0
        while index < limit {
            if a.bytes[index] != b.bytes[index] {
                let block = index / 16
                if block != currentBlock {
                    if currentBlock >= 0 {
                        blocks.append(BlockDiff(block: currentBlock, offsets: offsets))
                    }
                    currentBlock = block
                    offsets = []
                }
                offsets.append(index % 16)
            }
            index += 1
        }
        if currentBlock >= 0 {
            blocks.append(BlockDiff(block: currentBlock, offsets: offsets))
        }

        return CardDiff(a: a, b: b, blocks: blocks, sizeMismatch: a.bytes.count != b.bytes.count)
    }

    /// 导出的纯文本报告（与原型报告一致：整块内容 + 差异字节位置）
    func reportText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        var lines: [String] = []
        lines.append("差异报告 · 长生卡工具（iOS 只读版）")
        lines.append("生成时间：\(formatter.string(from: Date()))")
        lines.append("卡 A：\(a.uid)（\(a.name)，\(a.timeLabel) 读取）")
        lines.append("卡 B：\(b.uid)（\(b.name)，\(b.timeLabel) 读取）")
        lines.append("差异：\(sectorCount) 个扇区 / \(blockCount) 个块 / \(byteCount) 个字节")
        if sizeMismatch {
            lines.append("注意：两张卡尺寸不同（\(a.sizeLabel) 与 \(b.sizeLabel)），只比对了较短的部分。")
        }
        lines.append("")

        for item in blocks {
            let block = item.block
            lines.append("\(a.sectorLabel(block)) B\(String(format: "%02d", block))  字节 \(item.offsets.map { "#\($0)" }.joined(separator: " "))")
            lines.append("  A  \(Hex.bytes(a.block(block)))")
            lines.append("  B  \(Hex.bytes(b.block(block)))")
        }

        if blocks.isEmpty {
            lines.append("两张卡的全部块与字节完全一致。")
        }
        return lines.joined(separator: "\n")
    }
}
