import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var tab: RootTab
    @State private var sheetBlock: BlockRef?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.panel.ignoresSafeArea()
                if let card = model.selectedCard {
                    content(card)
                } else {
                    EmptyHint(title: "还没有选中的卡", message: "先在文件库导入一份 dump，再点开查看。")
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $sheetBlock) { ref in
            BlockDetailView(card: model.selectedCard, block: ref.id, offsets: offsets(for: ref.id))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func offsets(for block: Int) -> [Int] {
        guard let card = model.selectedCard, let diff = model.diff(for: card) else { return [] }
        return diff.offsets(for: block)
    }

    private func content(_ card: CardDump) -> some View {
        VStack(spacing: 0) {
            navRow(card)
            hero(card)
            Hairline()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(stride(from: 0, to: card.blockCount, by: 4)), id: \.self) { start in
                        sectorGroup(card, start: start)
                    }
                    Color.clear.frame(height: 20)
                }
            }
        }
    }

    private func navRow(_ card: CardDump) -> some View {
        HStack {
            Button {
                tab = .library
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("文件库")
                        .font(Theme.ui(12.5))
                }
                .foregroundColor(Theme.teal)
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                ForEach(model.cards) { item in
                    Button {
                        model.selectedCardID = item.id
                    } label: {
                        Text("\(item.uid) · \(item.name)")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("切换")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .font(Theme.ui(12))
                .foregroundColor(Theme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func hero(_ card: CardDump) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(card.uid)
                    .font(Theme.mono(25, weight: .bold))
                    .foregroundColor(Theme.ink)
                Chip(text: "\(card.typeLabel) · \(card.sizeLabel)", style: .on)
            }
            .padding(.top, 2)

            HStack(spacing: 0) {
                fact("块数", "\(card.blockCount) 块")
                fact("差异块", diffCount(card), highlight: diffCount(card) != "0" && diffCount(card) != "—")
                fact("读取", card.timeLabel)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func fact(_ key: String, _ value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key)
                .font(Theme.ui(9.5))
                .foregroundColor(Theme.faint)
            Text(value)
                .font(Theme.mono(11.5, weight: .semibold))
                .foregroundColor(highlight ? Theme.diff : Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 7)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }

    private func diffCount(_ card: CardDump) -> String {
        guard let diff = model.diff(for: card) else { return "—" }
        return "\(diff.blockCount)"
    }

    private func sectorGroup(_ card: CardDump, start: Int) -> some View {
        let offsets = offsetsMap(card)
        let short = card.blockCount == 64
        let rangeText = short ? "B\(start)–B\(min(start + 3, card.blockCount - 1))"
                              : "共 \(min(4, card.blockCount - start)) 块"
        let sectorText = short ? String(format: "S%02d", start / 4) : String(format: "B%03d", start)
        let changed = (start..<min(start + 4, card.blockCount)).contains { !(offsets[$0] ?? []).isEmpty }

        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(sectorText)
                    .font(Theme.mono(10.5, weight: .semibold))
                    .foregroundColor(Theme.teal)
                Text(rangeText)
                    .font(Theme.mono(10.5))
                    .foregroundColor(Theme.muted)
                Spacer()
                if changed {
                    Text("与对比卡不同")
                        .font(Theme.ui(9.5))
                        .foregroundColor(Theme.diff)
                }
            }
            .padding(.top, 10)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(0..<4, id: \.self) { offset in
                    let block = start + offset
                    if block < card.blockCount {
                        Button {
                            sheetBlock = BlockRef(id: block)
                        } label: {
                            BlockCell(card: card, block: block, offsets: offsets[block] ?? [])
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func offsetsMap(_ card: CardDump) -> [Int: [Int]] {
        guard let diff = model.diff(for: card) else { return [:] }
        var map: [Int: [Int]] = [:]
        for item in diff.blocks { map[item.block] = item.offsets }
        return map
    }
}

struct BlockRef: Identifiable {
    let id: Int
}

struct BlockCell: View {
    let card: CardDump
    let block: Int
    let offsets: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text("B\(block)")
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 2)
                Text(tag)
                    .font(Theme.ui(9))
                    .foregroundColor(offsets.isEmpty ? Theme.faint : Theme.diff)
            }

            if card.isTrailer(block) {
                keyRow("KEY A", Array(card.block(block).prefix(6)), base: 0)
                keyRow("访问位", Array(card.block(block)[6..<10]), base: 6)
                keyRow("KEY B", Array(card.block(block)[10..<16]), base: 10)
            } else {
                HexByteRow(values: Array(card.block(block).prefix(8)), baseOffset: 0, highlight: Set(offsets))
                HexByteRow(values: Array(card.block(block)[8..<16]), baseOffset: 8, highlight: Set(offsets))
            }
        }
        .padding(6)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(offsets.isEmpty ? Theme.line : Theme.diff.opacity(0.45), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var tag: String {
        if !offsets.isEmpty { return "差异 \(offsets.count)B" }
        if block == 0 { return "UID" }
        return card.isTrailer(block) ? "尾块" : "数据"
    }

    private var backgroundColor: Color {
        if !offsets.isEmpty { return Color(red: 0.988, green: 0.961, blue: 0.949) }
        if card.isTrailer(block) { return Color(red: 0.969, green: 0.973, blue: 0.953) }
        return Theme.card
    }

    private func keyRow(_ label: String, _ values: [UInt8], base: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(Theme.ui(8.5))
                .foregroundColor(Theme.faint)
                .frame(width: 37, alignment: .leading)
            HexByteRow(values: values, baseOffset: base, highlight: Set(offsets), size: 9)
        }
    }
}
