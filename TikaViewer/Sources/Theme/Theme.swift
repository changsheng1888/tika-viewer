import SwiftUI

/// 与原型一致的色板与字体：纸白工作台 + 墨色正文 + 单一青绿强调 + 差异朱红
enum Theme {
    static let paper = Color(red: 0.918, green: 0.922, blue: 0.898)
    static let panel = Color(red: 0.984, green: 0.984, blue: 0.969)
    static let card = Color.white
    static let ink = Color(red: 0.082, green: 0.102, blue: 0.094)
    static let muted = Color(red: 0.420, green: 0.451, blue: 0.431)
    static let faint = Color(red: 0.604, green: 0.631, blue: 0.612)
    static let line = Color(red: 0.846, green: 0.855, blue: 0.827)
    static let lineSoft = Color(red: 0.925, green: 0.929, blue: 0.906)

    static let teal = Color(red: 0.055, green: 0.357, blue: 0.318)
    static let tealSoft = Color(red: 0.875, green: 0.918, blue: 0.898)
    static let diff = Color(red: 0.659, green: 0.227, blue: 0.133)
    static let diffSoft = Color(red: 0.957, green: 0.875, blue: 0.847)
    static let warn = Color(red: 0.541, green: 0.416, blue: 0.094)
    static let warnSoft = Color(red: 0.957, green: 0.922, blue: 0.831)

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

enum Hex {
    static func byte(_ value: UInt8) -> String {
        String(format: "%02X", value)
    }

    static func bytes(_ values: [UInt8]) -> String {
        values.map(byte).joined(separator: " ")
    }

    static func bytes(_ values: ArraySlice<UInt8>) -> String {
        values.map(byte).joined(separator: " ")
    }

    static func uid(_ values: [UInt8]) -> String {
        Array(values.prefix(4)).map(byte).joined(separator: " ")
    }
}
