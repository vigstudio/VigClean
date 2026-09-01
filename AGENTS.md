# VigClean Project Memory

<!-- markdownlint-disable MD013 -->

This file is the durable source of truth for development sessions working on VigClean. Read it completely before changing the project. Update it in the same commit whenever a task changes product behavior, architecture, UI, release state, documentation, deployment, or the roadmap.

Do not store passwords, signing private keys, tokens, personal data, or machine-specific secrets in this file.

## Session protocol

At the beginning of every session:

1. Read this file completely.
2. Run `git status --short` and preserve unrelated user changes.
3. Read the source files relevant to the requested task instead of relying only on this summary.
4. Check the roadmap below before adding a feature that may already be planned or deliberately deferred.

Before finishing any implementation session:

1. Verify the result in proportion to its risk.
2. Update Current State if behavior or release state changed.
3. Update Roadmap status for completed, started, deferred, or rejected work.
4. Add a concise entry to Session Log with the date, outcome, verification, and commit when available.
5. Record important architectural or product decisions in Decision Log.
6. Commit this file together with the code it describes. Never leave the project memory claiming work that is not in the repository.

Status vocabulary:

- `DONE`: implemented and verified.
- `IN PROGRESS`: implementation exists but required work or verification remains.
- `PLANNED`: accepted direction, not implemented.
- `RESEARCH`: needs technical validation or product decision.
- `DEFERRED`: intentionally postponed.
- `REJECTED`: deliberately not planned, with a reason.

## Product identity

- Product: VigClean
- Repository: <https://github.com/vigstudio/VigClean>
- Platform: native macOS application
- Language and UI: Swift 6 and SwiftUI
- Minimum supported system for the next release: macOS 13 Ventura
- Current public release: `0.0.2`
- Latest release: <https://github.com/vigstudio/VigClean/releases/latest>
- Public bilingual guide: <https://vigclean-guide.netlify.app>
- Primary product promise: make storage cleanup understandable, recoverable by default, and explicit about risk.

VigClean is not intended to maximize the displayed amount of removable data at the cost of safety. A smaller accurate result is better than a large result containing protected, personal, inaccessible, or misleading entries.

## Current state

### Main interface

The app uses a sidebar with four areas:

- Clean: scan cleanup categories, review paths, select targets, and remove them.
- Applications: discover installed apps and associated data for uninstallation.
- Storage: analyze disk usage and inspect large folders and files.
- History: review completed cleanup and uninstall operations.

Long-running scans show:

- current operation and path;
- determinate percentage;
- progress bar;
- cancel control;
- disabled destructive actions while work is running.

### Cleanup categories

The current cleanup scanner includes:

- user caches;
- VS Code caches;
- Xcode DerivedData and device support data;
- Node, npm, npx, and Puppeteer caches;
- user logs and Trash;
- Gradle, Pub, CocoaPods, SwiftPM, pip, Poetry, pnpm, and Yarn caches;
- Chrome on-device model cache;
- developer build artifacts;
- large installers and archives when private-folder scanning is enabled;
- project `node_modules` as personal-risk, opt-in data;
- Zalo local data as personal-risk, opt-in data;
- large application data;
- Android SDK data as personal-risk, opt-in data;
- iOS Simulator devices as personal-risk, opt-in data.

Risk levels:

- Safe: generated or reproducible data. May be selected by default.
- Review: reproducible but can disrupt developer or application workflows.
- Personal: app state, project dependencies, downloads, documents, or user-created data. Never select by default.

### Safety behavior

- Trash-first deletion is the default.
- Permanent deletion requires explicit opt-in.
- A confirmation dialog shows selected count, total size, and risky groups.
- System roots, user roots, and sensitive subtrees are blocked by `DeletionSafetyValidator`.
- Users can protect additional paths. Protected paths are excluded from selection and deletion.
- Scan results classify every cleanup path as removable, administrator-required, protected, or unavailable. Protected and unavailable paths cannot be selected.
- Cleanup selection is normalized before preview and deletion: duplicate URLs and descendants of selected parents are removed, hidden files are included in allocated-size accounting, and hard links are counted once by device/inode identity.
- Cleanup execution has a 10,000-selected-path safety cap, checks cancellation between deletion roots, yields in bounded chunks, and exposes a cleanup Cancel control with partial-result reporting.
- Admin permission is requested only when required and enabled.
- Related apps can be quit before their data is removed.
- Downloads and Documents scanning is disabled by default.
- Cleanup and uninstall operations are written to local history.

