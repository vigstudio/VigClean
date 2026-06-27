import AppKit
import SwiftUI

struct CleanerView: View {
    @StateObject private var model = CleanerViewModel()
    @State private var selectedTab: AppTab = .clean

    var body: some View {
        VStack(spacing: 0) {
            appHeader
            TabView(selection: $selectedTab) {
                CleanTab(model: model)
                    .tabItem {
                        Label(model.t("clean"), systemImage: "sparkles")
                    }
                    .tag(AppTab.clean)

                AppsTab(model: model)
                    .tabItem {
                        Label(model.t("apps"), systemImage: "square.grid.2x2")
                    }
                    .tag(AppTab.apps)

                DiskTab(model: model)
                    .tabItem {
                        Label(model.t("disk"), systemImage: "chart.pie")
                    }
                    .tag(AppTab.disk)
            }
        }
        .background(AppTheme.background)
        .onChange(of: selectedTab) { _, nextTab in
            if nextTab == .apps, !model.hasScannedApps {
                model.scanApps()
            }
        }
    }

    private var appHeader: some View {
        HStack(spacing: 16) {
            LogoView()
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(model.status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if !model.progressDetail.isEmpty {
                    HStack(spacing: 8) {
                        if model.isScanning || model.isScanningApps || model.isScanningDisk || model.isCleaning {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.72)
                        }
                        Text(model.progressDetail)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                LanguageMenu(language: $model.language)

                HStack(spacing: 12) {
                    MetricPill(title: model.t("selected"), value: model.selectedBytes.storageText, systemImage: "checkmark.circle")
                    MetricPill(title: model.t("found"), value: model.totalBytes.storageText, systemImage: "internaldrive")
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(AppTheme.header)
    }
}

private enum AppTab: Hashable {
    case clean
    case apps
    case disk
}

private struct LogoView: View {
    var body: some View {
        Group {
            if let url = Bundle.module.url(forResource: "VigCleanLogo", withExtension: "png"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.green.opacity(0.16))
                    Text("V")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 4)
    }
}

private struct LanguageMenu: View {
    @Binding var language: AppLanguage

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    language = option
                } label: {
                    if option == language {
                        Label("\(option.flag)  \(option.displayName)", systemImage: "checkmark")
                    } else {
                        Text("\(option.flag)  \(option.displayName)")
                    }
                }
            }
        } label: {
            Text(language.flag)
                .font(.system(size: 18))
                .frame(width: 44, height: 34)
        }
        .menuStyle(.borderlessButton)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

private struct CleanTab: View {
    @ObservedObject var model: CleanerViewModel

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    SearchBar(text: $model.filterText, placeholder: model.t("filterCleanup"))

                    Button {
                        model.scan()
                    } label: {
                        Label(model.t("scan"), systemImage: "magnifyingglass")
                            .frame(minWidth: 108)
                    }
                    .buttonStyle(PrimaryUtilityButtonStyle())
                    .disabled(model.isScanning || model.isCleaning)

                    Button(role: .destructive) {
                        model.cleanSelected()
                    } label: {
                        Label(model.permanentlyDelete ? model.t("deleteSelected") : model.t("moveTrash"), systemImage: "trash")
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(DestructiveUtilityButtonStyle())
                    .disabled(model.selectedIDs.isEmpty || model.isScanning || model.isCleaning)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)

                if model.isScanning {
                    ScanProgressStrip(
                        title: model.status,
                        detail: model.progressDetail.isEmpty ? "Preparing scan..." : model.progressDetail,
                        systemImage: "magnifyingglass"
                    )
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                }

                List(selection: .constant(Set<CleanupFinding.ID>())) {
                    ForEach(model.visibleFindings) { finding in
                        FindingRow(
                            finding: finding,
                            isSelected: model.selectedIDs.contains(finding.id),
                            isPathSelected: { model.isSelected($0) },
                            onToggle: { model.toggle(finding) },
                            onTogglePath: { model.togglePath($0, in: finding) },
                            language: model.language
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
                    }
                }
                .listStyle(.inset)
                .overlay {
                    if !model.hasScannedClean && !model.isScanning {
                        EmptyStateCard(
                            systemImage: "magnifyingglass",
                            title: model.t("readyToScan"),
                            detail: model.t("chooseOptionsThenScan")
                        )
                    }
                }
            }

            UtilityPanel(model: model)
                .frame(width: 320)
        }
    }
}

private struct ScanProgressStrip: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .frame(width: 18, height: 18)

            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppTheme.control, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 26)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

