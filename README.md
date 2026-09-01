<p align="center">
  <img src="Sources/VigClean/Resources/VigCleanLogo.png" width="116" alt="VigClean logo">
</p>

<h1 align="center">VigClean</h1>

<p align="center">
  A fast, transparent and review-first cleaner for macOS.
</p>

<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-18211C?style=flat-square&logo=apple&logoColor=white">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-1FA35A?style=flat-square">
  <img alt="Release 0.0.3" src="https://img.shields.io/badge/release-0.0.3-08783F?style=flat-square">
</p>

<p align="center">
  <a href="https://github.com/vigstudio/VigClean/releases/latest"><strong>Download</strong></a>
  &nbsp;&nbsp;•&nbsp;&nbsp;
  <a href="https://vigclean-guide.netlify.app"><strong>Vietnamese / English Guide</strong></a>
</p>

VigClean is a native macOS cleaner built with SwiftUI. It helps users understand what is taking space on their Mac, review cleanup targets in detail, and delete only the files they intentionally select.

The app focuses on practical cleanup work instead of a one-click black box: it separates system cleanup, installed applications, and disk analysis into dedicated workflows so each scan is scoped to the job the user asked for.

<p align="center">
  <img src="Docs/VigCleanOverview.png" width="900" alt="VigClean smart cleanup interface">
</p>

## VigClean 0.0.3

Version 0.0.3 adds macOS Ventura 13 support, firmlink and symlink hardening, cleanup-path cleanability states, truthful allocated-size accounting, parent/child deduplication, operation limits, and cancellable cleanup.

Version 0.0.3 is distributed free of charge without Apple Developer ID notarization. On first launch, right-click **VigClean.app**, choose **Open**, then confirm **Open**. If macOS still blocks it, go to **System Settings → Privacy & Security** and choose **Open Anyway** for VigClean.

VigClean checks for releases every day using Sparkle. Update archives are verified with an EdDSA signature before extraction and installation. A manual **Check for Updates…** command is also available from the app menu.

## Interface Gallery

<p align="center">
  <img src="Docs/screenshots/clean-progress.png" width="820" alt="Cleanup scan with path, progress bar, percentage and cancel action">
</p>

<p align="center">
  <img src="Docs/screenshots/apps.png" width="820" alt="Installed application browser with related data and uninstall actions">
</p>

<p align="center">
  <img src="Docs/screenshots/disk.png" width="820" alt="Disk analysis with category totals, large folders and deletion guidance">
</p>

<p align="center">
  <img src="Docs/screenshots/history.png" width="820" alt="Cleanup history empty state">
</p>

## Highlights

- **Purpose-built macOS interface**: persistent sidebar navigation, compact page toolbars, a dedicated review panel, Finder integration, and a professional Dock icon.
- **Scoped scanning**: the Clean tab scans cleanup targets; the Apps tab scans installed applications; the Disk tab analyzes storage usage.
- **Review-first deletion**: cache files can be selected quickly, while personal data and developer dependencies are shown for review instead of being removed by default.
- **Tree-style cleanup targets**: each cleanup group can expose the exact folders and files found, making it possible to keep specific paths and delete only selected items.
- **App uninstaller**: lists apps from `/Applications` and `~/Applications`, shows icons and bundle identifiers, and can remove related support data.
- **Messaging app cleanup**: detects local data for Zalo, Telegram, WhatsApp, Signal, Discord, Slack, Messenger, LINE, Viber, Skype, and WeChat.
- **Disk analysis**: summarizes free/used space, breaks usage down by category, and surfaces large items with plain-English explanations and delete guidance.
- **Deterministic progress**: long scans and cleanup operations show the current path, a linear progress bar, and the exact completion percentage.
- **Multilingual UI**: includes Vietnamese, English, and Japanese language modes.
- **Admin escalation when needed**: regular user files are removed directly; protected locations can request administrator permission only when required.
- **Deletion Safety Engine**: every normal and administrator deletion is checked against protected roots, symlink resolution, traversal components, and user-protected paths.
- **Recoverable by default**: cleanup now moves files to the macOS Trash unless permanent deletion is explicitly enabled.
- **Persistent protection and history**: protect important paths across scans and review the last 100 cleanup, uninstall, and disk operations.
- **Cancellable scans**: stop cleanup, application, or disk scans without changing files.
- **Signed automatic updates**: checks GitHub Releases daily and verifies downloaded archives with Sparkle and EdDSA.

## Why VigClean Is Different