Important limitation: normal deletion paths now canonicalize known macOS firmlinks and revalidate symlink resolution immediately before deletion. Administrator deletion is revalidated before the authorization command is launched, but a privileged helper would be required to eliminate the authorization-window race completely. Operation caps are not yet implemented.

### Application removal

VigClean discovers installed applications and searches related locations including caches, preferences, containers, logs, saved state, WebKit data, HTTP storage, and application support data. Users can expand and review the path list before removal.

### Storage analysis

The storage analyzer groups disk usage, exposes large paths, supplies risk guidance, and lets the user select reviewed entries for cleanup. It does not yet provide a treemap, duplicate detection, or last-access-date filtering.

### Updates and distribution

- Sparkle `2.9.6` is integrated.
- Automatic update checks use the GitHub-hosted `appcast.xml`.
- Update archives are verified with an EdDSA signature.
- Release assets are produced for arm64, x86_64, and Universal architectures in ZIP and DMG formats.
- Version `0.0.3` release candidates target macOS 13.0 and use hardened runtime. Public release is blocked until the `vingamagic@icloud.com` Apple ID belongs to a paid Apple Developer Program team that can issue a Developer ID Application certificate and submit notarization requests.
- `Scripts/build-app.sh` embeds Sparkle and applies the expected runtime search path.
- `Scripts/package-release.sh` creates release archives and checksums.
- Release packaging removes temporary arm64, x86_64, and Universal app bundles after producing distribution assets so Spotlight does not present staging copies as installed apps.
- Version `0.0.2` was released publicly on GitHub.

### Documentation and website

- `README.md` contains download links, release highlights, and real app screenshots.
- `site/` contains the public Vietnamese and English guide.
- The guide defaults to Vietnamese and provides installation, first scan, cleanup, app removal, storage analysis, history, updates, recovery, permissions, and troubleshooting instructions.
- The guide uses real VigClean screenshots, a responsive table of contents, dark mode, reduced-motion support, and a language switch.
- Netlify site name: `vigclean-guide`.
- Netlify site ID: `4f586e1e-3074-46e5-b326-600f060b3915`.
- Latest verified guide deployment at the time of this entry: `6a96549b0b463e4593e14331`.
- Local Lighthouse verification: Performance 100, Accessibility 100, Best Practices 100, SEO 100.

## Repository map

```text
Package.swift                         Swift package and Sparkle dependency
Package.resolved                      Resolved Swift dependencies
Packaging/Info.plist                  App metadata and Sparkle configuration
Sources/VigClean/VigCleanApp.swift    App entry point and update menu
Sources/VigClean/CleanerView.swift    Main SwiftUI interface
Sources/VigClean/CleanerViewModel.swift
                                      App state, scans, cleanup, history
Sources/VigClean/CleanupScanner.swift Cleanup and application scanning/deletion
Sources/VigClean/DiskAnalyzer.swift   Storage analysis
Sources/VigClean/DeletionSafetyValidator.swift
                                      Deletion path validation
Sources/VigClean/CleanupModels.swift  Shared product models
Sources/VigClean/Localization.swift   Vietnamese, English, Japanese strings
Tests/VigCleanTests/                  Safety and behavior tests
Scripts/build-app.sh                  Build app bundle
Scripts/package-release.sh            Produce release packages
Packaging/                            macOS bundle metadata and assets
Docs/screenshots/                     Full-resolution app screenshots
site/                                 Public bilingual HTML guide
appcast.xml                           Sparkle update feed
RELEASE_NOTES.md                      Current release notes
README.md                             Public repository documentation
AGENTS.md                             This durable project memory
```

## Design principles

### Product UI