private struct AppsTab: View {
    @ObservedObject var model: CleanerViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 14)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                SearchBar(text: $model.appFilterText, placeholder: model.t("searchApps"))

                Button {
                    model.scanApps()
                } label: {
                    Label(model.hasScannedApps ? model.t("refresh") : model.t("scanApps"), systemImage: "arrow.clockwise")
                }
                .buttonStyle(CompactUtilityButtonStyle())
                .disabled(model.isScanningApps || model.isCleaning)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            if model.isScanningApps {
                ScanProgressStrip(
                    title: model.status,
                    detail: model.progressDetail.isEmpty ? "Preparing app scan..." : model.progressDetail,
                    systemImage: "square.grid.2x2"
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
            }

            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                    ForEach(model.visibleApps) { app in
                        AppCard(
                            app: app,
                            isCleaning: model.isCleaning,
                            selectedBytes: model.selectedBytes(for: app),
                            isPathSelected: { model.isAppPathSelected($0, app: app) },
                            togglePath: { model.toggleAppPath($0, app: app) },
                            language: model.language
                        ) {
                            model.uninstall(app)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .overlay {
                if !model.hasScannedApps && !model.isScanningApps {
                    EmptyStateCard(
                        systemImage: "square.grid.2x2",
                        title: model.t("readyToScanApps"),
                        detail: model.t("scanAppsDetail")
                    )
                }
            }
        }
        .background(AppTheme.background)
    }
}

private struct DiskTab: View {
    @ObservedObject var model: CleanerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    model.analyzeDisk()
                } label: {
                    Label(model.t("analyzeDisk"), systemImage: "chart.pie")
                }
                .buttonStyle(PrimaryUtilityButtonStyle())
                .disabled(model.isScanningDisk || model.isCleaning)

                Button(role: .destructive) {
                    model.deleteSelectedDiskItems()
                } label: {
                    Label(model.t("deleteSelected"), systemImage: "trash")
                }
                .buttonStyle(DestructiveUtilityButtonStyle())
                .disabled(model.selectedDiskItems.isEmpty || model.isScanningDisk || model.isCleaning)

                Spacer()

                if model.selectedDiskBytes > 0 {
                    MetricPill(title: model.t("selected"), value: model.selectedDiskBytes.storageText, systemImage: "checkmark.circle")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            if model.isScanningDisk {
                ScanProgressStrip(
                    title: model.status,
                    detail: model.progressDetail.isEmpty ? "Preparing disk analysis..." : model.progressDetail,
                    systemImage: "chart.pie"
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
            }

            if let analysis = model.diskAnalysis {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        DiskSummaryView(analysis: analysis, language: model.language)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(model.t("diskCategories"))
                                .font(.headline)
                            ForEach(analysis.categories) { category in
                                DiskCategoryRow(category: category, total: max(analysis.volume.usedBytes, 1))
                            }
                        }
                        .padding(16)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(model.t("largestItems"))
                                .font(.headline)
                            ForEach(analysis.items) { item in
                                DiskItemRow(
                                    item: item,
                                    isSelected: { model.isDiskItemSelected($0) },
                                    toggle: { model.toggleDiskItem($0) },
                                    language: model.language
                                )
                                Divider()
                            }
                        }
                        .padding(16)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))
                    }
                    .padding(24)
                }
            } else {
                VStack {
                    if !model.isScanningDisk {
                        EmptyStateCard(
                            systemImage: "chart.pie",
                            title: model.t("readyToAnalyzeDisk"),
                            detail: model.t("analyzeDiskDetail")
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppTheme.background)
    }
}

private struct DiskSummaryView: View {
    let analysis: DiskAnalysisResult
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("diskSummary", language))
                        .font(.headline)
                    Text("\(analysis.volume.freeBytes.storageText) \(L10n.text("freeOf", language)) \(analysis.volume.totalBytes.storageText)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                }
                Spacer()
                Text(percentText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.16))
                    Capsule()
                        .fill(Color.green.opacity(0.72))
                        .frame(width: proxy.size.width * freeRatio)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))
    }

    private var freeRatio: CGFloat {
        guard analysis.volume.totalBytes > 0 else { return 0 }
        return max(0, min(CGFloat(analysis.volume.freeBytes) / CGFloat(analysis.volume.totalBytes), 1))
    }

    private var percentText: String {
        "\(Int((freeRatio * 100).rounded()))% free"
    }
}

