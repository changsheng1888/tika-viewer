import SwiftUI

enum RootTab: Hashable {
    case library
    case detail
    case compare
    case report
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var tab: RootTab = .library

    var body: some View {
        TabView(selection: $tab) {
            LibraryView(tab: $tab)
                .tabItem { Label("文件库", systemImage: "folder") }
                .tag(RootTab.library)

            CardDetailView(tab: $tab)
                .tabItem { Label("详情", systemImage: "square.grid.3x3") }
                .tag(RootTab.detail)

            CompareView(tab: $tab)
                .tabItem { Label("对比", systemImage: "rectangle.on.rectangle") }
                .tag(RootTab.compare)

            ReportView(tab: $tab)
                .tabItem { Label("报告", systemImage: "doc.text") }
                .tag(RootTab.report)
        }
        .tint(Theme.teal)
        .onOpenURL { url in
            model.importURL(url)
        }
        .alert("导入失败",
               isPresented: Binding(get: { model.errorMessage != nil },
                                    set: { if !$0 { model.errorMessage = nil } })) {
            Button("好", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