- Show state, progress, current work, and outcome. Never leave a long operation looking frozen.
- Use plain labels that describe the action and consequence.
- Make the safe choice the easy default.
- Show paths and risk before deletion.
- Do not use color as the only risk signal.
- Disable or hide actions that cannot currently succeed.
- Prefer accurate recovered space over optimistic estimates.
- Keep destructive options visually distinct without making the interface alarming.

### Public website

- The site is a user guide first, not a generic marketing landing page.
- Use direct, natural Vietnamese and English.
- Avoid vague advertising phrases, forced metaphors, and claims that are not verified.
- Every major workflow should include steps and a real screenshot where useful.
- Keep the existing public URL stable.
- Preserve semantic HTML, keyboard navigation, contrast, mobile layout, system dark mode, and reduced motion.

## Cleanup engineering principles

Every deletion path should eventually follow this pipeline:

1. Declare a narrow scan target and its risk.
2. Enumerate without following unsafe links.
3. Standardize and canonicalize the candidate path.
4. Reject protected, personal-by-default, stale, inaccessible, and uncleanable candidates.
5. Deduplicate overlapping parent and child paths.
6. Calculate allocated size without double-counting.
7. Present the exact candidate and reason to the user.
8. Re-resolve and revalidate immediately before deletion.
9. Move to Trash by default.
10. Process large selections in cancellable chunks.
11. Record successes, skips, errors, and actual recovered space.

Never treat a broad directory as safe merely because its name contains `Cache`, `Logs`, `tmp`, or `Trash`.

## External research

### Mole

Reference: <https://github.com/tw93/mole>

Useful directions already considered for VigClean:

- broader developer-cache coverage;
- fast targeted scans;
- application leftover discovery;
- interactive review before deletion;
- maintenance tasks separated from ordinary cleanup.

Do not copy CLI interaction patterns directly into the native UI. Preserve VigClean's path visibility, risk grouping, and recoverable defaults.

### MacSai

Reference: <https://github.com/iliyami/MacSai>

MacSai is licensed under BSD 3-Clause. Directly reused source must retain its copyright notice, license conditions, and disclaimer. Do not use the MacSai name or contributor names to endorse VigClean without permission. Prefer independently implementing concepts unless direct reuse provides a clear maintenance benefit.

Current MacSai source composes roughly 20 System Junk categories, including user/system caches and logs, unused language resources, broken preferences and login items, document versions, broken or incomplete downloads, iOS backups, old updates, Universal binaries, Xcode data, deleted-user data, unused disk images, app leftovers, package-manager caches, IDE caches, and AI-tool caches.

High-value methods learned from the code review:

- Cleanability pre-filter: check whether the current process can actually modify the parent and descend into a directory before showing it as removable.
- Dry run: execute safety and accounting logic without touching files.
- Chunked cleanup: process large selections in bounded batches, yield to the UI, and honor cancellation between batches.
- Recursive allocated-size accounting before deletion.
- Firmlink canonicalization for `/var`, `/tmp`, and `/etc` versus `/private/...` forms.
- Resolve symlinks and reject suspicious target changes.
- Revalidate paths immediately before deletion to reduce time-of-check/time-of-use risk.
- Restrict generic orphan deletion to safe cache, log, saved-state, HTTP-storage, and WebKit locations.
- Progressive duplicate detection: group by size, hash a small prefix, hash full content, then deduplicate by inode.
- APFS duplicate consolidation: replace redundant copies with copy-on-write clones while keeping paths. This is powerful but requires careful atomic replacement and is not an early milestone.
- Incremental scan cache using SQLite plus FSEvents invalidation.
- Error-level operation logs with individual paths and automatic pruning.

Features that should not be copied without substantial validation:

- Secure overwrite claims on SSD/APFS. Copy-on-write and wear leveling make reliable physical erasure difficult to guarantee.
- Free RAM tasks. macOS manages memory pressure and cache automatically.
- Automatic browser-history or cookie deletion. It can destroy sessions and sign users out.
- Emptying every external-volume Trash by default. Scope and recovery expectations are unclear.
- Signature-only malware scanning without a maintained update and response model. It can create false confidence.
- Universal Binary thinning as a normal cleanup default. It modifies application bundles and requires transactional backup, compatibility policy, signature validation, and rollback.

