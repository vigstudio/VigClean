#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.0.1}"
DIST_DIR="$ROOT_DIR/dist/$VERSION"
BUILD_APPS_DIR="$ROOT_DIR/build/release-$VERSION"
ICONSET_DIR="$ROOT_DIR/build/AppIcon.iconset"
SOURCE_ICON="$ROOT_DIR/Sources/VigClean/Resources/VigCleanLogo.png"

cd "$ROOT_DIR"

rm -rf "$DIST_DIR" "$BUILD_APPS_DIR" "$ICONSET_DIR"
mkdir -p "$DIST_DIR" "$BUILD_APPS_DIR" "$ICONSET_DIR"

build_swift_arch() {
  local arch="$1"
  swift build --configuration release --arch "$arch"
}

create_icon() {
  sips -z 16 16 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$ICONSET_DIR" -o "$BUILD_APPS_DIR/AppIcon.icns"
}

copy_bundle_resources() {
  local source_build_dir="$1"
  local resources_dir="$2"

  if [ -d "$source_build_dir/VigClean_VigClean.bundle" ]; then
    cp -R "$source_build_dir/VigClean_VigClean.bundle" "$resources_dir/"
  fi
  cp "$BUILD_APPS_DIR/AppIcon.icns" "$resources_dir/AppIcon.icns"
}

create_app() {
  local name="$1"
  local binary="$2"
  local source_build_dir="$3"
  local app_dir="$BUILD_APPS_DIR/$name.app"
  local contents_dir="$app_dir/Contents"
  local macos_dir="$contents_dir/MacOS"
  local resources_dir="$contents_dir/Resources"

  rm -rf "$app_dir"
  mkdir -p "$macos_dir" "$resources_dir"

  cp "$binary" "$macos_dir/VigClean"
  cp "$ROOT_DIR/Packaging/Info.plist" "$contents_dir/Info.plist"
  copy_bundle_resources "$source_build_dir" "$resources_dir"
  chmod +x "$macos_dir/VigClean"

  if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$app_dir" >/dev/null
  fi
}

package_app() {
  local app_dir="$1"
  local base_name="$2"

  ditto -c -k --keepParent "$app_dir" "$DIST_DIR/$base_name.app.zip"
  hdiutil create \
    -volname "$base_name" \
    -srcfolder "$app_dir" \
    -ov \
    -format UDZO \
    "$DIST_DIR/$base_name.dmg" >/dev/null
}

echo "Building VigClean $VERSION for Apple Silicon..."
build_swift_arch arm64

echo "Building VigClean $VERSION for Intel..."
build_swift_arch x86_64

ARM_BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/release"
INTEL_BUILD_DIR="$ROOT_DIR/.build/x86_64-apple-macosx/release"
ARM_BINARY="$ARM_BUILD_DIR/VigClean"
INTEL_BINARY="$INTEL_BUILD_DIR/VigClean"
UNIVERSAL_BINARY="$BUILD_APPS_DIR/VigClean-universal"

create_icon

echo "Creating app bundles..."
create_app "VigClean-$VERSION-arm64" "$ARM_BINARY" "$ARM_BUILD_DIR"
create_app "VigClean-$VERSION-x86_64" "$INTEL_BINARY" "$INTEL_BUILD_DIR"
lipo -create "$ARM_BINARY" "$INTEL_BINARY" -output "$UNIVERSAL_BINARY"
create_app "VigClean-$VERSION-universal" "$UNIVERSAL_BINARY" "$ARM_BUILD_DIR"

echo "Creating ZIP and DMG assets..."
package_app "$BUILD_APPS_DIR/VigClean-$VERSION-arm64.app" "VigClean-$VERSION-arm64"
package_app "$BUILD_APPS_DIR/VigClean-$VERSION-x86_64.app" "VigClean-$VERSION-x86_64"
package_app "$BUILD_APPS_DIR/VigClean-$VERSION-universal.app" "VigClean-$VERSION-universal"

shasum -a 256 "$DIST_DIR"/* > "$DIST_DIR/SHA256SUMS.txt"

echo "$DIST_DIR"
