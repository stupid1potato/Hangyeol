import AppKit
import SwiftUI

struct HangyeolWindowActions {
    var openSample: () -> Void
    var openDocument: () -> Void
    var openRecent: (RecentDocuments.Item) -> Void
    var clearRecents: () -> Void
    var toggleFindReplace: () -> Void
    var exportPDF: () -> Void
    var printDocument: () -> Void
    var showHelp: () -> Void
    var canExportPDF: Bool
    var canPrint: Bool
    var exportHelp: String
    var printHelp: String
}

private struct HangyeolWindowActionsKey: FocusedValueKey {
    typealias Value = HangyeolWindowActions
}

private struct HangyeolRecentsKey: FocusedValueKey {
    typealias Value = [RecentDocuments.Item]
}

extension FocusedValues {
    var hangyeolActions: HangyeolWindowActions? {
        get { self[HangyeolWindowActionsKey.self] }
        set { self[HangyeolWindowActionsKey.self] = newValue }
    }

    var hangyeolRecents: [RecentDocuments.Item]? {
        get { self[HangyeolRecentsKey.self] }
        set { self[HangyeolRecentsKey.self] = newValue }
    }
}

struct HangyeolCommands: Commands {
    @FocusedValue(\.hangyeolActions) private var actions
    @FocusedValue(\.hangyeolRecents) private var recents

    var body: some Commands {
        // DocumentGroup의 New/Open/Open Recent를 교체하지 않습니다.
        // replacing: .newItem 은 PlatformDocumentController 초기화 중
        // createDocumentClassIfNeeded 에서 SIGSEGV를 유발합니다.
        CommandGroup(after: .newItem) {
            Button(L10n.openDocument) {
                if let openDocument = actions?.openDocument {
                    openDocument()
                } else {
                    FileOpening.presentOpenPanel()
                }
            }

            Menu(L10n.recents) {
                if let recents, !recents.isEmpty {
                    ForEach(recents) { item in
                        Button(item.title) {
                            actions?.openRecent(item)
                        }
                    }
                    Divider()
                    Button(L10n.clearRecents) {
                        actions?.clearRecents()
                    }
                    .disabled(actions == nil)
                } else {
                    Button(L10n.recentsEmpty) {}
                        .disabled(true)
                }
            }

            Button(L10n.openSample) {
                actions?.openSample()
            }
            .disabled(actions == nil)
        }

        CommandGroup(after: .saveItem) {
            Button(L10n.exportPDF) {
                actions?.exportPDF()
            }
            .disabled(actions?.canExportPDF != true)
            .help(actions?.exportHelp ?? L10n.exportEmptyHint)
            .accessibilityHint(actions?.exportHelp ?? L10n.exportEmptyHint)
            Button(L10n.printDocument) {
                actions?.printDocument()
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(actions?.canPrint != true)
            .help(actions?.printHelp ?? L10n.printEmptyHint)
            .accessibilityHint(actions?.printHelp ?? L10n.printEmptyHint)
        }

        CommandGroup(after: .pasteboard) {
            // Edit → Undo/Redo stays the system menu (window UndoManager).
            // DocumentSession registers live session edits automatically.
            Button(L10n.find) {
                actions?.toggleFindReplace()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(actions == nil)
        }

        CommandGroup(replacing: .help) {
            Button(L10n.help) {
                actions?.showHelp()
            }
            .disabled(actions == nil)
            Divider()
            Button(L10n.about) {
                NSApp.orderFrontStandardAboutPanel(options: [
                    .applicationName: L10n.appName
                ])
            }
        }
    }
}