Many cleaner examples and small open-source utilities only remove a short hard-coded list of cache folders or provide a simple disk-size browser. VigClean is designed as a more complete maintenance tool:

- It combines cleanup, app uninstall, and disk inspection in one native macOS experience.
- It treats personal app data as high-risk and keeps it unselected by default.
- It understands developer-heavy storage such as Xcode DerivedData, simulator data, Android SDKs, package-manager caches, `node_modules`, build artifacts, and Codex/workspace outputs.
- It scans modern communication apps where local media and chat databases often consume large amounts of disk space.
- It shows what each item is likely used for, whether deletion is safe, and when the item should be reviewed first.
- It avoids forcing every cleanup flow through the same global scan button, keeping each tab responsible for its own work.

The goal is not just to free disk space. The goal is to make macOS storage explainable and give users precise control before anything is deleted.

## Interface Principles

- **Review before removal**: the selected size, item count, and risk state stay visible beside the destructive action.
- **Progress where work happens**: active operations appear in the page header and directly above the working area.
- **Clear risk language**: rebuildable, review-required, and personal data remain visually distinct.
- **Local by design**: scanning and cleanup happen on the Mac; scan results are not uploaded.
- **One job per workspace**: cleanup, app management, and disk analysis each have a dedicated destination in the sidebar.

## Main Workflows

### Clean

Use this tab to scan removable cleanup targets such as:

- user logs and Trash
- browser and app caches
- VS Code cache
- package-manager caches
- npm, npx, Puppeteer, Gradle, CocoaPods, SwiftPM, pip, Poetry, pnpm, and Yarn caches
- Xcode DerivedData and iOS DeviceSupport
- Flutter and local project build outputs
- large installers and archives
- optional high-impact items such as Android SDKs, simulator devices, `node_modules`, and messaging app data

Safe generated files are selected by default. Personal data and project dependencies are listed, but require explicit user selection.

### Apps

Use this tab to browse installed apps with native icons, search by name or bundle identifier, reveal apps in Finder, and uninstall an app together with related local files such as:

- Application Support
- Caches
- Preferences
- Containers and Group Containers
- Logs
- Saved Application State
- WebKit and HTTP storage

When removing an app, VigClean can quit the affected app process before deletion so locked files are easier to remove.

### Disk

Use this tab to understand overall storage usage:

- total disk capacity and free space
- category breakdown by percentage
- largest directories and files
- explanations of what common macOS and app folders are used for
- guidance on whether an item is usually safe to delete, should be reviewed, or should normally be kept

## Build

VigClean requires macOS 13 Ventura or later. Building from source requires Swift 6.

For end users, download the Universal DMG from [GitHub Releases](https://github.com/vigstudio/VigClean/releases/latest). A complete bilingual walkthrough is available at [vigclean-guide.netlify.app](https://vigclean-guide.netlify.app).

```bash
swift build
```

## Run

For development:

```bash
swift run VigClean
```

For a proper macOS app bundle with Dock icon and foreground activation:

```bash
chmod +x Scripts/build-app.sh
Scripts/build-app.sh
open build/VigClean.app
```

## Project Structure

```text
Sources/VigClean/
  CleanupScanner.swift      Cleanup target discovery and deletion
  DiskAnalyzer.swift        Disk usage analysis and item classification
  CleanerViewModel.swift    App state, scan actions, delete actions
  CleanerView.swift         SwiftUI interface
  CleanupModels.swift       Shared data models
  Localization.swift        Vietnamese, English, Japanese UI text
  VigCleanApp.swift         macOS app entry point
  Resources/                App logo and resources
Scripts/
  build-app.sh              Builds the macOS .app bundle
  package-release.sh        Creates release archives for each architecture
Packaging/
  Info.plist                Bundle metadata
site/                       Vietnamese / English public guide
```

## Safety Model

VigClean uses three broad risk levels:

- **Safe**: generated files, caches, logs, and files that apps can usually recreate.
- **Review**: files that are often removable but may affect developer workflows or require re-download/rebuild time.
- **Personal**: app data, chat media, local databases, project dependencies, SDKs, and simulator states that may be important to the user.

The app is intentionally conservative: personal and high-impact data is visible, explained, and left unchecked until the user chooses to remove it.

All deletion routes pass through `DeletionSafetyValidator`. It rejects empty or relative paths, traversal components, control characters, protected system trees, bare user roots, resolved symlink targets inside protected locations, and paths saved to the user's Protected List. The same validation runs again immediately before an administrator deletion.
