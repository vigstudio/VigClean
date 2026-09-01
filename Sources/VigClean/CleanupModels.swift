import Foundation

final class OperationStepCounter: @unchecked Sendable {
    private let lock = NSLock()
    private let total: Double
    private var completed = 0.0

    init(total: Double) {
        self.total = max(total, 1)
    }

    func fraction() -> Double {
        lock.lock()
        defer { lock.unlock() }
        return min(completed / total, 1)
    }

    func advance() -> Double {
        lock.lock()
        completed += 1
        let result = min(completed / total, 1)
        lock.unlock()
        return result
    }
}

enum CleanupRisk: String, CaseIterable, Identifiable {
    case safe = "Safe"
    case review = "Review"
    case personal = "Personal"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .safe: 0
        case .review: 1
        case .personal: 2
        }
    }
}

enum CleanupPathCleanability: String, Hashable, Sendable {
    case removable
    case administratorRequired
    case protected
    case unavailable

    var isSelectable: Bool {
        self == .removable || self == .administratorRequired
    }
}

struct CleanupPathEntry: Identifiable, Hashable, Sendable {
    let id: String
    let url: URL
    let bytes: Int64
    let cleanability: CleanupPathCleanability
    let children: [CleanupPathEntry]

    init(url: URL, bytes: Int64, cleanability: CleanupPathCleanability, children: [CleanupPathEntry] = []) {
        self.id = url.standardizedFileURL.path
        self.url = url
        self.bytes = bytes
        self.cleanability = cleanability
        self.children = children
    }

    var requiresAdmin: Bool { cleanability == .administratorRequired }

    var flattened: [CleanupPathEntry] {
        [self] + children.flatMap(\.flattened)
    }
}

struct CleanupFinding: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let detail: String
    let pathEntries: [CleanupPathEntry]
    let bytes: Int64
    let risk: CleanupRisk
    let selectedByDefault: Bool

    var paths: [URL] {
        pathEntries.flatMap(\.flattened).map(\.url)
    }

    var requiresAdmin: Bool {
        pathEntries.flatMap(\.flattened).contains(where: \.requiresAdmin)
    }

    var exists: Bool {
        paths.contains { FileManager.default.fileExists(atPath: $0.path) }
    }
}

struct DeleteResult: Sendable {
    let deletedBytes: Int64
    let errors: [String]
    let freeBytesBefore: Int64
    let freeBytesAfter: Int64
    let cancelled: Bool

    var recoveredBytes: Int64 {
        max(freeBytesAfter - freeBytesBefore, 0)
    }
}

enum CleanupOperationLimits {
    static let maximumSelectedRoots = 10_000
    static let chunkSize = 100
}

enum CleanupOperationKind: String, Codable, Sendable {
    case cleanup
    case uninstall
    case diskCleanup
}

struct CleanupHistoryEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let kind: CleanupOperationKind
    let title: String
    let deletedBytes: Int64
    let recoveredBytes: Int64
    let freeBytesBefore: Int64
    let freeBytesAfter: Int64
    let itemCount: Int
    let errorCount: Int
    let permanent: Bool

    init(date: Date = .now, kind: CleanupOperationKind, title: String, deletedBytes: Int64, recoveredBytes: Int64, freeBytesBefore: Int64, freeBytesAfter: Int64, itemCount: Int, errorCount: Int, permanent: Bool) {
        self.id = UUID()
        self.date = date
        self.kind = kind
        self.title = title
        self.deletedBytes = deletedBytes
        self.recoveredBytes = recoveredBytes
        self.freeBytesBefore = freeBytesBefore
        self.freeBytesAfter = freeBytesAfter
        self.itemCount = itemCount
        self.errorCount = errorCount
        self.permanent = permanent
    }
}

struct InstalledApp: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let bundleID: String?
    let appURL: URL
    let relatedEntries: [CleanupPathEntry]
    let totalBytes: Int64

    var relatedPaths: [URL] {
        relatedEntries.flatMap(\.flattened).map(\.url)
    }

    var requiresAdmin: Bool {
        relatedEntries.flatMap(\.flattened).contains(where: \.requiresAdmin)
    }

    var cleanupFinding: CleanupFinding {
        let idText = bundleID.map { " Bundle ID: \($0)." } ?? ""
        return CleanupFinding(
            title: "Uninstall App: \(name)",
            detail: "Deletes the app bundle plus related support files, cache, preferences, containers, logs, saved state, WebKit, and HTTP storage.\(idText)",
            pathEntries: relatedEntries,
            bytes: totalBytes,
            risk: .personal,
            selectedByDefault: false
        )
    }
}

enum DiskItemRecommendation: String, Sendable {
    case removable
    case review
    case keep
}

struct DiskVolumeSummary: Sendable {
    let totalBytes: Int64
    let freeBytes: Int64

    var usedBytes: Int64 {
        max(totalBytes - freeBytes, 0)
    }
}

struct DiskCategorySummary: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let detail: String
    let bytes: Int64
    let colorName: String
}

struct DiskUsageItem: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let path: URL
    let bytes: Int64
    let purpose: String
    let recommendation: DiskItemRecommendation
    let lastAccessed: Date?
    let children: [DiskUsageItem]

    var flattened: [DiskUsageItem] {
        [self] + children.flatMap(\.flattened)
    }
}

struct DiskAnalysisResult: Sendable {
    let volume: DiskVolumeSummary
    let categories: [DiskCategorySummary]
    let items: [DiskUsageItem]
}

extension Int64 {
    var storageText: String {
        if self == 0 { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.includesUnit = true
        formatter.includesCount = true
        return formatter.string(fromByteCount: self)
    }
}
