import AppKit
import Combine

@MainActor
final class RecentDocuments: ObservableObject {
    static let shared = RecentDocuments()

    struct Item: Identifiable, Equatable {
        var id: String { url.standardizedFileURL.path }
        var url: URL
        var title: String
        var bookmark: Data?
    }

    @Published private(set) var items: [Item] = []

    private let defaultsKey = "hangyeol.recentBookmarks"
    private let maxCount = 12

    private init() {
        // DocumentGroup의 PlatformDocumentController 초기화 전에
        // NSDocumentController.shared 를 건드리지 않습니다.
    }

    func refresh() {
        var seen = Set<String>()
        var combined: [Item] = []
        let stored = loadStoredBookmarks()

        for url in NSDocumentController.shared.recentDocumentURLs {
            let key = url.standardizedFileURL.path
            guard seen.insert(key).inserted else { continue }
            let bookmark = (try? SecurityScopedBookmarks.bookmark(for: url))
                ?? stored.first(where: { $0.url.standardizedFileURL.path == key })?.bookmark
            combined.append(makeItem(url: url, bookmark: bookmark))
        }

        for item in stored {
            let key = item.url.standardizedFileURL.path
            guard seen.insert(key).inserted else { continue }
            combined.append(item)
        }

        items = Array(combined.prefix(maxCount))
        persistBookmarks()
    }

    func noteOpened(_ url: URL) {
        NSDocumentController.shared.noteNewRecentDocumentURL(url)

        let bookmark = try? SecurityScopedBookmarks.bookmark(for: url)
        let item = makeItem(url: url, bookmark: bookmark ?? existingBookmark(for: url))
        items.removeAll { $0.id == item.id }
        items.insert(item, at: 0)
        if items.count > maxCount {
            items = Array(items.prefix(maxCount))
        }
        persistBookmarks()
    }

    func open(_ item: Item) throws {
        if let bookmark = item.bookmark {
            try FileOpening.reopenSaved(bookmark: bookmark)
            return
        }
        _ = SecurityScopedBookmarks.startAccessing(item.url)
        FileOpening.openResolved(url: item.url)
    }

    func clear() {
        NSDocumentController.shared.clearRecentDocuments(nil)
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        items = []
    }

    private func makeItem(url: URL, bookmark: Data?) -> Item {
        Item(
            url: url.standardizedFileURL,
            title: url.lastPathComponent,
            bookmark: bookmark
        )
    }

    private func existingBookmark(for url: URL) -> Data? {
        items.first { $0.id == url.standardizedFileURL.path }?.bookmark
    }

    private func loadStoredBookmarks() -> [Item] {
        guard let stored = UserDefaults.standard.array(forKey: defaultsKey) as? [Data] else {
            return []
        }
        return stored.compactMap { data in
            guard let resolved = try? SecurityScopedBookmarks.resolve(data) else { return nil }
            return makeItem(url: resolved.url, bookmark: data)
        }
    }

    private func persistBookmarks() {
        let data = items.compactMap { item -> Data? in
            if let bookmark = item.bookmark { return bookmark }
            return try? SecurityScopedBookmarks.bookmark(for: item.url)
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
