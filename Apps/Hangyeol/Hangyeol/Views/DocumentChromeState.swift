import SwiftUI

/// Window-chrome title + edited badge. Binds to `NSWindow.isDocumentEdited`
/// (FileDocument Equatable) until Document/EngineClient publishes `isEdited`.
struct DocumentChromeState: Equatable {
    var title: String
    var isEdited: Bool

    var navigationSubtitle: String? {
        isEdited ? L10n.edited : nil
    }

    var accessibilityLabel: String {
        if isEdited {
            return "\(title), \(L10n.edited)"
        }
        return title
    }

    static func make(title: String, isEditedOverride: Bool?, windowEdited: Bool) -> DocumentChromeState {
        DocumentChromeState(
            title: title,
            isEdited: isEditedOverride ?? windowEdited
        )
    }
}

extension View {
    @ViewBuilder
    func hangyeolEditedSubtitle(_ subtitle: String?) -> some View {
        if let subtitle {
            navigationSubtitle(subtitle)
        } else {
            self
        }
    }
}
