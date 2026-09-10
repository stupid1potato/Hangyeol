import Foundation

/// Help sheet copy, including the scannable 「알려진 한계」 list.
struct HelpPresentation: Equatable {
    struct Limit: Equatable, Identifiable {
        var id: String
        var text: String
    }

    var title: String
    var body: String
    var limitsTitle: String
    var limits: [Limit]

    static let sheetIdentifier = "help-sheet"
    static let limitsIdentifier = "help-known-limits"

    static func make() -> HelpPresentation {
        HelpPresentation(
            title: L10n.help,
            body: L10n.helpBody,
            limitsTitle: L10n.helpKnownLimitsTitle,
            limits: [
                Limit(id: "layout", text: L10n.helpLimitLayout),
                Limit(id: "wysiwyg", text: L10n.helpLimitWysiwyg),
                Limit(id: "hwp-save", text: L10n.helpLimitHwpSave)
            ]
        )
    }

    var accessibilityLabel: String {
        var parts = [title, body, limitsTitle]
        parts.append(contentsOf: limits.map(\.text))
        return parts.joined(separator: " ")
    }
}
