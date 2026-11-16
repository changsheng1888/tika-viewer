import Foundation

// 自检专用：Linux 上没有 SwiftUI，无法引用 Theme.swift 里的 Hex，
// 这里按完全相同的实现补一份，仅用于编译纯逻辑文件做校验。
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
