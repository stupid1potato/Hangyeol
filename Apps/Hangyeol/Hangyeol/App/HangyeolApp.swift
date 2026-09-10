import SwiftUI

@main
struct HangyeolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Autoclosure factory: each New Document gets its own DocumentSession.
        // `{ HangyeolDocument() }` is inferred as Document on current SDK and
        // does not conform to FileDocument.
        DocumentGroup(newDocument: HangyeolDocument()) { file in
            DocumentWindow(document: file.$document, fileURL: file.fileURL)
                .environment(\.locale, Locale(identifier: "ko_KR"))
        }
        .commands {
            HangyeolCommands()
        }
        .defaultSize(width: 880, height: 640)
    }
}
