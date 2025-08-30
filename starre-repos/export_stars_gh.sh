#!/usr/bin/env bash
# Export GitHub starred repos for user o9-9 using gh CLI (recommended)
# Requirements: gh (GitHub CLI) v2+, jq
# Usage: ./export_stars_gh.sh
set -euo pipefail

OUT_JSON="stars.json"

echo "Fetching starred repos for user: o9-9 (using gh)..."
# Ensure user is authenticated: gh auth status
# Use --paginate to fetch all pages
gh api --paginate "/users/o9-9/starred" -H "Accept: application/vnd.github.mercy-preview+json, application/vnd.github+json" > "$OUT_JSON"
echo "Saved GitHub response to $OUT_JSON"

echo "Also writing a compact CSV (stars.csv) with key fields..."
jq -r '.[] | [
  .full_name,
  .html_url,
  (.language // ""),
  ((.topics // []) | join(";")),
  (.stargazers_count // 0),
  (.description // ""| gsub("\n"; " ")),
  (.archived // false),
  (.created_at // ""),
  (.updated_at // ""),
  (.pushed_at // "")
] | @csv' "$OUT_JSON" > stars.csv

echo "Done. Files: $OUT_JSON, stars.csv"
echo "Next: run ./group_stars.py to auto-group and generate star_groups.md"