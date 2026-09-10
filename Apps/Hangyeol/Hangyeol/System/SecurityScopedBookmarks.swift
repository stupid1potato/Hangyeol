import Foundation

enum SecurityScopedBookmarks {
    static func bookmark(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw HangyeolError.bookmarkFailed(error.localizedDescription)
        }
    }

    static func resolve(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (url, isStale)
        } catch {
            throw HangyeolError.bookmarkFailed(error.localizedDescription)
        }
    }

    @discardableResult
    static func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    static func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }

    /// Bookmark + start access. Caller keeps the URL for the document lifetime.
    static func bookmarkAndAccess(_ url: URL) throws -> Data {
        let data = try bookmark(for: url)
        _ = startAccessing(url)
        return data
    }
}
