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
        "history": [.vietnamese: "Lịch sử", .english: "History", .japanese: "履歴"],
        "cleanTitle": [.vietnamese: "Dọn dẹp thông minh", .english: "Smart Cleanup", .japanese: "スマートクリーンアップ"],
        "cleanSubtitle": [.vietnamese: "Tìm và loại bỏ dữ liệu không còn cần thiết", .english: "Find and remove data you no longer need", .japanese: "不要なデータを見つけて削除します"],
        "appsTitle": [.vietnamese: "Quản lý ứng dụng", .english: "Application Manager", .japanese: "アプリ管理"],
        "appsSubtitle": [.vietnamese: "Gỡ ứng dụng cùng toàn bộ dữ liệu liên quan", .english: "Uninstall apps and their related data", .japanese: "アプリと関連データを削除します"],
        "diskTitle": [.vietnamese: "Phân tích ổ đĩa", .english: "Disk Analyzer", .japanese: "ディスク分析"],
        "diskSubtitle": [.vietnamese: "Hiểu rõ những gì đang chiếm dung lượng", .english: "Understand what is using your storage", .japanese: "ストレージ使用状況を確認します"],
        "historyTitle": [.vietnamese: "Lịch sử dọn dẹp", .english: "Cleanup History", .japanese: "クリーンアップ履歴"],
        "historySubtitle": [.vietnamese: "Theo dõi dữ liệu đã xử lý và dung lượng thực tế thu hồi", .english: "Review completed operations and recovered storage", .japanese: "完了した操作と回復した容量を確認します"],
        "macCleaner": [.vietnamese: "Trình dọn dẹp Mac", .english: "Mac cleaner", .japanese: "Macクリーナー"],
        "localOnly": [.vietnamese: "Xử lý tại máy", .english: "On-device only", .japanese: "デバイス内処理"],
        "localOnlyDetail": [.vietnamese: "Dữ liệu quét không được tải lên mạng.", .english: "Scan data never leaves your Mac.", .japanese: "スキャンデータはMac外に送信されません。"],
        "recoverable": [.vietnamese: "Có thể giải phóng", .english: "Recoverable", .japanese: "解放可能"],
        "cleanupGroups": [.vietnamese: "Nhóm dọn dẹp", .english: "Cleanup groups", .japanese: "クリーン項目"],
        "reviewAndClean": [.vietnamese: "Kiểm tra và dọn", .english: "Review and clean", .japanese: "確認してクリーン"],
        "reviewAndCleanDetail": [.vietnamese: "Kiểm tra lựa chọn trước khi xóa.", .english: "Review your selection before removal.", .japanese: "削除前に選択内容を確認してください。"],
        "operations": [.vietnamese: "thao tác", .english: "operations", .japanese: "件の操作"],
        "clearHistory": [.vietnamese: "Xóa lịch sử", .english: "Clear History", .japanese: "履歴を消去"],
        "noHistory": [.vietnamese: "Chưa có lịch sử", .english: "No cleanup history", .japanese: "履歴はありません"],
        "noHistoryDetail": [.vietnamese: "Các lần dọn dẹp và gỡ ứng dụng sẽ xuất hiện tại đây.", .english: "Cleanup and uninstall operations will appear here.", .japanese: "クリーンアップとアンインストール操作がここに表示されます。"],
        "items": [.vietnamese: "mục", .english: "items", .japanese: "項目"],
        "permanent": [.vietnamese: "vĩnh viễn", .english: "permanent", .japanese: "完全削除"],
        "trash": [.vietnamese: "Thùng rác", .english: "Trash", .japanese: "ゴミ箱"],
        "recovered": [.vietnamese: "đã thu hồi", .english: "recovered", .japanese: "回復"],
        "riskHint": [.vietnamese: "Mục màu cam có thể tạo lại nhưng có thể ảnh hưởng quy trình làm việc. Dữ liệu cá nhân không được chọn mặc định.", .english: "Orange items can be rebuilt but may affect your workflow. Personal data is never selected by default.", .japanese: "オレンジの項目は再生成できますが作業に影響する場合があります。個人データは初期選択されません。"],
        "protectedPaths": [.vietnamese: "đường dẫn được bảo vệ", .english: "protected paths", .japanese: "保護されたパス"],
        "moreProtected": [.vietnamese: "đường dẫn khác", .english: "more protected", .japanese: "件以上"],
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
        "personal": [.vietnamese: "Cá nhân", .english: "Personal", .japanese: "個人データ"],
        "confirmPermanentTitle": [.vietnamese: "Xóa vĩnh viễn các mục đã chọn?", .english: "Permanently delete selected items?", .japanese: "選択項目を完全に削除しますか？"],
        "confirmTrashTitle": [.vietnamese: "Chuyển các mục đã chọn vào Thùng rác?", .english: "Move selected items to Trash?", .japanese: "選択項目をゴミ箱に移動しますか？"],
        "confirmCleanupMessage": [.vietnamese: "%count% mục, tổng cộng %size%. Có %risk% nhóm cần kiểm tra kỹ trước khi xóa.", .english: "%count% items totaling %size%. %risk% groups require review before deletion.", .japanese: "%count%項目、合計%size%。削除前に確認が必要なグループは%risk%件です。"],
        "cancel": [.vietnamese: "Hủy", .english: "Cancel", .japanese: "キャンセル"],
        "itemsSelected": [.vietnamese: "mục đã chọn", .english: "items selected", .japanese: "項目を選択"],
        "safeSelection": [.vietnamese: "Chỉ gồm dữ liệu có thể tạo lại", .english: "Only rebuildable data selected", .japanese: "再生成可能なデータのみ"],
        "reviewSelections": [.vietnamese: "nhóm cần kiểm tra", .english: "groups need review", .japanese: "グループは確認が必要"]
    ]
}
