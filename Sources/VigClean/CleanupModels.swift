import Foundation

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

struct CleanupPathEntry: Identifiable, Hashable, Sendable {
    let id: String
    let url: URL
    let bytes: Int64
    let requiresAdmin: Bool
    let children: [CleanupPathEntry]

    init(url: URL, bytes: Int64, requiresAdmin: Bool, children: [CleanupPathEntry] = []) {
        self.id = url.standardizedFileURL.path
        self.url = url
        self.bytes = bytes
        self.requiresAdmin = requiresAdmin
        self.children = children
    }

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
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.includesUnit = true
        formatter.includesCount = true
        return formatter.string(fromByteCount: self)
    }
}