### Features not approved for near-term implementation

- `REJECTED` Guaranteed secure overwrite or physical-erase claims on APFS SSDs. VigClean may offer ordinary permanent deletion but must not claim recovery is physically impossible.
- `REJECTED` Free RAM or memory purge tasks. macOS already manages cache and memory pressure; presenting this as cleanup would be misleading.
- `RESEARCH` Browser history, cookie, and session cleanup. Do not implement until browser detection, time-scoped selection, explicit browser shutdown, profile separation, and never-selected-by-default behavior are designed and tested.
- `RESEARCH` Trash cleanup across external volumes. Do not implement until volume-by-volume scope, permission handling, recovery expectations, and disconnected-volume behavior are explicit.
- `DEFERRED` Signature-only malware removal. Do not ship without a maintained signature/update pipeline, quarantine and response workflow, false-positive handling, and wording that does not create false confidence.
- `DEFERRED` Universal Binary thinning. Do not modify application bundles until transactional backup, signature verification, update compatibility, atomic replacement, and rollback are proven.
- `DEFERRED` APFS duplicate clone consolidation. Ordinary duplicate discovery and reviewed Trash-first removal must be stable first; clone replacement also requires atomicity and rollback tests.
- `DEFERRED` Automatic cleanup of Document Versions, iOS backups, preferences, login items, browser profiles, containers, keychains, and personal app databases. Any future scanner must be review-only, narrowly targeted, and covered by category-specific safety tests.

## Roadmap

### Engine safety and truthful results

- `DONE` Add a cleanability pre-filter so UI results distinguish removable, admin-required, protected, and unavailable items.
- `DONE` Canonicalize known macOS firmlinks before protected-path comparison.
- `DONE` Strengthen symlink handling and revalidate resolved targets immediately before deletion.
- `IN PROGRESS` Add explicit per-operation and total-item safety caps. The selected-path cap is implemented; recursive total filesystem-item accounting remains.
- `PLANNED` Add a real dry-run mode that exercises validation and accounting without file changes.
- `DONE` Deduplicate overlapping parent/child selections before size calculation and deletion.
- `IN PROGRESS` Process deletion in cancellable chunks with honest item and byte progress. Cancellation and bounded yields are implemented; structured item/byte progress remains.
- `PLANNED` Store per-path success, skip, and error details in the local operation log.
- `PLANNED` Add adversarial tests for symlinks, traversal, NULL bytes, firmlinks, stale paths, overlapping selections, and protected roots.

### User-facing cleanup features

- `PLANNED` Duplicate Finder using size, partial SHA-256, full SHA-256, and inode stages.
- `PLANNED` Large and Old Files with size, file type, and last-access filters.
- `PLANNED` Safe orphaned-app-data scan restricted to approved cache/log/state locations.
- `PLANNED` Mail attachment cache scan for Apple Mail, Outlook, and Spark, opt-in and review-only by default.
- `RESEARCH` Browser privacy cleanup with browser detection, time filters, explicit app shutdown, and no default selection.
- `RESEARCH` Trash discovery across external volumes with per-volume selection and clear recovery behavior.
- `DEFERRED` APFS clone consolidation for duplicates until ordinary duplicate removal is stable and tested.
- `DEFERRED` Universal Binary thinning until transaction, backup, signature, update, and rollback behavior are proven.

### Scan performance

- `PLANNED` Introduce a scan-result database with schema versioning and bounded retention.
- `PLANNED` Use FSEvents to invalidate only changed paths between scans.
- `PLANNED` Prefetch required `URLResourceKey` values during enumeration.
- `PLANNED` Limit concurrent directory work to avoid memory and file-descriptor spikes.
- `PLANNED` Measure cold scan, warm scan, cancellation latency, peak memory, and enumerated item count.

### Distribution and trust

- `IN PROGRESS` Add Apple Developer ID signing and notarization. Hardened-runtime packaging is complete, but the release owner is moving away from the former Developer ID team. The new `vingamagic@icloud.com` account currently has only a Personal Team and must join the Apple Developer Program before release signing and notarization can resume.
- `PLANNED` Publish through an official Homebrew cask after signed/notarized distribution is stable.
- `PLANNED` Automate release packaging, checksums, appcast update, and GitHub asset upload in CI.
- `PLANNED` Add an update-check preference and surface the current update channel.

