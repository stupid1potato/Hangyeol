import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DocumentWindow: View {
    @Binding var document: HangyeolDocument
    var fileURL: URL?
    /// Preview / tests. Live windows use `document.hasUnsavedEdits`.
    var isEditedOverride: Bool? = nil

    @Environment(\.openDocument) private var openDocument
    @ObservedObject private var recents = RecentDocuments.shared
    @StateObject private var exportFailure = RetryableFailure()
    @StateObject private var reopenFailure = RetryableFailure()
    @State private var showFindReplace = false
    @State private var findQuery = ""
    @State private var replaceQuery = ""
    @State private var lastReplacementCount: Int?
    @State private var replaceStatusFocusToken = 0
    @State private var presentedError: HangyeolError?
    @State private var showHelp = false
    @State private var isDropTargeted = false
    @State private var dismissedSaveErrorID: String?

    private var chrome: DocumentChromeState {
        DocumentChromeState.make(
            title: document.model.displayTitle,
            isEditedOverride: isEditedOverride,
            hasUnsavedEdits: document.hasUnsavedEdits
        )
    }

    private var sessionSaveError: HangyeolError? {
        SessionSaveFailurePresentation.presentedError(
            lastSaveError: document.session.lastSaveError,
            dismissedID: dismissedSaveErrorID
        )
    }

    private var findReplacePresentation: FindReplacePresentation {
        FindReplacePresentation.make(
            canReplace: document.session.canReplace,
            query: findQuery,
            lastReplacementCount: lastReplacementCount,
            statusFocusToken: replaceStatusFocusToken
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if showFindReplace {
                FindReplaceBar(
                    query: $findQuery,
                    replacement: $replaceQuery,
                    presentation: findReplacePresentation,
                    onFind: {},
                    onReplace: replaceInDocument,
                    onClose: { showFindReplace = false }
                )
                Divider()
            }

            if document.model.isEmpty {
                EmptyStateView(
                    recents: recents.items,
                    onOpenSample: loadSample,
                    onOpenDocument: presentOpenPanel,
                    onOpenRecent: openRecent
                )
            } else {
                // Sketch: in-memory TableBlock Binding only. Do not call
                // DocumentSession / HangyeolKit listTables or setCellText here.
                StructuredTextView(
                    model: $document.model,
                    tablesEditable: true
                )
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .padding(12)
                    .overlay {
                        Text(L10n.dropToOpen)
                            .font(.title2.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            FileOpening.handleDrop(providers: providers)
        }
        .navigationTitle(chrome.title)
        .hangyeolEditedSubtitle(chrome.navigationSubtitle)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if chrome.isEdited {
                    Text(L10n.edited)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                        .accessibilityLabel(L10n.edited)
                        .accessibilityIdentifier("document-edited-badge")
                }

                Button {
                    showFindReplace.toggle()
                } label: {
                    Label(L10n.find, systemImage: "magnifyingglass")
                }
                .help(L10n.find)

                Button(action: exportPDF) {
                    Label(L10n.exportPDF, systemImage: "arrow.up.doc")
                }
                .help(L10n.exportPDF)

                Button {
                    PrintCoordinator.print(document.model)
                } label: {
                    Label(L10n.printDocument, systemImage: "printer")
                }
                .help(L10n.printDocument)
            }
        }
        .sheet(item: $presentedError) { error in
            ErrorSheet(error: error) {
                presentedError = nil
            }
        }
        .sheet(item: sessionSaveErrorBinding) { error in
            SaveFailureSheet(
                error: error,
                title: L10n.saveFailureTitle,
                retryTitle: L10n.retrySave,
                retryHint: L10n.saveFailureRetryHint,
                onRetry: retryDocumentSave,
                onDismiss: { dismissedSaveErrorID = error.id }
            )
        }
        .sheet(item: exportFailure.sheetBinding) { error in
            SaveFailureSheet(
                error: error,
                title: L10n.exportFailureTitle,
                retryTitle: L10n.retry,
                retryHint: L10n.saveFailureRetryHint,
                onRetry: { exportFailure.retry() },
                onDismiss: { exportFailure.dismiss() }
            )
        }
        .sheet(item: reopenFailure.sheetBinding) { error in
            ErrorSheet(
                error: error,
                title: L10n.reopenFailureTitle,
                retryTitle: L10n.retryOpen,
                retryHint: L10n.reopenRetryHint,
                onRetry: { reopenFailure.retry() },
                onDismiss: { reopenFailure.dismiss() }
            )
        }
        .alert(L10n.help, isPresented: $showHelp) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.helpBody)
        }
        .focusedSceneValue(\.hangyeolActions, HangyeolWindowActions(
            openSample: loadSample,
            openDocument: presentOpenPanel,
            openRecent: openRecent,
            clearRecents: { recents.clear() },
            toggleFindReplace: { showFindReplace.toggle() },
            exportPDF: exportPDF,
            printDocument: { PrintCoordinator.print(document.model) },
            showHelp: { showHelp = true }
        ))
        .focusedSceneValue(\.hangyeolRecents, recents.items)
        .onAppear {
            FileOpening.install(openDocument: openDocument)
            if let fileURL {
                recents.noteOpened(fileURL)
            }
        }
        .onChange(of: fileURL) { _, url in
            if let url {
                recents.noteOpened(url)
            }
        }
        .onChange(of: findQuery) { _, _ in
            lastReplacementCount = nil
        }
        .onReceive(document.session.$lastSaveError) { error in
            if error == nil {
                dismissedSaveErrorID = nil
            }
        }
    }

    private var sessionSaveErrorBinding: Binding<HangyeolError?> {
        Binding(
            get: { sessionSaveError },
            set: { newValue in
                if newValue == nil, let id = document.session.lastSaveError?.id {
                    dismissedSaveErrorID = id
                }
            }
        )
    }

    private func retryDocumentSave() {
        NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
    }

    private func replaceInDocument() {
        switch FindReplaceFlow.replace(
            canReplace: document.session.canReplace,
            find: findQuery,
            replace: replaceQuery,
            perform: { find, replacement in
                var updated = document
                let count = try updated.replaceText(find: find, replace: replacement)
                document = updated
                return count
            }
        ) {
        case .skippedUnavailable, .skippedEmptyQuery:
            return
        case .replaced(let count):
            lastReplacementCount = count
            replaceStatusFocusToken += 1
        case .failed(let error):
            presentedError = error
        }
    }

    private func loadSample() {
        do {
            document.model = try MockEngine.loadBundledSample()
        } catch let error as HangyeolError {
            presentedError = error
        } catch {
            presentedError = .sampleNotFound
        }
    }

    private func presentOpenPanel() {
        FileOpening.install(openDocument: openDocument)
        FileOpening.presentOpenPanel()
    }

    private func openRecent(_ item: RecentDocuments.Item) {
        do {
            try recents.open(item)
        } catch let error as HangyeolError {
            reopenFailure.present(error) { openRecent(item) }
        } catch {
            reopenFailure.present(.bookmarkFailed(error.localizedDescription)) {
                openRecent(item)
            }
        }
    }

    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = L10n.exportPDF
        panel.nameFieldStringValue = "\(document.model.displayTitle).pdf"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try PDFExporter.export(document.model, to: url)
            } catch let error as HangyeolError {
                exportFailure.present(error, retry: exportPDF)
            } catch {
                exportFailure.present(.saveFailed(error.localizedDescription), retry: exportPDF)
            }
        }
    }
}

#Preview("문서") {
    DocumentWindow(
        document: .constant(HangyeolDocument(model: MockEngine.sampleDocument())),
        fileURL: nil
    )
}

#Preview("빈 화면") {
    DocumentWindow(document: .constant(HangyeolDocument()), fileURL: nil)
}

#Preview("편집됨") {
    DocumentWindow(
        document: .constant(HangyeolDocument(model: MockEngine.sampleDocument())),
        fileURL: nil,
        isEditedOverride: true
    )
}
