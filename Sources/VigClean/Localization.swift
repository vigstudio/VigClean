import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vietnamese: "Tiếng Việt"
        case .english: "English"
        case .japanese: "日本語"
        }
    }

    var flag: String {
        switch self {
        case .vietnamese: "🇻🇳"
        case .english: "🇺🇸"
        case .japanese: "🇯🇵"
        }
    }
}

enum L10n {
    static func text(_ key: String, _ language: AppLanguage) -> String {
        table[key]?[language] ?? table[key]?[.english] ?? key
    }

    private static let table: [String: [AppLanguage: String]] = [
        "clean": [.vietnamese: "Làm sạch", .english: "Clean", .japanese: "クリーン"],
        "apps": [.vietnamese: "Ứng dụng", .english: "Apps", .japanese: "アプリ"],
        "disk": [.vietnamese: "Ổ đĩa", .english: "Disk", .japanese: "ディスク"],
        "selected": [.vietnamese: "Đã chọn", .english: "Selected", .japanese: "選択済み"],
        "found": [.vietnamese: "Tìm thấy", .english: "Found", .japanese: "検出"],
        "filterCleanup": [.vietnamese: "Lọc hạng mục dọn dẹp", .english: "Filter cleanup targets", .japanese: "クリーン項目を検索"],
        "searchApps": [.vietnamese: "Tìm ứng dụng đã cài", .english: "Search installed apps", .japanese: "インストール済みアプリを検索"],
        "refresh": [.vietnamese: "Làm mới", .english: "Refresh", .japanese: "更新"],
        "scanApps": [.vietnamese: "Quét ứng dụng", .english: "Scan Apps", .japanese: "アプリをスキャン"],
        "analyzeDisk": [.vietnamese: "Phân tích ổ đĩa", .english: "Analyze Disk", .japanese: "ディスク分析"],
        "diskSummary": [.vietnamese: "Tổng dung lượng", .english: "Disk capacity", .japanese: "ディスク容量"],
        "freeOf": [.vietnamese: "trống trên", .english: "free of", .japanese: "空き /"],
        "diskCategories": [.vietnamese: "Phân bổ dung lượng", .english: "Storage categories", .japanese: "容量カテゴリ"],
        "largestItems": [.vietnamese: "Chi tiết chiếm dụng lớn", .english: "Largest items", .japanese: "大きい項目"],
        "readyToAnalyzeDisk": [.vietnamese: "Sẵn sàng phân tích ổ đĩa", .english: "Ready to analyze disk", .japanese: "ディスク分析準備完了"],
        "analyzeDiskDetail": [.vietnamese: "Bấm Phân tích ổ đĩa để xem dung lượng, nhóm chiếm dụng và thư mục lớn.", .english: "Press Analyze Disk to see capacity, categories, and large folders.", .japanese: "ディスク分析を押すと容量、カテゴリ、大きいフォルダを表示します。"],
        "canDelete": [.vietnamese: "Có thể xóa", .english: "Can delete", .japanese: "削除可"],
        "reviewBeforeDelete": [.vietnamese: "Kiểm tra", .english: "Review", .japanese: "確認"],
        "keep": [.vietnamese: "Nên giữ", .english: "Keep", .japanese: "保持"],
        "lastUsed": [.vietnamese: "Dùng gần nhất", .english: "Last used", .japanese: "最終使用"],
        "readyToScan": [.vietnamese: "Sẵn sàng quét", .english: "Ready to scan", .japanese: "スキャン準備完了"],
        "chooseOptionsThenScan": [.vietnamese: "Chọn bộ lọc và tùy chọn bên phải, rồi bấm Quét.", .english: "Choose filters and options, then press Scan.", .japanese: "フィルターとオプションを選び、スキャンを押してください。"],
        "readyToScanApps": [.vietnamese: "Sẵn sàng quét ứng dụng", .english: "Ready to scan apps", .japanese: "アプリスキャン準備完了"],
        "scanAppsDetail": [.vietnamese: "Bấm Quét ứng dụng để tải danh sách app đã cài.", .english: "Press Scan Apps to load installed applications.", .japanese: "アプリをスキャンしてインストール済みアプリを読み込みます。"],
        "reveal": [.vietnamese: "Hiện trong Finder", .english: "Reveal", .japanese: "Finderで表示"],
        "uninstall": [.vietnamese: "Gỡ cài đặt", .english: "Uninstall", .japanese: "アンインストール"],
        "actions": [.vietnamese: "Hành động", .english: "Actions", .japanese: "操作"],
        "options": [.vietnamese: "Tùy chọn", .english: "Options", .japanese: "オプション"],
        "deletePermanently": [.vietnamese: "Xóa vĩnh viễn", .english: "Delete permanently", .japanese: "完全に削除"],
        "quitAffectedApps": [.vietnamese: "Tắt app liên quan khi xóa dữ liệu", .english: "Quit affected apps before deleting data", .japanese: "関連アプリを終了してから削除"],
        "askAdmin": [.vietnamese: "Yêu cầu admin khi cần", .english: "Ask admin when needed", .japanese: "必要時に管理者権限を要求"],
        "scanPrivateFolders": [.vietnamese: "Quét Downloads/Documents", .english: "Scan Downloads/Documents", .japanese: "Downloads/Documentsをスキャン"],
        "selectRecommended": [.vietnamese: "Chọn đề xuất", .english: "Select recommended", .japanese: "推奨を選択"],
        "clearSelection": [.vietnamese: "Bỏ chọn", .english: "Clear selection", .japanese: "選択解除"],
        "selection": [.vietnamese: "Lựa chọn", .english: "Selection", .japanese: "選択"],
        "risk": [.vietnamese: "Mức rủi ro", .english: "Risk", .japanese: "リスク"],
        "scan": [.vietnamese: "Quét", .english: "Scan", .japanese: "スキャン"],
        "deleteSelected": [.vietnamese: "Xóa mục đã chọn", .english: "Delete Selected", .japanese: "選択項目を削除"],
        "moveTrash": [.vietnamese: "Chuyển vào Thùng rác", .english: "Move Selected to Trash", .japanese: "ゴミ箱に移動"],
        "related": [.vietnamese: "liên quan", .english: "related", .japanese: "関連"],
        "admin": [.vietnamese: "Cần admin", .english: "Admin", .japanese: "管理者"],
        "language": [.vietnamese: "Ngôn ngữ", .english: "Language", .japanese: "言語"],
        "safe": [.vietnamese: "An toàn", .english: "Safe", .japanese: "安全"],
        "review": [.vietnamese: "Kiểm tra", .english: "Review", .japanese: "確認"],
        "personal": [.vietnamese: "Cá nhân", .english: "Personal", .japanese: "個人データ"]
    ]
}