### Documentation

- `DONE` Publish a bilingual Vietnamese/English visual guide.
- `DONE` Add real screenshots for Clean, Applications, Storage, and History.
- `PLANNED` Add installation screenshots after the app is signed and the final installation flow is stable.
- `PLANNED` Add feature-specific screenshots whenever a roadmap module ships.
- `PLANNED` Keep README, guide, release notes, and this file synchronized for each release.

### Explicit non-goals

- `REJECTED` Claiming guaranteed secure physical erase on APFS SSDs.
- `REJECTED` One-click deletion of personal folders without review.
- `REJECTED` Selecting browser sessions, cookies, Documents, Downloads, projects, SDKs, or messaging databases by default.
- `REJECTED` Showing inaccessible or protected files merely to inflate the amount found.
- `REJECTED` Running privileged helpers for ordinary user-owned cache cleanup.

## Recommended implementation order

The next development milestone should be completed in this order:

1. Cleanability classification and clearer result states.
2. Firmlink and symlink safety hardening with tests.
3. Selection deduplication and truthful allocated-size accounting.
4. Cancellable chunked deletion and detailed operation log.
5. Dry-run UI and engine mode.
6. Duplicate Finder.
7. Large and Old Files.
8. Incremental scan cache and FSEvents.

Do not begin Universal Binary thinning or APFS clone consolidation before steps 1 through 5 are complete and covered by tests.

## Verification checklist

For cleanup-engine changes:

- Run `swift test`.
- Add tests that use temporary fixtures and never touch the real home directory.
- Verify Trash mode and dry-run mode separately.
- Verify cancellation and partial failure behavior.
- Verify protected paths and user-protected paths.
- Verify displayed bytes are not double-counted.

For UI changes:

- Build and launch the real app.
- Check empty, scanning, results, confirmation, cleaning, completed, cancelled, and error states.
- Check Vietnamese and English strings. Japanese currently exists in the app and must not be broken.
- Check the minimum supported window size and a typical large desktop window.
- Ensure percentages and progress text remain readable.

For website changes:

- Validate HTML and JavaScript.
- Test Vietnamese and English.
- Test desktop and mobile layouts.
- Check console errors and missing assets.
- Run Lighthouse before deployment.
- Verify the production URL after deployment.

For a release:

- Run all tests.
- Build arm64, x86_64, and Universal packages.
- Validate app architecture and bundle version.
- Validate code signature in proportion to the signing mode.
- Verify Sparkle signature and appcast enclosure size.
- Verify SHA-256 checksums.
- Publish release notes and assets.
- Confirm public download and appcast URLs return successfully.
- Update README, guide, this file, and Session Log.

## Decision log

- 2026-08-31: Redesigned the product around an explicit sidebar, visible progress, cancellation, risk levels, protected paths, and operation history.
- 2026-08-31: Chose Trash-first behavior. Permanent deletion remains an explicit option.
- 2026-08-31: Integrated Sparkle with signed GitHub-hosted appcast updates.
- 2026-08-31: Released version `0.0.2` for arm64, x86_64, and Universal architectures.
- 2026-08-31: Published the bilingual guide on Netlify.
- 2026-09-01: Replaced the guide's marketing-heavy copy with task-based product documentation and troubleshooting.
- 2026-09-01: After reviewing MacSai, prioritized cleanability filtering, chunked cancellable deletion, dry run, duplicate detection, and incremental scanning. Deferred higher-risk binary thinning and APFS consolidation.
- 2026-09-01: Established this `AGENTS.md` as the single durable project-memory and roadmap file for future sessions.
- 2026-09-01: Classified cleanup paths before selection and made protected or unavailable results non-selectable while preserving explicit administrator-required results.
- 2026-09-01: Kept release app bundles as temporary staging artifacts and removed them automatically after packaging to avoid duplicate VigClean results in Spotlight.
- 2026-09-01: Canonicalized `/var`, `/tmp`, and `/etc` firmlinks, rejected suspicious symlink redirects, and required the resolved target to remain unchanged immediately before deletion.
- 2026-09-01: Explicitly deferred or rejected cleanup features whose safety, recovery, or truthfulness contracts are not yet proven.
- 2026-09-01: Made cleanup previews and deletion payloads share one normalized selection plan, with recursive allocated-size accounting that includes hidden files and deduplicates hard links.
- 2026-09-01: Lowered the supported deployment target from macOS 14 to macOS 13 after replacing the macOS 14-only `onChange` overload and verifying both architectures link with `minos 13.0`.
- 2026-09-01: Required Developer ID signing and hardened runtime for release packages; public `0.0.3` publishing must wait for successful notarization and Gatekeeper assessment.
- 2026-09-02: Removed the former Developer ID identity from release defaults after the release owner chose to stop using that Apple account. Release packaging now requires an explicitly supplied Developer ID Application identity and rejects Apple Development/Personal Team certificates; `vingamagic@icloud.com` must first join a paid Apple Developer Program team.

