import SwiftUI

@main
struct HangyeolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        DocumentGroup(newDocument: HangyeolDocument()) { file in
            DocumentWindow(document: file.$document, fileURL: file.fileURL)
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .onAppear {
                    if let url = file.fileURL {
                        RecentDocuments.shared.noteOpened(url)
                    }
                }
        }
        .commands {
            HangyeolCommands()
        }
        .defaultSize(width: 880, height: 640)
    }
}
