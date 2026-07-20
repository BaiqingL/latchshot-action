#!/usr/bin/env bash
set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

arguments_file="$temporary_dir/curl-arguments.txt"
github_output="$temporary_dir/github-output.txt"
capture_output="$temporary_dir/full-page.png"

PATH="$repository_dir/test/bin:$PATH" \
RUNNER_TEMP="$temporary_dir" \
GITHUB_OUTPUT="$github_output" \
LATCHSHOT_TEST_ARGS="$arguments_file" \
LATCHSHOT_API_KEY="ls_live_test_only" \
LATCHSHOT_URL="https://example.com/catalog" \
LATCHSHOT_OUTPUT="$capture_output" \
LATCHSHOT_WIDTH="1200" \
LATCHSHOT_HEIGHT="800" \
LATCHSHOT_FORMAT="png" \
LATCHSHOT_FULL_PAGE="true" \
LATCHSHOT_SCROLL_PAGE="true" \
LATCHSHOT_DARK_MODE="false" \
  bash "$repository_dir/scripts/capture.sh" > "$temporary_dir/stdout.txt"

[[ "$(<"$capture_output")" == "PNG_TEST_BYTES" ]]
grep -Fx 'fullPage=true' "$arguments_file"
grep -Fx 'scrollPage=true' "$arguments_file"
grep -Fx 'scroll=complete' "$github_output"
grep -F 'scroll complete' "$temporary_dir/stdout.txt"

invalid_arguments="$temporary_dir/invalid-curl-arguments.txt"
set +e
PATH="$repository_dir/test/bin:$PATH" \
LATCHSHOT_TEST_ARGS="$invalid_arguments" \
LATCHSHOT_API_KEY="ls_live_test_only" \
LATCHSHOT_URL="https://example.com" \
LATCHSHOT_FULL_PAGE="false" \
LATCHSHOT_SCROLL_PAGE="true" \
  bash "$repository_dir/scripts/capture.sh" > "$temporary_dir/invalid-stdout.txt" 2> "$temporary_dir/invalid-stderr.txt"
status=$?
set -e

[[ "$status" -eq 2 ]]
[[ ! -e "$invalid_arguments" ]]
grep -F 'scroll_page requires full_page to be true' "$temporary_dir/invalid-stderr.txt"

printf 'Action contract tests passed.\n'
