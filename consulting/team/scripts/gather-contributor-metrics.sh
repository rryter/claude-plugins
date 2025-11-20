#!/bin/bash

# Gather comprehensive metrics for a list of contributors
# Usage: ./gather-contributor-metrics.sh "user1,user2,user3" [year1] [year2]
# Example: ./gather-contributor-metrics.sh "rryter,rfe-css,tthttl" 2024 2025

CONTRIBUTORS=$1
YEAR1=${2:-2024}
YEAR2=${3:-2025}

if [ -z "$CONTRIBUTORS" ]; then
  echo "Error: No contributors specified"
  echo "Usage: $0 \"user1,user2,user3\" [year1] [year2]"
  exit 1
fi

echo "=== CONTRIBUTOR METRICS REPORT ==="
echo "Years: $YEAR1 vs $YEAR2"
echo "Contributors: $CONTRIBUTORS"
echo ""

# Convert comma-separated list to array
IFS=',' read -ra USERS <<< "$CONTRIBUTORS"

# Output file for results
OUTPUT_FILE="/tmp/contributor-metrics-$(date +%s).json"
echo "{" > "$OUTPUT_FILE"
echo "  \"metadata\": {" >> "$OUTPUT_FILE"
echo "    \"year1\": $YEAR1," >> "$OUTPUT_FILE"
echo "    \"year2\": $YEAR2," >> "$OUTPUT_FILE"
echo "    \"generated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"
echo "  \"contributors\": [" >> "$OUTPUT_FILE"

FIRST=true

for github_user in "${USERS[@]}"; do
  if [ "$FIRST" = false ]; then
    echo "," >> "$OUTPUT_FILE"
  fi
  FIRST=false

  echo "Processing: $github_user"

  # Get PR counts
  PR_COUNT_Y1=$(gh pr list --state all --author "$github_user" --search "created:${YEAR1}-01-01..${YEAR1}-12-31" --limit 1000 --json number | jq '. | length')
  PR_COUNT_Y2=$(gh pr list --state all --author "$github_user" --search "created:${YEAR2}-01-01..${YEAR2}-12-31" --limit 1000 --json number | jq '. | length')

  # Get monthly PR breakdown for both years
  PR_MONTHLY_Y1=$(gh pr list --state all --author "$github_user" --search "created:${YEAR1}-01-01..${YEAR1}-12-31" --limit 1000 --json createdAt | jq -r '.[].createdAt[:7]' | sort | uniq -c | awk '{print "      {\"month\": \"" $2 "\", \"count\": " $1 "}"}' | paste -sd ',' -)
  PR_MONTHLY_Y2=$(gh pr list --state all --author "$github_user" --search "created:${YEAR2}-01-01..${YEAR2}-12-31" --limit 1000 --json createdAt | jq -r '.[].createdAt[:7]' | sort | uniq -c | awk '{print "      {\"month\": \"" $2 "\", \"count\": " $1 "}"}' | paste -sd ',' -)

  # Get user's real name from GitHub
  USER_NAME=$(gh pr list --state all --author "$github_user" --limit 1 --json author | jq -r '.[0].author.name // "Unknown"')

  echo "    {" >> "$OUTPUT_FILE"
  echo "      \"github_username\": \"$github_user\"," >> "$OUTPUT_FILE"
  echo "      \"name\": \"$USER_NAME\"," >> "$OUTPUT_FILE"
  echo "      \"year1\": {" >> "$OUTPUT_FILE"
  echo "        \"year\": $YEAR1," >> "$OUTPUT_FILE"
  echo "        \"prs\": $PR_COUNT_Y1," >> "$OUTPUT_FILE"
  echo "        \"prs_by_month\": [" >> "$OUTPUT_FILE"
  echo "$PR_MONTHLY_Y1" >> "$OUTPUT_FILE"
  echo "        ]" >> "$OUTPUT_FILE"
  echo "      }," >> "$OUTPUT_FILE"
  echo "      \"year2\": {" >> "$OUTPUT_FILE"
  echo "        \"year\": $YEAR2," >> "$OUTPUT_FILE"
  echo "        \"prs\": $PR_COUNT_Y2," >> "$OUTPUT_FILE"
  echo "        \"prs_by_month\": [" >> "$OUTPUT_FILE"
  echo "$PR_MONTHLY_Y2" >> "$OUTPUT_FILE"
  echo "        ]" >> "$OUTPUT_FILE"
  echo "      }" >> "$OUTPUT_FILE"
  echo -n "    }" >> "$OUTPUT_FILE"
done

echo "" >> "$OUTPUT_FILE"
echo "  ]" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo ""
echo "Metrics saved to: $OUTPUT_FILE"
cat "$OUTPUT_FILE"