private struct DiskCategoryRow: View {
    let category: DiskCategorySummary
    let total: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(category.bytes.storageText) • \(percentText)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.12))
                    Capsule()
                        .fill(color.opacity(0.72))
                        .frame(width: proxy.size.width * ratio)
                }
            }
            .frame(height: 8)
            Text(category.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var ratio: CGFloat {
        guard total > 0 else { return 0 }
        return max(0, min(CGFloat(category.bytes) / CGFloat(total), 1))
    }

    private var percentText: String {
        "\(Int((ratio * 100).rounded()))%"
    }

    private var color: Color {
        switch category.colorName {
        case "orange": .orange
        case "pink": .pink
        case "purple": .purple
        case "green": .green
        case "teal": .teal
        case "red": .red
        case "yellow": .yellow
        default: .blue
        }
    }
}

private struct DiskItemRow: View {
    let item: DiskUsageItem
    let isSelected: (DiskUsageItem) -> Bool
    let toggle: (DiskUsageItem) -> Void
    let language: AppLanguage

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                if item.children.isEmpty {
                    Image(systemName: "circle")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14, height: 20)
                } else {
                    Button {
                        expanded.toggle()
                    } label: {
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .frame(width: 14, height: 20)
                    }
                    .buttonStyle(.plain)
                }

                Toggle("", isOn: Binding(get: { isSelected(item) }, set: { _ in toggle(item) }))
                    .labelsHidden()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        RecommendationBadge(recommendation: item.recommendation, language: language)
                        Spacer()
                        Text(item.bytes.storageText)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                    }

                    Text(item.path.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(item.purpose)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let lastAccessed = item.lastAccessed {
                        Text("\(L10n.text("lastUsed", language)): \(lastAccessed.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(item.children) { child in
                        DiskItemRow(item: child, isSelected: isSelected, toggle: toggle, language: language)
                    }
                }
                .padding(.leading, 24)
            }
        }
    }
}

private struct RecommendationBadge: View {
    let recommendation: DiskItemRecommendation
    let language: AppLanguage

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
    }

    private var title: String {
        switch recommendation {
        case .removable: L10n.text("canDelete", language)
        case .review: L10n.text("reviewBeforeDelete", language)
        case .keep: L10n.text("keep", language)
        }
    }

    private var color: Color {
        switch recommendation {
        case .removable: .green
        case .review: .orange
        case .keep: .red
        }
    }
}

private struct AppCard: View {
    let app: InstalledApp
    let isCleaning: Bool
    let selectedBytes: Int64
    let isPathSelected: (CleanupPathEntry) -> Bool
    let togglePath: (CleanupPathEntry) -> Void
    let language: AppLanguage
    let uninstall: () -> Void

    @State private var confirmUninstall = false
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AppIconView(url: app.appURL)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(app.bundleID ?? "No bundle identifier")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }

            HStack {
                Label(selectedBytes.storageText, systemImage: "internaldrive")
                    .font(.subheadline.weight(.medium))
                if app.requiresAdmin {
                    AdminBadge(language: language)
                }
                Spacer()
                Text("\(max(app.relatedPaths.count - 1, 0)) \(L10n.text("related", language))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(app.appURL.path)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)

            HStack {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([app.appURL])
                } label: {
                    Label(L10n.text("reveal", language), systemImage: "finder")
                }

                Spacer()

                Button(role: .destructive) {
                    confirmUninstall = true
                } label: {
                    Label(L10n.text("uninstall", language), systemImage: "trash")
                }
                .disabled(isCleaning)
            }

            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                    Text("\(app.relatedEntries.count) root paths")
                        .font(.caption.weight(.medium))
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(app.relatedEntries) { entry in
                        PathEntryRow(
                            entry: entry,
                            isSelected: isPathSelected,
                            toggle: togglePath,
                            language: language
                        )
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        )
        .confirmationDialog(
            "Uninstall \(app.name)?",
            isPresented: $confirmUninstall,
            titleVisibility: .visible
        ) {
            Button(L10n.text("uninstall", language), role: .destructive, action: uninstall)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the app and local support data found by VigClean. macOS may ask for an administrator password for apps in /Applications.")
        }
    }
}

private struct UtilityPanel: View {
    @ObservedObject var model: CleanerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(model.t("options"))
                    .font(.headline)

                Toggle(model.t("deletePermanently"), isOn: $model.permanentlyDelete)
                Toggle(model.t("quitAffectedApps"), isOn: $model.terminateAffectedApps)
                Toggle(model.t("askAdmin"), isOn: $model.requestAdminWhenNeeded)
                Toggle(model.t("scanPrivateFolders"), isOn: $model.includePrivacySensitiveScan)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text(model.t("selection"))
                    .font(.headline)

