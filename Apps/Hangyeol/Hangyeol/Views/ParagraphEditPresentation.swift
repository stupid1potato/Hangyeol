import Foundation

/// Paragraph chrome gated by **this** document's `session.canEditParagraphs`.
/// Views must not call HangyeolKit `RealEngine` or process-wide `EngineClient`.
struct ParagraphEditPresentation: Equatable {
    var canEditParagraphs: Bool

    var usesField: Bool { canEditParagraphs }

    /// Live session only. Mock / closed sessions stay silent (no fake success).
    var caption: String? {
        canEditParagraphs ? L10n.paragraphEditLiveNote : nil
    }

    static func make(canEditParagraphs: Bool) -> ParagraphEditPresentation {
        ParagraphEditPresentation(canEditParagraphs: canEditParagraphs)
    }

    /// 1-based ordinal for VoiceOver. `ordinal` is 0-based body index.
    static func accessibilityLabel(ordinal: Int, text: String, editable: Bool) -> String {
        L10n.paragraphA11y(ordinal: ordinal + 1, text: text, editable: editable)
    }
}

/// One on-screen body paragraph plus optional engine `(section, paragraph)`.
/// `paragraphIndex` is Kit body-paragraph index, never a flattened cell line.
struct ParagraphEditSurface: Equatable, Identifiable {
    var id: String
    var paragraph: ParagraphBlock
    var section: UInt32?
    var paragraphIndex: UInt32?
    var editable: Bool

    var plainText: String { paragraph.plainText }

    var engineAddress: (section: UInt32, paragraph: UInt32)? {
        guard let section, let paragraphIndex else { return nil }
        return (section, paragraphIndex)
    }
}

/// Map UI body-paragraph ordinal → Kit `insertText` / `deleteRange` address.
///
/// Kit `displayModel` concatenates body + table-cell paragraphs, drops empty
/// lines, then `TableEditMapping` peels trailing cell slots. Remaining **body**
/// lines are non-empty section body texts in document order.
///
/// Engine indices include empty body paragraphs (not in the display). Views
/// therefore map the i-th body line to `paragraph: i` and do not guess later
/// sections. Hub-A / SimpleTable is contiguous non-empty body from paragraph 0.
enum ParagraphEditMapping {
    static func address(
        bodyOrdinal: Int,
        engineTables: [TableInfo]
    ) -> (section: UInt32, paragraph: UInt32)? {
        guard bodyOrdinal >= 0 else { return nil }
        return (inferredSection(engineTables: engineTables), UInt32(bodyOrdinal))
    }

    /// Single shared section from `listTables()`, else 0 (hub-A is section 0).
    static func inferredSection(engineTables: [TableInfo]) -> UInt32 {
        let sections = Set(engineTables.map(\.section))
        if sections.count == 1, let section = engineTables.first?.section {
            return section
        }
        return 0
    }

    static func surface(
        paragraph: ParagraphBlock,
        bodyOrdinal: Int,
        engineTables: [TableInfo],
        canEditParagraphs: Bool
    ) -> ParagraphEditSurface {
        let address = address(bodyOrdinal: bodyOrdinal, engineTables: engineTables)
        return ParagraphEditSurface(
            id: paragraph.id.uuidString,
            paragraph: paragraph,
            section: address?.section,
            paragraphIndex: address?.paragraph,
            editable: canEditParagraphs && address != nil
        )
    }
}

/// Unicode-scalar diff aligned with DocumentCore `chars()` / `char_offset`.
struct ParagraphTextChange: Equatable {
    var charOffset: UInt32
    var deleteCount: UInt32
    var insertText: String

    var hasDelete: Bool { deleteCount > 0 }
    var hasInsert: Bool { !insertText.isEmpty }
}

enum ParagraphEditDiff {
    static func change(from oldText: String, to newText: String) -> ParagraphTextChange? {
        if oldText == newText { return nil }

        let oldScalars = Array(oldText.unicodeScalars)
        let newScalars = Array(newText.unicodeScalars)
        var prefix = 0
        while prefix < oldScalars.count,
              prefix < newScalars.count,
              oldScalars[prefix] == newScalars[prefix] {
            prefix += 1
        }
        var oldEnd = oldScalars.count
        var newEnd = newScalars.count
        while oldEnd > prefix, newEnd > prefix, oldScalars[oldEnd - 1] == newScalars[newEnd - 1] {
            oldEnd -= 1
            newEnd -= 1
        }
        let inserted = String(String.UnicodeScalarView(newScalars[prefix..<newEnd]))
        return ParagraphTextChange(
            charOffset: UInt32(prefix),
            deleteCount: UInt32(oldEnd - prefix),
            insertText: inserted
        )
    }
}

/// View-layer paragraph commit: no fake success when the session cannot edit.
enum ParagraphEditFlow {
    enum Outcome: Equatable {
        case skippedUnavailable
        case skippedUnmapped
        case skippedUnchanged
        case updated
        case failed(HangyeolError)
    }

    static func commit(
        canEditParagraphs: Bool,
        section: UInt32?,
        paragraph: UInt32?,
        oldText: String,
        newText: String,
        insert: (UInt32, UInt32, UInt32, String) throws -> Void,
        delete: (UInt32, UInt32, UInt32, UInt32) throws -> Void
    ) -> Outcome {
        guard canEditParagraphs else { return .skippedUnavailable }
        guard let section, let paragraph else { return .skippedUnmapped }
        guard let change = ParagraphEditDiff.change(from: oldText, to: newText) else {
            return .skippedUnchanged
        }
        do {
            if change.hasDelete {
                try delete(section, paragraph, change.charOffset, change.deleteCount)
            }
            if change.hasInsert {
                try insert(section, paragraph, change.charOffset, change.insertText)
            }
            return .updated
        } catch let error as HangyeolError {
            return .failed(error)
        } catch {
            return .failed(.engineFailed(error.localizedDescription))
        }
    }
}
