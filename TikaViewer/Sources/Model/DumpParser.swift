import Foundation

/// 解析 .dump / .mfd / .bin 文件：
/// 1) 原始二进制 1024 或 4096 字节；
/// 2) HEX 文本（允许空格、换行、冒号、横线分隔），有效十六进制字符数为 2048 或 8192。
enum DumpParser {
    enum ParseError: LocalizedError {
        case empty
        case unsupportedSize(Int)
        case invalidHex

        var errorDescription: String? {
            switch self {
            case .empty:
                return "文件是空的，没有可解析的内容"
            case .unsupportedSize(let size):
                return "文件为 \(size) 字节，只支持 1024 或 4096 字节的 dump"
            case .invalidHex:
                return "HEX 文本的十六进制字符数不是 2048 或 8192，无法按 1K/4K 解析"
            }
        }
    }

    static func parse(data: Data) throws -> [UInt8] {
        guard !data.isEmpty else { throw ParseError.empty }
        let bytes = [UInt8](data)
        if bytes.count == 1024 || bytes.count == 4096 {
            // 防止「纯 HEX 文本恰好也是 1024/4096 字节」被当成二进制 dump
            if isHexTextLike(bytes) {
                if let text = String(data: data, encoding: .utf8) {
                    return try parse(text: text)
                }
            }
            return bytes
        }
        // 可能是文本 dump，按文本再解一次
        if let text = String(data: data, encoding: .utf8) {
            return try parse(text: text)
        }
        throw ParseError.unsupportedSize(bytes.count)
    }

    /// 全部字符都在十六进制/分隔符集合内，才怀疑它是文本 dump
    private static func isHexTextLike(_ bytes: [UInt8]) -> Bool {
        for b in bytes {
            switch b {
            case 0x30...0x39, 0x41...0x46, 0x61...0x66:   // 0-9 A-F a-f
                continue
            case 0x20, 0x09, 0x0A, 0x0D, 0x3A, 0x2D, 0x7C: // 空格 制表 换行 冒号 横线 竖线
                continue
            default:
                return false
            }
        }
        return true
    }

    static func parse(text: String) throws -> [UInt8] {
        let digits = text.filter { $0.isHexDigit }
        guard digits.count == 2048 || digits.count == 8192 else {
            throw ParseError.invalidHex
        }
        var result = [UInt8]()
        result.reserveCapacity(digits.count / 2)
        var index = digits.startIndex
        while index < digits.endIndex {
            let next = digits.index(index, offsetBy: 2, limitedBy: digits.endIndex) ?? digits.endIndex
            let pair = String(digits[index..<next])
            if let value = UInt8(pair, radix: 16) {
                result.append(value)
            }
            index = next
        }
        guard result.count == 1024 || result.count == 4096 else {
            throw ParseError.invalidHex
        }
        return result
    }
}
