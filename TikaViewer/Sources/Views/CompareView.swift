import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var tab: RootTab

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.panel.ignoresSafeArea()
                if let a = model.cardA, let b = model.cardB, a.id != b.id {
                    content(a: a, b: b, diff: CardDiff.make(a: a, b: b))
                } else {
                    VStack {
                        headerSub
                        EmptyHint(title: "需要两张不同的卡",
                                  message: "先在文件库导入两份 dump，\n再回到这里选择 A 与 B。")
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var headerSub: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("对比")
                    .font(Theme.ui(22, weight: .bold))
                    .foregroundColor(Theme.ink)
                Text("逐块逐字节 · 本机计算")
                    .font(Theme.ui(11.5))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func content(a: CardDump, b: CardDump, diff: CardDiff) -> some View {
        VStack(spacing: 0) {
            header(diff)
            pick(a, label: "A")
            versus
            pick(b, label: "B")
            stats(diff)
            filter

            ScrollView {
                LazyVStack(spacing: 0) {
                    if model.showDiffOnly {
                        if diff.blocks.isEmpty {
                            EmptyHint(title: "完全一致", message: "这两张卡的全部块与字节都相同。")
                        } else {
                            ForEach(diff.blocks) { item in
                                diffRow(a: diff.a, b: diff.b, block: item.block, offsets: item.offsets)
                            }
                        }
                    } else {
                        ForEach(0..<min(a.blockCount, b.blockCount), id: \.self) { block in
                            allRow(a: diff.a, b: diff.b, block: block, offsets: diff.offsets(for: block))
                        }
                    }
                    Color.clear.frame(height: 20)
                }
            }

            Button {
                tab = .report
            } label: {
                Text("生成差异报告")
            }
            .buttonStyle(GhostButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Theme.panel)
        }
    }

    private func header(_ diff: CardDiff) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("对比")
                    .font(Theme.ui(22, weight: .bold))
                    .foregroundColor(Theme.ink)
                Text("两份 dump · 逐块比对")
                    .font(Theme.ui(11.5))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            Chip(text: diff.isEmpty ? "完全一致" : "\(diff.blockCount) 处不同",
                 style: diff.isEmpty ? .on : .warn)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func pick(_ card: CardDump, label: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(Theme.mono(10, weight: .semibold))
                .foregroundColor(Color(red: 0.953, green: 0.969, blue: 0.953))
                .frame(width: 20, height: 20)
                .background(label == "A" ? Theme.teal : Color(red: 0.227, green: 0.259, blue: 0.239))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.uid)
                    .font(Theme.mono(13, weight: .semibold))
                    .foregroundColor(Theme.ink)
                Text(card.name)
                    .font(Theme.ui(10.5))
                    .foregroundColor(Theme.faint)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Menu {
                ForEach(model.cards) { item in
                    Button {
                        setCard(item, as: label)
                    } label: {
                        Text("\(item.uid) · \(item.name)")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(card.timeLabel)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                }
                .font(Theme.mono(10))
                .foregroundColor(Theme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.lineSoft).frame(height: 1).padding(.leading, 20)
        }
    }

    private func setCard(_ card: CardDump, as label: String) {
        if label == "A" { model.compareAID = card.id } else { model.compareBID = card.id }
    }

    private var versus: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Theme.line).frame(height: 1)
            Text("VERSUS")
                .font(Theme.mono(9, weight: .semibold))
                .foregroundColor(Theme.faint)
                .tracking(1.2)
            Rectangle().fill(Theme.line).frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func stats(_ diff: CardDiff) -> some View {
        HStack(spacing: 0) {
            stat("\(diff.sectorCount)", "差异扇区")
            divider
            stat("\(diff.blockCount)", "差异块")
            divider
            stat("\(diff.byteCount)", "差异字节")
        }
        .padding(.vertical, 9)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.line, lineWidth: 1)
        )
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.top, 2)
    }

    private var divider: some View {
        Rectangle().fill(Theme.line).frame(width: 1, height: 30)
    }

    private func stat(_ number: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(number)
                .font(Theme.mono(17, weight: .bold))
                .foregroundColor(Theme.diff)
            Text(title)
                .font(Theme.ui(9.5))
                .foregroundColor(Theme.faint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }

    private var filter: some View {
        HStack(spacing: 6) {
            filterButton("仅差异", active: model.showDiffOnly) { model.showDiffOnly = true }
            filterButton("全部块", active: !model.showDiffOnly) { model.showDiffOnly = false }
            Spacer()
            Text("按块索引排序")
                .font(Theme.ui(10))
                .foregroundColor(Theme.faint)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func filterButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.ui(11))
                .foregroundColor(active ? Color(red: 0.953, green: 0.969, blue: 0.953) : Theme.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(active ? Theme.teal : Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(active ? Theme.teal : Theme.line, lineWidth: 1)
                )
                .cornerRadius(7)
        }
        .buttonStyle(.plain)
    }

    private func diffRow(a: CardDump, b: CardDump, block: Int, offsets: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(a.sectorLabel(block))
                    .font(Theme.mono(10.5, weight: .semibold))
                    .foregroundColor(Theme.muted)
                Text("B\(block)")
                    .font(Theme.mono(10.5))
                    .foregroundColor(Theme.muted)
                if a.isTrailer(block) {
                    Text("尾块")
                        .font(Theme.ui(9.5))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Text("\(offsets.count) 字节")
                    .font(Theme.ui(9.5))
                    .foregroundColor(Theme.diff)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.diffSoft)
                    .cornerRadius(5)
            }

            hexLine(label: "A", values: a.block(block), offsets: offsets)
            hexLine(label: "B", values: b.block(block), offsets: offsets)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.lineSoft).frame(height: 1)
        }
    }

    private func allRow(a: CardDump, b: CardDump, block: Int, offsets: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(a.sectorLabel(block))
                    .font(Theme.mono(10.5))
                    .foregroundColor(offsets.isEmpty ? Theme.faint : Theme.muted)
                Text("B\(block)")
                    .font(Theme.mono(10.5))
                    .foregroundColor(offsets.isEmpty ? Theme.faint : Theme.muted)
                Spacer()
                if !offsets.isEmpty {
                    Text("\(offsets.count) 字节")
                        .font(Theme.ui(9.5))
                        .foregroundColor(Theme.diff)
                }
            }
            hexLine(label: "A", values: a.block(block), offsets: offsets)
            if !offsets.isEmpty {
                hexLine(label: "B", values: b.block(block), offsets: offsets)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.lineSoft).frame(height: 1)
        }
    }

    private func hexLine(label: String, values: [UInt8], offsets: [Int]) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text(label)
                .font(Theme.mono(9.5))
                .foregroundColor(Theme.faint)
                .frame(width: 12, alignment: .leading)
            HexText(values: values, offsets: offsets, size: 9.5)
        }
    }
}

/// 16 字节自动折行，差异字节标红
struct HexText: View {
    let values: [UInt8]
    let offsets: [Int]
    let size: CGFloat

    private var limited: [UInt8] {
        Array(values.prefix(16))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HexByteRow(values: Array(limited.prefix(8)), baseOffset: 0, highlight: Set(offsets), size: size)
            if limited.count > 8 {
                HexByteRow(values: Array(limited[8..<limited.count]), baseOffset: 8, highlight: Set(offsets), size: size)
            }
        }
    }
}
