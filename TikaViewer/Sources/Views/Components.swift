import SwiftUI

struct Chip: View {
    enum Style { case plain, on, warn }
    let text: String
    var style: Style = .plain

    var body: some View {
        Text(text)
            .font(Theme.mono(10.5))
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .cornerRadius(6)
    }

    private var foreground: Color {
        switch style {
        case .plain: return Theme.muted
        case .on: return Theme.teal
        case .warn: return Theme.warn
        }
    }

    private var background: Color {
        switch style {
        case .plain: return Theme.lineSoft
        case .on: return Theme.tealSoft
        case .warn: return Theme.warnSoft
        }
    }
}

struct SectionLabel: View {
    let left: String
    let right: String

    var body: some View {
        HStack {
            Text(left)
            Spacer(minLength: 8)
            Text(right)
        }
        .font(Theme.ui(10.5))
        .foregroundColor(Theme.faint)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 7)
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
            .padding(.horizontal, 20)
    }
}

/// 64 格扇区条：已读到=浅青，尾块=描边，与当前对比对不同的块=朱红
struct SectorStrip: View {
    let card: CardDump
    let diff: CardDiff?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<64, id: \.self) { index in
                Rectangle()
                    .fill(color(at: index))
                    .frame(maxWidth: .infinity)
                    .frame(height: 14)
                    .cornerRadius(1)
                    .overlay(
                        Rectangle()
                            .stroke(card.blockCount <= 64 && card.isTrailer(index) ? Theme.teal.opacity(0.35) : Color.clear,
                                    lineWidth: 1)
                            .cornerRadius(1)
                    )
            }
        }
    }

    private func color(at index: Int) -> Color {
        let readTick = Color(red: 0.788, green: 0.847, blue: 0.824)
        if card.blockCount <= 64 {
            if let diff = diff, diff.hasDiff(block: index) { return Theme.diff }
            return readTick
        }
        // 4K：每格代表 4 块
        if let diff = diff {
            let changed = (0..<4).contains { diff.hasDiff(block: index * 4 + $0) }
            if changed { return Theme.diff }
        }
        return readTick
    }
}

/// 一行十六进制字节，差异位置高亮
struct HexByteRow: View {
    let values: [UInt8]
    let baseOffset: Int
    let highlight: Set<Int>
    var size: CGFloat = 9.5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<values.count, id: \.self) { index in
                Text(Hex.byte(values[index]))
                    .font(Theme.mono(size))
                    .foregroundColor(highlight.contains(baseOffset + index) ? Theme.diff : Theme.ink)
                    .background(highlight.contains(baseOffset + index) ? Theme.diffSoft : Color.clear)
            }
        }
    }
}

struct EmptyHint: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.ui(15, weight: .semibold))
                .foregroundColor(Theme.ink)
            Text(message)
                .font(Theme.ui(11.5))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 28)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.ui(14, weight: .semibold))
            .foregroundColor(Color(red: 0.953, green: 0.969, blue: 0.953))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.teal)
            .cornerRadius(13)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.ui(12.5, weight: .semibold))
            .foregroundColor(Theme.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Theme.teal.opacity(0.4), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
