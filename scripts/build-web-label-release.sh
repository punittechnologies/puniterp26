#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tablet_root="$repo_root/apps/tablet"
apk_path="$tablet_root/build/app/outputs/apk/webLabel/release/app-webLabel-release.apk"

required_signing_variables=(
  PUNIT_WEBLABEL_STORE_FILE
  PUNIT_WEBLABEL_STORE_PASSWORD
  PUNIT_WEBLABEL_KEY_ALIAS
  PUNIT_WEBLABEL_KEY_PASSWORD
)

for variable_name in "${required_signing_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Required signing variable is missing: $variable_name" >&2
    exit 1
  fi
done

release_id="$(git -C "$repo_root" rev-parse --short=8 HEAD)"
previous_payload_hash=""

if [[ -f "$apk_path" ]]; then
  previous_payload_hash="$(unzip -p "$apk_path" lib/arm64-v8a/libapp.so | shasum -a 256 | awk '{print $1}')"
fi

cd "$tablet_root"

# Production releases must never reuse Flutter's previous AOT payload. This
# removes only generated build/cache output; application source is untouched.
flutter clean
flutter pub get
flutter build apk \
  --flavor webLabel \
  --release \
  --dart-define=PUNIT_WEB_LABEL_EDITION=true \
  --dart-define="PUNIT_RELEASE_ID=$release_id"

if [[ ! -f "$apk_path" ]]; then
  echo "Release APK was not generated: $apk_path" >&2
  exit 1
fi

current_payload_hash="$(unzip -p "$apk_path" lib/arm64-v8a/libapp.so | shasum -a 256 | awk '{print $1}')"

if [[ -n "$previous_payload_hash" && "$previous_payload_hash" == "$current_payload_hash" ]]; then
  echo "Release blocked: compiled Dart payload is unchanged after a clean build." >&2
  exit 1
fi

apk_hash="$(shasum -a 256 "$apk_path" | awk '{print $1}')"

echo "Web Label release built successfully."
echo "Release ID: $release_id"
echo "Dart payload SHA-256: $current_payload_hash"
echo "APK SHA-256: $apk_hash"
echo "APK: $apk_path"
