# VigClean 0.0.3

VigClean 0.0.3 is a compatibility, distribution, and cleanup-safety update.

## Highlights

- Supports macOS 13 Ventura and later instead of requiring macOS 14 Sonoma.
- Distributed free of charge with an ad-hoc app signature instead of Apple Developer ID notarization.
- Fixed release packaging for current SwiftPM/Xcode output paths so arm64, x86_64, and Universal artifacts contain the intended fresh binary.
- Canonicalizes macOS `/var`, `/tmp`, and `/etc` firmlinks and revalidates symlink targets immediately before deletion.
- Classifies cleanup paths as removable, administrator-required, protected, or unavailable.
- Deduplicates overlapping parent/child selections and counts allocated bytes truthfully, including hidden files and hard links.
- Adds a 10,000-path safety cap and cancellable cleanup with partial-result reporting.
- Keeps Trash-first deletion, protected paths, risk review, and signed Sparkle updates.

## Install

Download the Universal DMG for most Macs. Apple Silicon and Intel-specific packages are also provided. On macOS 12 Monterey or earlier, VigClean remains unsupported.

On first launch, right-click **VigClean.app**, choose **Open**, then confirm **Open**. If macOS still blocks it, open **System Settings → Privacy & Security** and choose **Open Anyway** for VigClean.

Documentation: https://vigclean-guide.netlify.app
