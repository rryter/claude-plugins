#!/bin/bash

# Find top N contributors by PR count
# Usage: ./find-top-contributors.sh [year] [limit]
# Example: ./find-top-contributors.sh 2025 10

YEAR=${1:-2025}
LIMIT=${2:-10}

echo "Finding top $LIMIT contributors by PRs for year $YEAR..."
echo ""

# Get all PRs for the year and count by author
gh pr list \
  --state all \
  --limit 1000 \
  --search "created:${YEAR}-01-01..${YEAR}-12-31" \
  --json author \
  | jq -r '.[].author.login' \
  | grep -v "bot\|renovate\|dependabot" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -n "$LIMIT" \
  | awk '{print $2 ":" $1}'

echo ""
echo "Format: github_username:pr_count"
