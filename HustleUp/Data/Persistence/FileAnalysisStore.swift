import Foundation

@MainActor
protocol AnalysisStoring: AnyObject {
    var items: [StoredAnalysis] { get }
    func append(_ item: StoredAnalysis)
    func update(_ item: StoredAnalysis)
    func deleteAll()
}

@Observable
@MainActor
final class FileAnalysisStore: AnalysisStoring {
    private let fileURL: URL
    private let cap: Int
    private(set) var items: [StoredAnalysis] = []

    init(fileURL: URL? = nil, cap: Int = 20) {
        self.cap = cap
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let directory = folder.appendingPathComponent("HustleUp", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            self.fileURL = directory.appendingPathComponent("history.json")
        }
        items = Self.read(from: self.fileURL)
    }

    func append(_ item: StoredAnalysis) {
        items.insert(item, at: 0)
        if items.count > cap {
            items = Array(items.prefix(cap))
        }
        persist()
    }

    func update(_ item: StoredAnalysis) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        persist()
    }

    func deleteAll() {
        items = []
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            HULog.debug("store persist failed")
        }
    }

    private static func read(from url: URL) -> [StoredAnalysis] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([StoredAnalysis].self, from: data)) ?? []
    }
}