## Session log

### 2026-08-31: VigClean 0.0.2

- Redesigned the app UI and UX.
- Added determinate scan progress, percentages, current-path detail, and cancellation.
- Expanded cleanup categories and application leftover detection.
- Added protected paths, safer selection defaults, Trash-first deletion, and history.
- Reworked logo assets and README.
- Integrated Sparkle automatic updates and signed the release archive.
- Packaged and published `v0.0.2` on GitHub.
- Captured real app screenshots.
- Published the bilingual guide to Netlify.
- Verification included Swift tests, architecture checks, code-sign validation, Sparkle signature validation, checksums, live URLs, and Lighthouse.
- Commit: `85bd0e2`.

### 2026-09-01: Guide rewrite

- Rewrote the public site as an actual user guide rather than a marketing landing page.
- Added task-based navigation, installation steps, cleanup workflow, app removal, disk analysis, history, updates, recovery, permissions, and troubleshooting.
- Added the History screenshot and made Vietnamese the default language.
- Verified desktop and 390-pixel mobile layouts, language switching, FAQ interaction, absence of browser errors, valid HTML/JavaScript, and Lighthouse scores of 100 across all four categories.
- Deployed production site and verified the public result.
- Commit: `aedfbe6`.

### 2026-09-01: MacSai research and project memory

- Reviewed MacSai's current README, cleanup modules, safety guard, cleanability filter, cleaning engine, duplicate pipeline, FSEvents monitor, uninstaller, and BSD 3-Clause license.
- Recorded reusable methods, risks, rejected ideas, and an ordered implementation roadmap in this file.
- Verification: compared research findings against VigClean's current scanner, validator, disk analyzer, view model, and repository state.
- Commit: included with this entry.

### 2026-09-01: Cleanability classification

- Outcome: cleanup paths now expose removable, administrator-required, protected, and unavailable states.
- Important behavior or files changed: added a cleanability classifier, made protected and unavailable paths non-selectable, surfaced localized status badges, and excluded non-selectable paths from cleanup accounting.
- Verification performed: `swift test` passed with five tests across cleanability classification and deletion safety suites.
- Remaining limitation or follow-up: firmlink canonicalization and stronger symlink revalidation remain the next roadmap milestone.
- Commit: included with this entry.

### 2026-09-01: Remove release staging apps

- Outcome: release packaging no longer leaves three architecture-specific `VigClean.app` copies under `build/`.
- Important behavior or files changed: added an exit trap to clean release staging bundles and icon generation files after packaging; distribution ZIP, DMG, and checksum files remain intact.
- Verification performed: validated the packaging script with `bash -n` and confirmed the old release staging directory was removed.
- Remaining limitation or follow-up: `build/VigClean.app` intentionally remains as the local development app produced by `Scripts/build-app.sh`.
- Commit: included with this entry.

### 2026-09-01: Firmlink and symlink safety hardening

