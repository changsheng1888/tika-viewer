import Foundation

// 仅用于 Linux/macOS 上对「解析 + 比对」纯逻辑做真机外的自动校验：
// 这些文件不依赖 SwiftUI，因此可以用 swiftc 直接编译运行。
// 运行方式：swiftc -O _selftest/model_selftest.swift Sources/Model/CardDump.swift Sources/Model/DumpParser.swift Sources/Model/CardDiff.swift _selftest/HexStub.swift -o selftest && ./selftest

var failures = 0
var checks = 0

func check(_ name: String, _ condition: Bool, _ detail: String = "") {
    checks += 1
    if condition {
        print("PASS  \(name)")
    } else {
        failures += 1
        print("FAIL  \(name)  \(detail)")
    }
}

func makeBytes(_ count: Int, seed: UInt8 = 0) -> [UInt8] {
    var out = [UInt8]()
    out.reserveCapacity(count)
    for i in 0..<count {
        out.append(UInt8((i &+ Int(seed)) % 251))
    }
    return out
}

// 1. 原始二进制
let raw1k = makeBytes(1024, seed: 7)
let raw4k = makeBytes(4096, seed: 11)
do {
    let parsed = try DumpParser.parse(data: Data(raw1k))
    check("binary 1024 解析一致", parsed == raw1k)
    let parsed4k = try DumpParser.parse(data: Data(raw4k))
    check("binary 4096 解析一致", parsed4k == raw4k && parsed4k.count == 4096)
} catch {
    check("binary 解析不抛错", false, "\(error)")
}

// 2. HEX 文本（含空格/冒号/横线/换行）
let hex1k = raw1k.map { String(format: "%02X", $0) }.joined(separator: " ")
var messy = ""
for (i, token) in hex1k.split(separator: " ").enumerated() {
    messy += token
    if i % 16 == 15 { messy += "\n" }
    else if i % 16 == 7 { messy += ":" }
    else { messy += " " }
}
do {
    let parsed = try DumpParser.parse(text: messy)
    check("HEX 文本（带分隔符）解析一致", parsed == raw1k, "count \(parsed.count)")
    let tight = raw1k.map { String(format: "%02X", $0) }.joined()
    let parsedTight = try DumpParser.parse(text: tight)
    check("HEX 文本（无分隔）解析一致", parsedTight == raw1k)
} catch {
    check("HEX 文本解析不抛错", false, "\(error)")
}

// 3. 错误输入
do {
    _ = try DumpParser.parse(data: Data())
    check("空文件应报错", false)
} catch DumpParser.ParseError.empty {
    check("空文件报 empty", true)
} catch {
    check("空文件报 empty", false, "\(error)")
}

do {
    _ = try DumpParser.parse(data: Data(makeBytes(512)))
    check("512 字节应报错", false)
} catch DumpParser.ParseError.unsupportedSize(let size) {
    check("512 字节报 unsupportedSize(512)", size == 512, "\(size)")
} catch {
    check("512 字节报 unsupportedSize", false, "\(error)")
}

do {
    _ = try DumpParser.parse(text: String(repeating: "A", count: 1000))
    check("1000 字符 HEX 应报错", false)
} catch DumpParser.ParseError.invalidHex {
    check("1000 字符 HEX 报 invalidHex", true)
} catch {
    check("1000 字符 HEX 报 invalidHex", false, "\(error)")
}

// 3.1 纯 HEX 文本恰好 1024/4096 字节时，不能被当成二进制 dump
do {
    _ = try DumpParser.parse(data: Data(String(repeating: "A", count: 1024).utf8))
    check("1024 字节纯十六进制文本应报错", false)
} catch DumpParser.ParseError.invalidHex {
    check("1024 字节纯十六进制文本报 invalidHex", true)
} catch {
    check("1024 字节纯十六进制文本报 invalidHex", false, "\(error)")
}

