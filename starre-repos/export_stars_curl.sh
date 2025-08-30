#!/usr/bin/env bash
# Export GitHub starred repos for user o9-9 using curl (no gh CLI)
# Requirements: curl >=7.58, jq
# Usage:
#   export GITHUB_TOKEN="ghp_..."   # personal token with public_repo (or no scope for public)
#   ./export_stars_curl.sh
set -euo pipefail

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: set GITHUB_TOKEN environment variable (a personal access token)."
  exit 1
fi

USER="o9-9"
OUT_JSON="stars.json"
TMPDIR=$(mktemp -d)
page=1
all=()

echo "Fetching starred repos for user: $USER (curl + pagination)..."

while :; do
  url="https://api.github.com/users/$USER/starred?per_page=100&page=$page"
  echo "Requesting page $page..."
  resp_headers="$TMPDIR/headers_$page"
  resp_body="$TMPDIR/body_$page.json"

  curl -sS -D "$resp_headers" -o "$resp_body" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.mercy-preview+json, application/vnd.github+json" \
    "$url"

  len=$(jq 'length' "$resp_body")
  if [ "$len" -eq 0 ]; then
    break
  fi

  all+=("$resp_body")

  # detect if there's a next link in Link header
  if ! grep -i '^Link:' "$resp_headers" >/dev/null 2>&1; then
    break
  fi

  link=$(grep -i '^Link:' "$resp_headers" | sed 's/Link: //I')
  echo "$link" | grep 'rel="next"' >/dev/null 2>&1 || break
  page=$((page + 1))
done

# combine JSON arrays
jq -s 'add' "${all[@]}" > "$OUT_JSON"
echo "Saved combined results to $OUT_JSON"

echo "Also writing a compact CSV (stars.csv) with key fields..."
jq -r '.[] | [
  .full_name,
  .html_url,
  (.language // ""),
  ((.topics // []) | join(";")),
  (.stargazers_count // 0),
  (.description // "" | gsub("\n"; " ")),
  (.archived // false),
  (.created_at // ""),
  (.updated_at // ""),
  (.pushed_at // "")
] | @csv' "$OUT_JSON" > stars.csv

echo "Done. Files: $OUT_JSON, stars.csv"
rm -rf "$TMPDIR"
echo "Next: run ./group_stars.py to auto-group and generate star_groups.md"