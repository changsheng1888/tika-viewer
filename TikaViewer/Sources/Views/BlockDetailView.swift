import SwiftUI

struct BlockDetailView: View {
    @EnvironmentObject private var model: AppModel
    let card: CardDump?
    let block: Int
    let offsets: [Int]

    @Environment(\.dismiss) private var dismiss

    private var partner: CardDump? {
        guard let card = card else { return nil }
        if let a = model.cardA, a.id == card.id { return model.cardB }
        return model.cardA
    }

    var body: some View {
        ZStack {
            Theme.panel.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("块 \(block)")
                        .font(Theme.ui(17, weight: .bold))
                        .foregroundColor(Theme.ink)
                    Text(subtitle)
                        .font(Theme.ui(10))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Button("关闭") { dismiss() }
                        .font(Theme.ui(12.5))
                        .foregroundColor(Theme.teal)
                }
                .padding(.top, 8)

                if let card = card {
                    HexByteRow(values: Array(card.block(block).prefix(8)), baseOffset: 0, highlight: Set(offsets), size: 11)
                        .padding(.top, 14)
                    HexByteRow(values: Array(card.block(block)[8..<16]), baseOffset: 8, highlight: Set(offsets), size: 11)
                        .padding(.top, 4)

                    if let partner = partner, partner.id != card.id, !offsets.isEmpty {
                        Text("对比值")
                            .font(Theme.ui(9.5))
                            .foregroundColor(Theme.faint)
                            .padding(.top, 14)
                        HexByteRow(values: Array(partner.block(block).prefix(8)), baseOffset: 0, highlight: Set(offsets), size: 11)
                            .padding(.top, 5)
                        HexByteRow(values: Array(partner.block(block)[8..<16]), baseOffset: 8, highlight: Set(offsets), size: 11)
                            .padding(.top, 4)
                    }

                    HStack(alignment: .top, spacing: 0) {
                        kv("差异字节", offsets.isEmpty ? "无" : "\(offsets.count) 个 · " + offsets.map { "#\($0)" }.joined(separator: " "),
                           highlight: !offsets.isEmpty)
                        kv("字节偏移", String(format: "%04d – %04d", block * 16, block * 16 + 15))
                    }
                    .padding(.top, 18)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var subtitle: String {
        guard let card = card else { return "" }
        let sector = card.sectorLabel(block)
        return "\(sector) · \(card.isTrailer(block) ? "尾块（密钥/访问位）" : "数据块")"
    }

    private func kv(_ key: String, _ value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key)
                .font(Theme.ui(9.5))
                .foregroundColor(Theme.faint)
            Text(value)
                .font(Theme.mono(10.5))
                .foregroundColor(highlight ? Theme.diff : Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 7)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }
}