                HStack(spacing: 10) {
                    Button {
                        model.selectAllSafe()
                    } label: {
                        Label(model.t("selectRecommended"), systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CompactUtilityButtonStyle())

                    Button {
                        model.clearSelection()
                    } label: {
                        Label(model.t("clearSelection"), systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CompactUtilityButtonStyle())
                }
            }

            Divider()

            Text(model.t("risk"))
                .font(.headline)

            RiskLegend(title: model.t("safe"), detail: "Cache and generated files.", color: .green)
            RiskLegend(title: model.t("review"), detail: "Rebuildable, but can affect dev workflow.", color: .orange)
            RiskLegend(title: model.t("personal"), detail: "App data or project dependencies.", color: .red)

            if !model.lastErrors.isEmpty {
                Divider()
                Text("Errors")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.lastErrors, id: \.self) { error in
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.panel)
    }
}

private struct PrimaryUtilityButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? Color.accentColor : Color.gray.opacity(0.35))
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct DestructiveUtilityButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(isEnabled ? .red : .secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? Color.red.opacity(0.12) : Color.gray.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? Color.red.opacity(0.28) : Color.gray.opacity(0.16), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct CompactUtilityButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isEnabled ? .primary : .secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.control)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct FindingRow: View {
    let finding: CleanupFinding
    let isSelected: Bool
    let isPathSelected: (CleanupPathEntry) -> Bool
    let onToggle: () -> Void
    let onTogglePath: (CleanupPathEntry) -> Void
    let language: AppLanguage

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Toggle("", isOn: Binding(get: { isSelected }, set: { _ in onToggle() }))
                    .labelsHidden()
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(finding.title)
                            .font(.headline)
                        RiskBadge(risk: finding.risk, language: language)
                        if finding.requiresAdmin {
                            AdminBadge(language: language)
                        }
                        Spacer()
                        Text(finding.bytes.storageText)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.primary)
                    }

                    Text(finding.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text(pathSummary)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                    Text("\(finding.pathEntries.count) root paths")
                        .font(.caption.weight(.medium))
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.leading, 34)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(finding.pathEntries) { entry in
                        PathEntryRow(
                            entry: entry,
                            isSelected: isPathSelected,
                            toggle: onTogglePath,
                            language: language
                        )
                    }
                }
                .padding(.leading, 34)
                .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
    }

    private var pathSummary: String {
        if finding.paths.count == 1 {
            return finding.paths[0].path
        }
        return "\(finding.paths.count) paths, including \(finding.paths[0].path)"
    }
}

private struct AppIconView: View {
    let url: URL

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .interpolation(.high)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
    }
}

private struct PathEntryRow: View {
    let entry: CleanupPathEntry
    let isSelected: (CleanupPathEntry) -> Bool
    let toggle: (CleanupPathEntry) -> Void
    let language: AppLanguage
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                if entry.children.isEmpty {
                    Image(systemName: "circle")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14, height: 18)
                } else {
                    Button {
                        expanded.toggle()
                    } label: {
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .frame(width: 14, height: 18)
                    }
                    .buttonStyle(.plain)
                }

                Toggle("", isOn: Binding(get: { isSelected(entry) }, set: { _ in toggle(entry) }))
                    .labelsHidden()

                Image(systemName: entryIcon)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.url.lastPathComponent.isEmpty ? entry.url.path : entry.url.lastPathComponent)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        if entry.requiresAdmin {
                            AdminBadge(language: language)
                        }
                        Spacer()
                        Text(entry.bytes.storageText)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.url.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.children) { child in
                        PathEntryRow(
                            entry: child,
                            isSelected: isSelected,
                            toggle: toggle,
                            language: language
                        )
                    }
                }
                .padding(.leading, 22)
            }
        }
    }

    private var entryIcon: String {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: entry.url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue ? "folder" : "doc"
    }
}

private struct AdminBadge: View {
    let language: AppLanguage

    var body: some View {
        Text(L10n.text("admin", language))
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.14), in: Capsule())
            .foregroundStyle(.red)
    }
}

private struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

private struct MetricPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.headline, design: .rounded))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

private struct RiskLegend: View {
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RiskBadge: View {
    let risk: CleanupRisk
    let language: AppLanguage

    var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.16), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch risk {
        case .safe: .green
        case .review: .orange
        case .personal: .red
        }
    }

    private var title: String {
        switch risk {
        case .safe: L10n.text("safe", language)
        case .review: L10n.text("review", language)
        case .personal: L10n.text("personal", language)
        }
    }
}

private enum AppTheme {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let header = Color(nsColor: .controlBackgroundColor)
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let card = Color(nsColor: .textBackgroundColor)
    static let control = Color(nsColor: .quaternaryLabelColor).opacity(0.12)
}
