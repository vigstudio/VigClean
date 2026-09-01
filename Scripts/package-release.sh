#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.0.3}"
DIST_DIR="$ROOT_DIR/dist/$VERSION"
BUILD_APPS_DIR="$ROOT_DIR/build/release-$VERSION"
ICONSET_DIR="$ROOT_DIR/build/AppIcon.iconset"
SOURCE_ICON="$ROOT_DIR/Sources/VigClean/Resources/VigCleanLogo.png"
SPARKLE_FRAMEWORK="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
SIGNING_IDENTITY="${VIGCLEAN_SIGNING_IDENTITY:--}"
NOTARY_PROFILE="${VIGCLEAN_NOTARY_PROFILE:-}"

cleanup_staging() {
  rm -rf "$BUILD_APPS_DIR" "$ICONSET_DIR"
}

trap cleanup_staging EXIT

cd "$ROOT_DIR"

build_swift_arch() {
  local arch="$1"
  swift build --configuration release --arch "$arch"
}

capture_swift_product() {
  local arch="$1"
  local destination="$2"
  local bin_dir
  bin_dir="$(swift build --show-bin-path --configuration release --arch "$arch")"
  cp "$bin_dir/VigClean" "$destination"
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
  local variant="$1"
  local binary="$2"
  local source_build_dir="$3"
  local app_dir="$BUILD_APPS_DIR/$variant/VigClean.app"
  local contents_dir="$app_dir/Contents"
  local macos_dir="$contents_dir/MacOS"
  local resources_dir="$contents_dir/Resources"
  local frameworks_dir="$contents_dir/Frameworks"

  rm -rf "$app_dir"
  mkdir -p "$macos_dir" "$resources_dir" "$frameworks_dir"

  cp "$binary" "$macos_dir/VigClean"
  ditto "$SPARKLE_FRAMEWORK" "$frameworks_dir/Sparkle.framework"
  install_name_tool -add_rpath "@loader_path/../Frameworks" "$macos_dir/VigClean"
  cp "$ROOT_DIR/Packaging/Info.plist" "$contents_dir/Info.plist"
  copy_bundle_resources "$source_build_dir" "$resources_dir"
  chmod +x "$macos_dir/VigClean"

  if [ "$SIGNING_IDENTITY" = "-" ]; then
    codesign --force --deep --sign - "$app_dir" >/dev/null
  else
    codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$app_dir" >/dev/null
  fi
  codesign --verify --deep --strict --verbose=2 "$app_dir"
}

package_app() {
  local app_dir="$1"
  local base_name="$2"
  local notary_zip="$BUILD_APPS_DIR/$base_name-notary.zip"

  if [ -n "$NOTARY_PROFILE" ]; then
    ditto -c -k --keepParent "$app_dir" "$notary_zip"
    xcrun notarytool submit "$notary_zip" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$app_dir"
    xcrun stapler validate "$app_dir"
    rm -f "$notary_zip"
  fi

  ditto -c -k --keepParent "$app_dir" "$DIST_DIR/$base_name.app.zip"
  hdiutil create \
    -volname "$base_name" \
    -srcfolder "$app_dir" \
    -ov \
    -format UDZO \
    "$DIST_DIR/$base_name.dmg" >/dev/null
  if [ "$SIGNING_IDENTITY" != "-" ]; then
    codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DIST_DIR/$base_name.dmg" >/dev/null
  fi

  if [ -n "$NOTARY_PROFILE" ]; then
    xcrun notarytool submit "$DIST_DIR/$base_name.dmg" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DIST_DIR/$base_name.dmg"
    xcrun stapler validate "$DIST_DIR/$base_name.dmg"
  fi
}

if [ "$SIGNING_IDENTITY" = "-" ]; then
  if [ -n "$NOTARY_PROFILE" ]; then
    echo "Notarization requires VIGCLEAN_SIGNING_IDENTITY to be a Developer ID Application certificate." >&2
    exit 1
  fi
  echo "Packaging with an ad-hoc app signature. Gatekeeper will require the user to approve the app manually."
else
  IDENTITY_LINE="$(security find-identity -v -p codesigning | grep -F "$SIGNING_IDENTITY" | head -n 1 || true)"
  if [ -z "$IDENTITY_LINE" ]; then
    echo "Missing signing identity: $SIGNING_IDENTITY" >&2
    exit 1
  fi

  if [[ "$IDENTITY_LINE" != *'"Developer ID Application:'* ]]; then
    echo "Public release signing requires a Developer ID Application certificate; Apple Development and Personal Team certificates cannot be notarized." >&2
    exit 1
  fi
fi

rm -rf "$DIST_DIR" "$BUILD_APPS_DIR" "$ICONSET_DIR"
mkdir -p "$DIST_DIR" "$BUILD_APPS_DIR" "$ICONSET_DIR"

echo "Building VigClean $VERSION for Apple Silicon..."
build_swift_arch arm64
ARM_BINARY="$BUILD_APPS_DIR/VigClean-arm64"
capture_swift_product arm64 "$ARM_BINARY"

echo "Building VigClean $VERSION for Intel..."
build_swift_arch x86_64
INTEL_BINARY="$BUILD_APPS_DIR/VigClean-x86_64"
capture_swift_product x86_64 "$INTEL_BINARY"

SOURCE_BUILD_DIR="$(swift build --show-bin-path --configuration release --arch x86_64)"
UNIVERSAL_BINARY="$BUILD_APPS_DIR/VigClean-universal"

create_icon

echo "Creating app bundles..."
create_app "arm64" "$ARM_BINARY" "$SOURCE_BUILD_DIR"
create_app "x86_64" "$INTEL_BINARY" "$SOURCE_BUILD_DIR"
lipo -create "$ARM_BINARY" "$INTEL_BINARY" -output "$UNIVERSAL_BINARY"
create_app "universal" "$UNIVERSAL_BINARY" "$SOURCE_BUILD_DIR"

for binary in "$ARM_BINARY" "$INTEL_BINARY" "$UNIVERSAL_BINARY"; do
  otool -l "$binary" | grep -A4 LC_BUILD_VERSION | grep -q "minos 13.0"
done

echo "Creating ZIP and DMG assets..."
package_app "$BUILD_APPS_DIR/arm64/VigClean.app" "VigClean-$VERSION-arm64"
package_app "$BUILD_APPS_DIR/x86_64/VigClean.app" "VigClean-$VERSION-x86_64"
package_app "$BUILD_APPS_DIR/universal/VigClean.app" "VigClean-$VERSION-universal"

shasum -a 256 "$DIST_DIR"/* > "$DIST_DIR/SHA256SUMS.txt"

echo "$DIST_DIR"
