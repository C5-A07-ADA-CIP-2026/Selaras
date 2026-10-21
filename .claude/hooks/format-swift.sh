#!/usr/bin/env bash
# Shared Claude/Codex hook: format and lint edited Swift files.
# Claude passes one file on stdin; Codex uses --changed at Stop.
set -uo pipefail

files=()

if [ "${1:-}" = "--changed" ]; then
  root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

  while IFS= read -r -d '' file; do
    [ -f "$root/$file" ] && files+=("$root/$file")
  done < <(
    git -C "$root" diff --name-only --diff-filter=ACMR -z HEAD -- '*.swift' 2>/dev/null
    git -C "$root" ls-files --others --exclude-standard -z -- '*.swift'
  )
else
  input=$(cat)

  if command -v jq >/dev/null 2>&1; then
    file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
  else
    file=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
  fi

  [ -n "${file:-}" ] && [ "${file##*.}" = "swift" ] && [ -f "$file" ] && files+=("$file")
fi

[ "${#files[@]}" -eq 0 ] && exit 0

if command -v swiftformat >/dev/null 2>&1; then
  for file in "${files[@]}"; do
    swiftformat --swift-version 6.0 --language-mode 6 "$file" >/dev/null 2>&1 || true
  done
fi

status=0
if command -v swiftlint >/dev/null 2>&1; then
  for file in "${files[@]}"; do
    swiftlint --fix --quiet "$file" >/dev/null 2>&1 || true
    if out=$(swiftlint lint --quiet "$file" 2>&1); then
      lint_status=0
    else
      lint_status=$?
    fi
    if [ -n "$out" ]; then
      printf 'SwiftLint findings for %s:\n%s\n' "$file" "$out" >&2
    fi
    if [ "$lint_status" -ne 0 ]; then
      status=2
    fi
  done
fi

exit "$status"
