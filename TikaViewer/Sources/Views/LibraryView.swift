import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var tab: RootTab

    @State private var importing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.panel.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    importArea
                    SectionLabel(left: "最近读取", right: "字节 → 块")
                    Hairline()
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(model.cards) { card in
                                cardRow(card)
                            }
                            if model.cards.isEmpty {
                                EmptyHint(title: "还没有卡数据",
                                          message: "点上面的按钮导入 .dump 文件；\n也可以从「文件」或微信里用本应用打开。")
                            }
                            legend
                            SectionLabel(left: "快捷", right: "本地计算")
                            Hairline()
                            quickRow
                            SectionLabel(left: "说明", right: "iOS 端不做 NFC")
                            Hairline()
                            Text("数据来自安卓端读卡导出的 dump。本机只做浏览与比对，不改原始文件，也不上传网络。")
                                .font(Theme.ui(11))
                                .foregroundColor(Theme.muted)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 28)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: allowedTypes,
                      allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls { model.importURL(url) }
            case .failure(let error):
                model.errorMessage = error.localizedDescription
            }
        }
    }

    private var allowedTypes: [UTType] {
        var types: [UTType] = [.data, .text]
        for ext in ["dump", "mfd", "bin", "tlk", "hex"] {
            if let type = UTType(filenameExtension: ext), !types.contains(type) {
                types.append(type)
            }
        }
        return types
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("文件库")
                    .font(Theme.ui(22, weight: .bold))
                    .foregroundColor(Theme.ink)
                Text("只读解析 · 文件不出本机")
                    .font(Theme.ui(11.5))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            Chip(text: "\(model.cards.count) 张")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var importArea: some View {
        VStack(spacing: 8) {
            Button {
                importing = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                    Text("从「文件」导入 dump")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Text("支持 .dump / .bin / .mfd · 1024 与 4096 字节 · HEX 文本")
                .font(Theme.ui(10.5))
                .foregroundColor(Theme.faint)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private func cardRow(_ card: CardDump) -> some View {
        Button {
            model.selectedCardID = card.id
            tab = .detail
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.uid)
                        .font(Theme.mono(15, weight: .semibold))
                        .foregroundColor(Theme.ink)
                    HStack(spacing: 6) {
                        Chip(text: "\(card.typeLabel) · 卡片", style: .on)
                        Chip(text: card.sizeLabel)
                    }
                    SectorStrip(card: card, diff: model.diff(for: card))
                        .padding(.top, 2)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(card.name)
                        .font(Theme.ui(10.5))
                        .foregroundColor(Theme.faint)
                    Text(card.timeLabel)
                        .font(Theme.ui(10.5))
                        .foregroundColor(Theme.faint)
                    Text(card.sourceLabel)
                        .font(Theme.ui(10.5))
                        .foregroundColor(Theme.faint)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.lineSoft)
                .frame(height: 1)
                .padding(.leading, 20)
        }
        .contextMenu {
            Button {
                model.selectedCardID = card.id
                tab = .detail
            } label: { Label("查看详情", systemImage: "square.grid.3x3") }
            Button(role: .destructive) {
                model.delete(card)
            } label: { Label("从列表移除", systemImage: "trash") }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Color(red: 0.788, green: 0.847, blue: 0.824), text: "已读到")
            legendItem(color: Theme.diff, text: "与对比卡不同")
            legendItem(color: .clear, text: "尾块", stroked: true)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func legendItem(color: Color, text: String, stroked: Bool = false) -> some View {
        HStack(spacing: 5) {
            Rectangle()
                .fill(color)
                .frame(width: 7, height: 7)
                .overlay(
                    Rectangle()
                        .stroke(stroked ? Theme.teal.opacity(0.35) : Color.clear, lineWidth: 1)
                )
            Text(text)
                .font(Theme.ui(10))
                .foregroundColor(Theme.faint)
        }
    }

    private var quickRow: some View {
        Button {
            tab = .compare
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.tealSoft)
                        .frame(width: 30, height: 30)
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.teal)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("上次对比 · A ↔ B")
                        .font(Theme.ui(12.5, weight: .semibold))
                        .foregroundColor(Theme.ink)
                    Text(quickSubtitle)
                        .font(Theme.ui(10))
                        .foregroundColor(Theme.faint)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.faint)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.lineSoft)
                .frame(height: 1)
                .padding(.leading, 20)
        }
    }

    private var quickSubtitle: String {
        guard let diff = model.currentDiff else { return "还没有可对比的两张卡" }
        if diff.isEmpty { return "\(diff.a.uid) 与 \(diff.b.uid) 完全一致" }
        return "\(diff.a.uid) · \(diff.blockCount) 处不同 · \(diff.byteCount) 字节"
    }
}
