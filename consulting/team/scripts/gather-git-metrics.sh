#!/bin/bash

# Gather git commit metrics for contributors based on their identities
# Usage: ./gather-git-metrics.sh <identities_file> [year1] [year2]
# identities_file format: each line contains grep patterns for matching commits
# Example line: rryter|reto.ryter@css.ch|reto@twy.gmbh

IDENTITIES_FILE=$1
YEAR1=${2:-2024}
YEAR2=${3:-2025}

if [ -z "$IDENTITIES_FILE" ] || [ ! -f "$IDENTITIES_FILE" ]; then
  echo "Error: Identities file not found: $IDENTITIES_FILE"
  echo "Usage: $0 <identities_file> [year1] [year2]"
  exit 1
fi

echo "=== GIT COMMIT METRICS ==="
echo "Years: $YEAR1 vs $YEAR2"
echo ""

OUTPUT_FILE="/tmp/git-metrics-$(date +%s).json"
echo "{" > "$OUTPUT_FILE"
echo "  \"metadata\": {" >> "$OUTPUT_FILE"
echo "    \"year1\": $YEAR1," >> "$OUTPUT_FILE"
echo "    \"year2\": $YEAR2," >> "$OUTPUT_FILE"
echo "    \"generated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"
echo "  \"contributors\": [" >> "$OUTPUT_FILE"

FIRST=true

while IFS= read -r identity_pattern; do
  if [ -z "$identity_pattern" ] || [[ "$identity_pattern" == \#* ]]; then
    continue
  fi

  if [ "$FIRST" = false ]; then
    echo "," >> "$OUTPUT_FILE"
  fi
  FIRST=false

  # Extract name (first part before |)
  NAME=$(echo "$identity_pattern" | cut -d'|' -f1)

  echo "Processing git commits for: $NAME (pattern: $identity_pattern)"

  # Year 1 commits (excluding merges)
  COMMITS_Y1=$(git log --all --no-merges --since="${YEAR1}-01-01" --until="${YEAR1}-12-31" --format="%an <%ae>" | grep -iE "$identity_pattern" | wc -l | tr -d ' ')

  # Year 2 commits (excluding merges)
  COMMITS_Y2=$(git log --all --no-merges --since="${YEAR2}-01-01" --format="%an <%ae>" | grep -iE "$identity_pattern" | wc -l | tr -d ' ')

  # Monthly breakdown for both years (excluding merges)
  MONTHLY_Y1=$(git log --all --no-merges --since="${YEAR1}-01-01" --until="${YEAR1}-12-31" --format="%ad %an <%ae>" --date=format:"%Y-%m" | grep -iE "$identity_pattern" | awk '{print $1}' | sort | uniq -c | awk '{print "      {\"month\": \"" $2 "\", \"commits\": " $1 "}"}' | paste -sd ',' -)
  MONTHLY_Y2=$(git log --all --no-merges --since="${YEAR2}-01-01" --format="%ad %an <%ae>" --date=format:"%Y-%m" | grep -iE "$identity_pattern" | awk '{print $1}' | sort | uniq -c | awk '{print "      {\"month\": \"" $2 "\", \"commits\": " $1 "}"}' | paste -sd ',' -)

  # Get all identities found (excluding merges)
  IDENTITIES=$(git log --all --no-merges --format="%an <%ae>" | grep -iE "$identity_pattern" | sort -u | jq -Rs 'split("\n") | map(select(length > 0))')

  echo "    {" >> "$OUTPUT_FILE"
  echo "      \"name\": \"$NAME\"," >> "$OUTPUT_FILE"
  echo "      \"pattern\": \"$identity_pattern\"," >> "$OUTPUT_FILE"
  echo "      \"identities\": $IDENTITIES," >> "$OUTPUT_FILE"
  echo "      \"year1\": {" >> "$OUTPUT_FILE"
  echo "        \"year\": $YEAR1," >> "$OUTPUT_FILE"
  echo "        \"commits\": $COMMITS_Y1," >> "$OUTPUT_FILE"
  echo "        \"commits_by_month\": [" >> "$OUTPUT_FILE"
  echo "$MONTHLY_Y1" >> "$OUTPUT_FILE"
  echo "        ]" >> "$OUTPUT_FILE"
  echo "      }," >> "$OUTPUT_FILE"
  echo "      \"year2\": {" >> "$OUTPUT_FILE"
  echo "        \"year\": $YEAR2," >> "$OUTPUT_FILE"
  echo "        \"commits\": $COMMITS_Y2," >> "$OUTPUT_FILE"
  echo "        \"commits_by_month\": [" >> "$OUTPUT_FILE"
  echo "$MONTHLY_Y2" >> "$OUTPUT_FILE"
  echo "        ]" >> "$OUTPUT_FILE"
  echo "      }" >> "$OUTPUT_FILE"
  echo -n "    }" >> "$OUTPUT_FILE"
done < "$IDENTITIES_FILE"

echo "" >> "$OUTPUT_FILE"
echo "  ]" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo ""
echo "Git metrics saved to: $OUTPUT_FILE"
cat "$OUTPUT_FILE"
