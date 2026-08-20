#!/usr/bin/env bash
set -euo pipefail

readonly SOURCE_URL="${SOURCE_URL:-https://raw.githubusercontent.com/runetfreedom/russia-blocked-geosite/release/ru-blocked-all.txt}"
readonly MIHOMO_RELEASE_API="https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"
readonly OUTPUT_FILE="${OUTPUT_FILE:-ru-blocked-all.mrs}"

work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT

source_file="$work_dir/ru-blocked-all.txt"
release_json="$work_dir/mihomo-release.json"
mihomo_archive="$work_dir/mihomo.gz"
mihomo_binary="$work_dir/mihomo"
output_tmp="$work_dir/ru-blocked-all.mrs"

echo "Downloading the current RunetFreedom ru-blocked-all list..."
curl --fail --location --retry 3 --retry-all-errors \
  --output "$source_file" "$SOURCE_URL"

line_count="$(wc -l < "$source_file")"
if (( line_count < 100000 )); then
  echo "Refusing to build: the source contains only $line_count lines." >&2
  exit 1
fi

echo "Resolving the latest stable official Mihomo release..."
github_api_headers=(
  --header "Accept: application/vnd.github+json"
  --header "X-GitHub-Api-Version: 2022-11-28"
)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  github_api_headers+=(--header "Authorization: Bearer $GITHUB_TOKEN")
fi
curl --fail --location --retry 3 --retry-all-errors \
  "${github_api_headers[@]}" \
  --output "$release_json" "$MIHOMO_RELEASE_API"

asset_pattern='^mihomo-linux-amd64-v[0-9]+\.[0-9]+\.[0-9]+\.gz$'
asset_url="$(jq -r --arg pattern "$asset_pattern" \
  '.assets[] | select(.name | test($pattern)) | .browser_download_url' \
  "$release_json" | head -n 1)"
asset_digest="$(jq -r --arg pattern "$asset_pattern" \
  '.assets[] | select(.name | test($pattern)) | (.digest // "")' \
  "$release_json" | head -n 1)"

if [[ -z "$asset_url" ]]; then
  echo "The latest stable Mihomo release has no matching linux-amd64 asset." >&2
  exit 1
fi

echo "Downloading Mihomo from $asset_url"
curl --fail --location --retry 3 --retry-all-errors \
  --output "$mihomo_archive" "$asset_url"

if [[ "$asset_digest" == sha256:* ]]; then
  expected_sha256="${asset_digest#sha256:}"
  actual_sha256="$(sha256sum "$mihomo_archive" | awk '{print $1}')"
  if [[ "$actual_sha256" != "$expected_sha256" ]]; then
    echo "Mihomo archive checksum mismatch." >&2
    exit 1
  fi
fi

gzip --decompress --stdout "$mihomo_archive" > "$mihomo_binary"
chmod +x "$mihomo_binary"
"$mihomo_binary" -v

echo "Converting $line_count domain rules to MRS..."
"$mihomo_binary" convert-ruleset domain text "$source_file" "$output_tmp"

if [[ ! -s "$output_tmp" ]]; then
  echo "Mihomo produced an empty rule-set." >&2
  exit 1
fi

mv -- "$output_tmp" "$OUTPUT_FILE"
echo "Wrote $OUTPUT_FILE ($(wc -c < "$OUTPUT_FILE") bytes)."

