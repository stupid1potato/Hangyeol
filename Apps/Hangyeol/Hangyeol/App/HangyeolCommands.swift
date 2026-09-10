import AppKit
import SwiftUI

struct HangyeolWindowActions {
    var openSample: () -> Void
    var toggleFindReplace: () -> Void
    var exportPDF: () -> Void
    var printDocument: () -> Void
    var showHelp: () -> Void
}

private struct HangyeolWindowActionsKey: FocusedValueKey {
    typealias Value = HangyeolWindowActions
}

extension FocusedValues {
    var hangyeolActions: HangyeolWindowActions? {
        get { self[HangyeolWindowActionsKey.self] }
        set { self[HangyeolWindowActionsKey.self] = newValue }
    }
}

struct HangyeolCommands: Commands {
    @FocusedValue(\.hangyeolActions) private var actions

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(L10n.openSample) {
                actions?.openSample()
            }
            .disabled(actions == nil)
        }

        CommandGroup(after: .saveItem) {
            Button(L10n.exportPDF) {
                actions?.exportPDF()
            }
            .disabled(actions == nil)
            Button(L10n.printDocument) {
                actions?.printDocument()
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(actions == nil)
        }

        CommandGroup(after: .pasteboard) {
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
