---
name: cons:team-stats
description: Generate condensed team contributor statistics report comparing two years
---

You are tasked with generating a concise, actionable team contributor statistics report.

## Step 1: Find Top Contributors

Run the script to find the top 10 contributors by PR count for the current year:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-top-contributors.sh 2025 10
```

Parse the output which will be in format: `github_username:pr_count`

Store the list of GitHub usernames.

## Step 2: Identify All Git Identities

For each GitHub username from Step 1, you need to identify ALL possible git identities (email addresses, name variations, employee IDs) they might have used in commits.

For each contributor:

1. First, get their name from a sample PR:

   ```bash
   gh pr list --state all --author "USERNAME" --limit 1 --json author
   ```

2. Then search for all possible identities in git history using variations of:
   - Their GitHub username
   - Their real name (from PR)
   - Common email patterns (firstname.lastname@css.ch, etc.)
   - Employee ID patterns (p##### format)

3. Use commands like:
   ```bash
   git log --all --format="%an <%ae>" | grep -iE "(name_pattern|email_pattern)" | sort -u
   ```

Create a temporary file `/tmp/contributor-identities.txt` with one line per contributor in format:

```
github_user|name_pattern|email_pattern|employee_id_pattern
```

Example:

```
rryter|reto|ryter|reto.ryter@css.ch|reto@twy.gmbh
rfe-css|raphael|felber|p17875|raphael.felber@css.ch
```

**IMPORTANT:** Be thorough in finding all identities. Check:

- Variations in name format (FirstName LastName, LastName FirstName, p#####)
- Multiple email addresses (work, personal, GitHub noreply)
- Case variations

## Step 3: Gather PR Metrics

Run the PR metrics script with the GitHub usernames (comma-separated):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/gather-contributor-metrics.sh "user1,user2,user3" 2024 2025
```

This will output JSON with PR counts and **monthly breakdowns for both years** (2024 and 2025). Save the output location.

## Step 4: Gather Git Commit Metrics

Run the git metrics script with the identities file:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/gather-git-metrics.sh /tmp/contributor-identities.txt 2024 2025
```

This will output JSON with commit counts and **monthly breakdowns for both years** (2024 and 2025).

**Important:** Git metrics **exclude merge commits** (using `--no-merges` flag) to focus on actual code contributions rather than integration work. Save the output location.

## Step 5: Merge and Analyze Data

Read both JSON outputs and merge the data by matching contributors. You should now have for each contributor:

- GitHub username
- Real name
- All git identities
- PR counts (2024 and 2025) with monthly breakdowns for both years
- Commit counts (2024 and 2025, excluding merges) with monthly breakdowns for both years
- Complete monthly trends showing all 12 months (missing months filled with 0)

## Step 6: Generate Condensed Report

Generate a concise, actionable report and save it to `/tmp/team-stats-report.md` following this structure:

### Executive Summary

- Overall team performance (total commits, total PRs, year-over-year changes)
- Team composition changes (new joiners, departures)
- Top 3-5 key highlights and trends
- Seasonal trends (quarterly breakdown)

### Performance Overview Table

Single comprehensive table combining all metrics:
| Developer | 2024 Commits | 2024 PRs | 2025 Commits | 2025 PRs | Commit Δ | PR Δ | Commits/PR 2024 | Commits/PR 2025 | Trend |

Include trend indicators: 🚀 (explosive growth), 📈 (growth), 📉 (decline), ⚠️ (concern), ✅ (stable)

### Key Contributor Insights

**IMPORTANT:** Provide insights for **ALL contributors** found in the data (typically 10+ people). Do not skip anyone.

For each contributor, provide 2-4 concise bullet points:

- Most significant pattern or change
- Peak/low activity periods (if notable)
- Year-over-year trend (growth, decline, stable)
- Concerns or highlights (if applicable)

**Format per contributor:**

```
**name (role/id):** Status emoji
- Key insight 1
- Key insight 2
- Key insight 3 (if notable)
- Concern/highlight (if applicable)
```

Sort contributors by their total impact (commits + PRs) in descending order.

### Critical Issues & Immediate Actions

Bullet-point format only:

**High Priority (Next 30 days):**

- Issue + Action + Owner

**Medium Priority (Next 90 days):**

- Issue + Action + Owner

**Strategic Concerns:**

- Concentration risks
- Capacity gaps
- Retention risks

### Recommendations

Keep current structure but use concise bullets:

- Immediate actions (next 30 days)
- Process improvements (next 90 days)
- Long-term strategic (6-12 months)

### Data Notes

Single paragraph covering:

- Analysis period, data sources, caveats
- Note: 2025 is partial year (through current date)
- **Commit counts exclude merge commits** (--no-merges flag) to focus on actual code contributions
- Monthly breakdowns include all 12 months (missing months show as 0)
- Omit detailed git identity lists

## Output Format

Generate a comprehensive, scannable report in Markdown with:

- **One comprehensive table** with ALL contributors (not multiple ranking tables)
- **Include insights for EVERY contributor** in the Key Contributor Insights section
- **Bullet points only** for insights (no paragraphs)
- **2-4 bullets per contributor** covering key patterns and trends
- Emojis for visual highlights (🚀 📈 📉 ⚠️ ✅)
- Percentages and absolute numbers for changes
- **Completeness:** Every person in the data should have a section
- **Focus:** Actionable insights for each team member

**IMPORTANT:** Do not summarize or skip contributors. The report should be comprehensive enough to understand every team member's contribution and status.

Save the report to `/tmp/team-stats-report.md` using the Write tool.

## Step 7: Generate Interactive Dashboard

Generate the final interactive HTML dashboard that includes the report and charts:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-interactive-charts.sh /tmp/contributor-metrics-*.json /tmp/git-metrics-*.json /tmp/team-stats-graphs /tmp/team-stats-report.md
```

This will create an interactive HTML file at `/tmp/team-stats-graphs/team-stats-charts.html` with:

- **CSS-branded header** with logo and clean design
- **Full markdown report** rendered before the charts (Executive Summary, Performance Table, Insights, etc.)
- **Summary statistics cards** showing year-over-year changes with percentage deltas
- **8 interactive charts** (4 for 2024, 4 for 2025):
  - Line charts showing individual contributor trends
  - Stacked bar charts showing total team output
  - Both commit and PR metrics for each year
- **All 12 months displayed** for 2024 (Jan-Dec), current month for 2025 (missing months show as 0)
- **Interactive features**: hover tooltips, clickable legend to show/hide contributors
- **Professional CSS branding** with clean, minimalist design
- **No dependencies required** - works in any browser, uses Chart.js via CDN

After generating the dashboard, inform the user they can open the HTML file in their browser.

## Example Commands You'll Run

```bash
# Step 1: Find top contributors
bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-top-contributors.sh 2025 10

# Step 2: You'll search for identities manually using git log and grep

# Step 3: Gather PR metrics
bash ${CLAUDE_PLUGIN_ROOT}/scripts/gather-contributor-metrics.sh "rryter,rfe-css,tthttl,zemph,vorderpneu" 2024 2025

# Step 4: Gather git metrics (after creating identities file)
bash ${CLAUDE_PLUGIN_ROOT}/scripts/gather-git-metrics.sh /tmp/contributor-identities.txt 2024 2025

# Step 5: Analyze and merge data

# Step 6: Generate report (save to /tmp/team-stats-report.md)

# Step 7: Generate interactive dashboard with embedded report
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-interactive-charts.sh /tmp/contributor-metrics-*.json /tmp/git-metrics-*.json /tmp/team-stats-graphs /tmp/team-stats-report.md
```

Begin the analysis now. Start with Step 1.