- Outcome: deletion validation now treats known macOS firmlink aliases consistently and refuses paths whose resolved target changes after initial validation.
- Important behavior or files changed: added canonical firmlink comparison, suspicious cross-scope symlink rejection, validation snapshots, immediate pre-delete revalidation, administrator-batch revalidation, and adversarial temporary-fixture tests.
- Verification performed: `swift test` passed eight tests across deletion safety and cleanability suites; `swift build -c release` passed.
- Remaining limitation or follow-up: the administrator authorization window cannot be made race-free without a validated privileged helper; selection deduplication and truthful allocated-size accounting are next.
- Commit: included with this entry.

### 2026-09-01: Truthful selection and allocated-size accounting

- Outcome: duplicate URLs and selected descendants are removed before preview and deletion, preventing double-counted bytes and repeated delete errors.
- Important behavior or files changed: added a shared cleanup selection plan, recursive allocated-size calculator, hidden-file accounting, device/inode hard-link deduplication, and consistent accounting for cleanup and uninstall selections.
- Verification performed: eleven tests passed using temporary fixtures, including parent/child deletion, hidden files, hard links, firmlinks, symlinks, protected paths, and cleanability; release build passed; real app UI verified empty, scanning, determinate progress, disabled destructive action, and cancellation states without deleting user data.
- Remaining limitation or follow-up: chunked cancellation, operation caps, byte progress, and detailed per-path logs are next. The host currently selects Command Line Tools by default, so verification used `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` to provide the required SwiftUI macro plugin.
- Commit: included with this entry.

### 2026-09-01: Cleanup caps and cancellation foundation

- Outcome: cleanup can be cancelled safely between selected roots and pathological selections above 10,000 paths are refused before filesystem mutation.
- Important behavior or files changed: added selected-path limits, bounded execution yields, cancellation state in delete results, tracked cleanup tasks, Cancel controls for cleanup/uninstall/disk operations, and partial-result status messaging.
- Verification performed: thirteen tests passed, including pre-cancelled deletion and over-limit selection fixtures; no real user data was modified.
- Remaining limitation or follow-up: recursive total-item caps, structured per-path results, byte/item progress, persisted detailed logs, and cancellation during administrator authorization remain.
- Commit: included with this entry.

### 2026-09-01: VigClean 0.0.3 compatibility release candidate

- Outcome: prepared a Developer ID-signed `0.0.3` release candidate supporting macOS 13 Ventura and later, and fixed architecture capture for current SwiftPM/Xcode output paths.
- Important behavior or files changed: changed deployment and bundle minimums to 13.0, replaced a macOS 14-only SwiftUI API, updated version/build metadata, enforced fresh per-architecture capture, hardened-runtime signing, signature verification, min-version checks, optional notarization/stapling, release notes, README, guide requirement, and Sparkle appcast metadata/signature.
- Verification performed: thirteen tests passed; arm64 and x86_64 release builds passed; Universal DMG contains both architectures with `minos 13.0`; bundle version is `0.0.3 (3)`; Developer ID signature, hardened runtime, Sparkle EdDSA signature, and SHA-256 checksums validated.
- Remaining limitation or follow-up: Gatekeeper correctly rejects the current candidate as `Unnotarized Developer ID`. Configure a `notarytool` keychain profile, rebuild with `VIGCLEAN_NOTARY_PROFILE`, staple, validate, run Gatekeeper assessment, then publish the GitHub release and appcast commit.
- Commit: included with this entry; do not publish this candidate until notarization succeeds.

### 2026-09-02: Release-account migration guard

- Outcome: release packaging no longer references or silently uses the former Developer ID account.
- Important behavior or files changed: removed the former signing identity default and made the packaging script require an explicit Developer ID Application certificate, rejecting Personal Team and Apple Development certificates.
- Verification performed: validated the packaging script syntax and confirmed that it fails safely when no release identity or a Personal Team development identity is supplied.
- Remaining limitation or follow-up: `vingamagic@icloud.com` currently belongs only to Personal Team `49NN45N3J2`; enroll it in the paid Apple Developer Program, create a Developer ID Application certificate, and configure notarization before publishing `0.0.3`.
- Commit: included with this entry.

## Session log template

Copy this block for future completed work:

```markdown
### YYYY-MM-DD: Short task name

- Outcome:
- Important behavior or files changed:
- Verification performed:
- Remaining limitation or follow-up:
- Commit:
```