do {
    let text = (0..<1024).map { String(format: "%02X", $0 % 256) }.joined(separator: " ")
    let parsed = try DumpParser.parse(data: Data(text.utf8))
    check("带分隔的 HEX 文本按文本解析", parsed.count == 1024 && parsed[0] == 0 && parsed[1023] == 255,
          "count \(parsed.count)")
} catch {
    check("带分隔的 HEX 文本按文本解析", false, "\(error)")
}

// 4. 比对：构造已知差异
var a = makeBytes(1024, seed: 3)
var b = a
b[3 * 16 + 0] = b[3 * 16 + 0] ^ 0xFF
b[3 * 16 + 1] += 1
b[3 * 16 + 15] = b[3 * 16 + 15] ^ 0x0F
b[20 * 16 + 7] = b[20 * 16 + 7] ^ 0x80

let cardA = CardDump(name: "A", bytes: a)
let cardB = CardDump(name: "B", bytes: b)
let diff = CardDiff.make(a: cardA, b: cardB)

check("差异块数与顺序", diff.blocks.map { $0.block } == [3, 20], "\(diff.blocks.map { $0.block })")
check("第 3 块差异字节", diff.offsets(for: 3) == [0, 1, 15], "\(diff.offsets(for: 3))")
check("第 20 块差异字节", diff.offsets(for: 20) == [7], "\(diff.offsets(for: 20))")
check("差异字节总数", diff.byteCount == 4, "\(diff.byteCount)")
check("差异扇区数", diff.sectorCount == 2, "\(diff.sectorCount)")
check("尾块差异计数", diff.trailerDiffCount(using: cardA) == 1, "\(diff.trailerDiffCount(using: cardA))")
check("hasDiff(block:)", diff.hasDiff(block: 3) && !diff.hasDiff(block: 4))

// 5. 完全一致
let same = CardDiff.make(a: cardA, b: cardA)
check("相同卡无差异", same.isEmpty && same.byteCount == 0 && same.blockCount == 0)

// 6. 尺寸不一致只比短边
var shortBytes = makeBytes(1024, seed: 3)
shortBytes[5 * 16] ^= 0xFF
let shortB = CardDump(name: "1K", bytes: shortBytes)
let bigA = CardDump(name: "4K", bytes: makeBytes(4096, seed: 3))
let mixed = CardDiff.make(a: bigA, b: shortB)
check("尺寸不一致标记", mixed.sizeMismatch)
check("尺寸不一致只比 1024", mixed.blocks.map { $0.block } == [5], "\(mixed.blocks.map { $0.block })")

// 7. 模型属性
check("UID 格式化", cardA.uid == "03 04 05 06", cardA.uid)
check("块数", cardA.blockCount == 64, "\(cardA.blockCount)")
check("类型标签", cardA.typeLabel == "1K" && CardDump(name: "4", bytes: raw4k).typeLabel == "4K")
check("尾块判断", cardA.isTrailer(3) && cardA.isTrailer(63) && !cardA.isTrailer(2))
check("扇区号与标签", cardA.sectorNumber(17) == 4 && cardA.sectorLabel(17) == "S04", cardA.sectorLabel(17))
let big = CardDump(name: "4K", bytes: raw4k)
check("4K 标签走块号", big.sectorLabel(17) == "B017", big.sectorLabel(17))
check("block 越界返回空", cardA.block(64).isEmpty && cardA.block(-1).isEmpty)

// 8. 报告文本
let report = diff.reportText()
check("报告含差异统计", report.contains("2 个扇区") && report.contains("2 个块") && report.contains("4 个字节"), report)
check("报告含两块位置", report.contains("S00") && report.contains("S05"))
check("报告无异常空行", !report.contains("\n\n\n"))

// 9. Codable 往返（文件库持久化）
do {
    let data = try JSONEncoder().encode([cardA])
    let back = try JSONDecoder().decode([CardDump].self, from: data)
    check("Codable 往返", back.count == 1 && back[0].bytes == cardA.bytes && back[0].uid == cardA.uid)
} catch {
    check("Codable 往返", false, "\(error)")
}

print("---")
print("checks: \(checks), failures: \(failures)")
exit(failures == 0 ? 0 : 1)
