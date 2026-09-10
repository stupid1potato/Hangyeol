import SwiftUI

@main
struct HangyeolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Closure so each untitled window gets its own DocumentSession
        // (value-template would share the class instance across New Document).
        DocumentGroup(newDocument: { HangyeolDocument() }) { file in
            DocumentWindow(document: file.$document, fileURL: file.fileURL)
                .environment(\.locale, Locale(identifier: "ko_KR"))
        }
        .commands {
            HangyeolCommands()
        }
        .defaultSize(width: 880, height: 640)
    }
}
