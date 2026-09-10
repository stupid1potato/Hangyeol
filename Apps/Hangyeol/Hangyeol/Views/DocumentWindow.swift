import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DocumentWindow: View {
    @Binding var document: HangyeolDocument
    var fileURL: URL?

    @Environment(\.openDocument) private var openDocument
    @ObservedObject private var recents = RecentDocuments.shared
    @State private var showFindReplace = false
    @State private var findQuery = ""
    @State private var replaceQuery = ""
    @State private var presentedError: HangyeolError?
    @State private var saveFailure: HangyeolError?
    @State private var showHelp = false
    @State private var exportRetry: (() -> Void)?
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            if showFindReplace {
                FindReplaceBar(
                    query: $findQuery,
                    replacement: $replaceQuery,
                    liveEngine: EngineClient.liveSession != nil,
                    onFind: {},
                    onReplace: replaceInEngine,
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
                StructuredTextView(model: document.model)
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
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            FileOpening.handleDrop(providers: providers)
        }
        .navigationTitle(document.model.displayTitle)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
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
        .sheet(item: $saveFailure) { error in
            SaveFailureSheet(
                error: error,
                onRetry: {
                    saveFailure = nil
                    exportRetry?()
                },
                onDismiss: {
                    saveFailure = nil
                    exportRetry = nil
                }
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
    }

    private func replaceInEngine() {
        guard EngineClient.liveSession != nil else { return }
        let find = findQuery
        let replacement = replaceQuery
        guard !find.isEmpty else { return }
        do {
            _ = try EngineClient.replaceText(find: find, replace: replacement)
            document.model = try EngineClient.refreshDisplayModel(
                type: document.model.metadata.sourceType,
                title: document.model.metadata.title
            )
        } catch let error as HangyeolError {
            presentedError = error
        } catch {
            presentedError = .engineFailed(error.localizedDescription)
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
            presentedError = error
        } catch {
            presentedError = .bookmarkFailed(error.localizedDescription)
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
                exportRetry = exportPDF
                saveFailure = error
            } catch {
                exportRetry = exportPDF
                saveFailure = .saveFailed(error.localizedDescription)
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
