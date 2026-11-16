import SwiftUI
import UIKit

struct ReportView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var tab: RootTab

    private var diff: CardDiff? { model.currentDiff }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.panel.ignoresSafeArea()
                if let diff = diff {
                    content(diff)
                } else {
                    VStack {
                        header
                        EmptyHint(title: "还没有可生成的报告", message: "先导入两份 dump，再回到对比页看看差异。")
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("差异报告")
                    .font(Theme.ui(22, weight: .bold))
                    .foregroundColor(Theme.ink)
                Text(dateLine)
                    .font(Theme.ui(11.5))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            Chip(text: "只读")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return "\(formatter.string(from: Date())) · 本机生成"
    }

    private func content(_ diff: CardDiff) -> some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(diff.byteCount)")
                            .font(Theme.mono(34, weight: .bold))
                            .foregroundColor(Theme.ink)
                        Text("字节不同 · \(diff.blockCount) 块")
                            .font(Theme.ui(11))
                            .foregroundColor(Theme.muted)
                    }

                    Text(leadText(diff))
                        .font(Theme.ui(11.5))
                        .foregroundColor(Theme.muted)
                        .lineSpacing(5)
                        .padding(.top, 10)

                    if diff.sizeMismatch {
                        Text("注意：两张卡尺寸不同（\(diff.a.sizeLabel) 与 \(diff.b.sizeLabel)），只比对了较短的部分。")
                            .font(Theme.ui(11))
                            .foregroundColor(Theme.warn)
                            .padding(.top, 8)
                    }

                    distribution(diff)
                    table(diff)
                    conclusion(diff)
                    signature(diff)
                    suggestion(diff)
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }

            HStack(spacing: 8) {
                ShareLink(item: diff.reportText()) {
                    Text("导出 .txt")
                        .font(Theme.ui(12.5, weight: .semibold))
                        .foregroundColor(Color(red: 0.953, green: 0.969, blue: 0.953))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Theme.teal)
                        .cornerRadius(11)
                }
                Button {
                    UIPasteboard.general.string = diff.reportText()
                } label: {
                    Text("复制摘要")
                }
                .buttonStyle(GhostButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Theme.panel)
        }
    }

    private func leadText(_ diff: CardDiff) -> String {
        if diff.isEmpty {
            return "两份 dump 全部块与字节一致，没有发现任何差异。"
        }
        let trailer = diff.trailerDiffCount(using: diff.a)
        let dataBlocks = diff.blockCount - trailer
        return "两份 dump 同为 \(diff.a.blockCount) 块、每块 16 字节。差异分布在 \(diff.sectorCount) 个扇区，其中 \(trailer) 处落在尾块（密钥或访问位），\(dataBlocks) 处为数据块。"
    }

    private func distribution(_ diff: CardDiff) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<16, id: \.self) { sector in
                    let changed = diff.blocks.contains { $0.block / 4 == sector }
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(changed ? Theme.diffSoft : Color(red: 0.890, green: 0.906, blue: 0.875))
                        if changed {
                            Circle()
                                .fill(Theme.diff)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 26)
                }
            }
            HStack {
                Text("S00")
                Spacer()
                Text("差异扇区分布 · 16 扇区")
                Spacer()
                Text("S15")
            }
            .font(Theme.ui(9))
            .foregroundColor(Theme.faint)
        }
        .padding(.top, 16)
    }

    private func table(_ diff: CardDiff) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("位置").frame(width: 74, alignment: .leading)
                Text("字节").frame(width: 58, alignment: .leading)
                Text("卡 A").frame(maxWidth: .infinity, alignment: .leading)
                Text("卡 B").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(Theme.ui(9))
            .foregroundColor(Theme.faint)
            .padding(.bottom, 6)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.line).frame(height: 1)
            }

            ForEach(diff.blocks) { item in
                HStack(alignment: .top, spacing: 4) {
                    Text(position(diff.a, item.block))
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.ink)
                        .frame(width: 74, alignment: .leading)
                    Text(rangeText(item.offsets))
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.muted)
                        .frame(width: 58, alignment: .leading)
                    Text(item.offsets.map { Hex.byte(diff.a.block(item.block)[$0]) }.joined(separator: " "))
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.offsets.map { Hex.byte(diff.b.block(item.block)[$0]) }.joined(separator: " "))
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.diff)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 7)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Theme.lineSoft).frame(height: 1)
                }
            }
        }
        .padding(.top, 14)
    }

    private func position(_ card: CardDump, _ block: Int) -> String {
        if card.blockCount == 64 {
            return String(format: "S%02d B%02d", block / 4, block)
        }
        return String(format: "B%03d", block)
    }

    private func rangeText(_ offsets: [Int]) -> String {
        guard let first = offsets.first, let last = offsets.last else { return "—" }
        if offsets.count > 1, last - first == offsets.count - 1 {
            return "#\(first)–#\(last)"
        }
        return offsets.map { "#\($0)" }.joined(separator: " ")
    }

    private func conclusion(_ diff: CardDiff) -> some View {
        Group {
            if diff.isEmpty {
                Text("两张卡完全一致，无需处理。")
            } else {
                let trailerBlocks = diff.blocks.filter { diff.a.isTrailer($0.block) }.map { diff.a.sectorLabel($0.block) }
                Text("尾块差异落在 \(trailerBlocks.isEmpty ? "—" : trailerBlocks.joined(separator: "、"))。若两次读取本应一致，写卡前以 A 为准；导出的 .txt 保留完整 16 字节块，便于逐块复核。")
            }
        }
        .font(Theme.ui(11))
        .foregroundColor(Color(red: 0.235, green: 0.271, blue: 0.251))
        .lineSpacing(5)
        .padding(.leading, 10)
        .padding(.vertical, 2)
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.teal).frame(width: 2)
        }
        .padding(.top, 16)
    }

    private func signature(_ diff: CardDiff) -> some View {
        HStack(alignment: .top, spacing: 12) {
            signatureCell(diff.a)
            signatureCell(diff.b)
        }
        .padding(.top, 16)
    }

    private func signatureCell(_ card: CardDump) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Rectangle().fill(Theme.teal).frame(height: 2)
            Text(card.uid)
                .font(Theme.mono(11, weight: .semibold))
                .foregroundColor(Theme.ink)
                .padding(.top, 6)
            Text("\(card.typeLabel) · \(card.sizeLabel)")
                .font(Theme.ui(9.5))
                .foregroundColor(Theme.faint)
            Text("\(card.timeLabel) 读取")
                .font(Theme.ui(9.5))
                .foregroundColor(Theme.faint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func suggestion(_ diff: CardDiff) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("核对建议")
                .font(Theme.ui(10))
                .foregroundColor(Theme.faint)
                .tracking(1)
            suggestionLine("01", "尾块差异只影响密钥/访问位时，先确认两次读取用的是同一张卡，再决定以哪次为准。")
            suggestionLine("02", "数据块差异先核对扇区用途；改过楼层或有效期的卡，这类差异通常是有意的。")
            suggestionLine("03", "导出的 .txt 含 16 字节整块，可在电脑版逐字节复核后再重新读一次卡。")
        }
        .padding(.top, 18)
    }

    private func suggestionLine(_ index: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(index)
                .font(Theme.mono(9))
                .foregroundColor(Theme.teal)
            Text(text)
                .font(Theme.ui(11))
                .foregroundColor(Color(red: 0.235, green: 0.271, blue: 0.251))
                .lineSpacing(4)
        }
    }
}
