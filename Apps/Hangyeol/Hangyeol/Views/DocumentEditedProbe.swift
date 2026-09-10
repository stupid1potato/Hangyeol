import AppKit
import SwiftUI

/// Reads AppKit's existing `NSWindow.isDocumentEdited` for window chrome.
/// DocumentGroup sets this when `HangyeolDocument` is `Equatable`.
/// Not a parallel engine session — pass `DocumentWindow.isEditedOverride` when
/// EngineClient publishes dirty state.
struct DocumentEditedProbe: NSViewRepresentable {
    @Binding var isEdited: Bool

    func makeNSView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.onEditedChange = { newValue in
            if isEdited != newValue {
                isEdited = newValue
            }
        }
        return view
    }

    func updateNSView(_ nsView: ProbeView, context: Context) {
        nsView.onEditedChange = { newValue in
            if isEdited != newValue {
                isEdited = newValue
            }
        }
        if let edited = nsView.window?.isDocumentEdited, edited != isEdited {
            DispatchQueue.main.async {
                isEdited = edited
            }
        }
    }

    final class ProbeView: NSView {
        var onEditedChange: ((Bool) -> Void)?
        private var observation: NSKeyValueObservation?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observation?.invalidate()
            guard let window else {
                onEditedChange?(false)
                return
            }
            observation = window.observe(\.isDocumentEdited, options: [.initial, .new]) { [weak self] observed, _ in
                let edited = observed.isDocumentEdited
                DispatchQueue.main.async {
                    self?.onEditedChange?(edited)
                }
            }
        }
    }
}
