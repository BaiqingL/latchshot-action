#!/usr/bin/env bash
set -euo pipefail

api_key="${LATCHSHOT_API_KEY:-}"
target_url="${LATCHSHOT_URL:-}"
output_path="${LATCHSHOT_OUTPUT:-latchshot.png}"
width="${LATCHSHOT_WIDTH:-1440}"
height="${LATCHSHOT_HEIGHT:-900}"
format="${LATCHSHOT_FORMAT:-png}"
full_page="${LATCHSHOT_FULL_PAGE:-false}"
scroll_page="${LATCHSHOT_SCROLL_PAGE:-false}"
dark_mode="${LATCHSHOT_DARK_MODE:-false}"

if [[ -z "$api_key" ]]; then
  echo "::error::api_key is required; pass it from a GitHub Actions secret" >&2
  exit 2
fi

if [[ ! "$target_url" =~ ^https?:// ]]; then
  echo "::error::url must begin with http:// or https://" >&2
  exit 2
fi

if [[ ! "$width" =~ ^[0-9]+$ ]] || (( width < 320 || width > 2560 )); then
  echo "::error::width must be an integer from 320 to 2560" >&2
  exit 2
fi

if [[ ! "$height" =~ ^[0-9]+$ ]] || (( height < 240 || height > 1440 )); then
  echo "::error::height must be an integer from 240 to 1440" >&2
  exit 2
fi

if [[ "$format" != "png" && "$format" != "jpeg" ]]; then
  echo "::error::format must be png or jpeg" >&2
  exit 2
fi

if [[ "$full_page" != "true" && "$full_page" != "false" ]]; then
  echo "::error::full_page must be true or false" >&2
  exit 2
fi

if [[ "$scroll_page" != "true" && "$scroll_page" != "false" ]]; then
  echo "::error::scroll_page must be true or false" >&2
  exit 2
fi

if [[ "$scroll_page" == "true" && "$full_page" != "true" ]]; then
  echo "::error::scroll_page requires full_page to be true" >&2
  exit 2
fi

if [[ "$dark_mode" != "true" && "$dark_mode" != "false" ]]; then
  echo "::error::dark_mode must be true or false" >&2
  exit 2
fi

if [[ -z "$output_path" || "$output_path" == *$'\n'* || "$output_path" == *$'\r'* ]]; then
  echo "::error::output must be a non-empty single-line path" >&2
  exit 2
fi

mkdir -p "$(dirname "$output_path")"
headers_file="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/latchshot-headers-${RANDOM}.txt"
trap 'rm -f "$headers_file"' EXIT

curl --silent --show-error --fail-with-body \
  --retry 2 \
  --retry-delay 2 \
  --retry-connrefused \
  --retry-max-time 30 \
  --dump-header "$headers_file" \
  --get 'https://latchshot.fly.dev/v1/screenshot' \
  --header "Authorization: Bearer $api_key" \
  --data-urlencode "url=$target_url" \
  --data-urlencode "width=$width" \
  --data-urlencode "height=$height" \
  --data-urlencode "format=$format" \
  --data-urlencode "fullPage=$full_page" \
  --data-urlencode "scrollPage=$scroll_page" \
  --data-urlencode "darkMode=$dark_mode" \
  --output "$output_path"

header_value() {
  local name="$1"
  awk -F ': *' -v wanted="$name" 'tolower($1) == wanted { value=$2 } END { gsub("\r", "", value); print value }' "$headers_file"
}

render_ms="$(header_value 'x-latchshot-render-ms')"
quota_remaining="$(header_value 'x-quota-remaining')"
navigation="$(header_value 'x-latchshot-navigation')"
scroll="$(header_value 'x-latchshot-scroll')"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "path=$output_path"
    echo "render_ms=$render_ms"
    echo "quota_remaining=$quota_remaining"
    echo "navigation=$navigation"
    echo "scroll=$scroll"
  } >> "$GITHUB_OUTPUT"
fi

printf 'Captured %s to %s (%s ms, %s quota remaining, navigation %s, scroll %s)\n' \
  "$target_url" "$output_path" "${render_ms:-unknown}" "${quota_remaining:-unknown}" "${navigation:-unknown}" "${scroll:-unknown}"
