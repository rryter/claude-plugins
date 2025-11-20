# Custom Commands

This directory contains custom slash commands for Claude Code.

## Available Commands

### `/team-stats` - Comprehensive Team Statistics Report

Generates a detailed analysis of team contributor statistics comparing two years.

**What it does:**
1. Finds top 10 contributors by PR count
2. Identifies all git identities for each contributor
3. Gathers PR metrics (counts, monthly breakdowns)
4. Gathers git commit metrics (counts, monthly breakdowns)
5. Generates comprehensive report with:
   - Performance comparisons
   - Productivity metrics
   - Monthly activity patterns
   - Strategic insights
   - Recommendations

**Usage:**
```bash
/team-stats
```

The command will:
- Automatically find top contributors for 2025
- Use Claude to identify all possible git identities
- Run scripts to gather metrics
- Generate a comprehensive markdown report

**Requirements:**
- `gh` CLI (GitHub CLI) installed and authenticated
- Git repository with commit history
- Bash shell

**Output:**
A comprehensive markdown report including:
- Executive summary
- Individual performance tables
- Team rankings
- Productivity metrics (commits/PR, PRs/month, efficiency scores)
- Monthly activity breakdowns
- Strategic insights and recommendations

**Example:**
```
/team-stats
```

This will generate a full report comparing 2024 vs 2025 for the top 10 contributors.

## Scripts

The command uses these helper scripts in `.claude/scripts/`:

### `find-top-contributors.sh`
Finds top N contributors by PR count for a given year.

**Usage:**
```bash
bash .claude/scripts/find-top-contributors.sh [year] [limit]
```

**Example:**
```bash
bash .claude/scripts/find-top-contributors.sh 2025 10
```

### `gather-contributor-metrics.sh`
Gathers PR metrics for specified contributors.

**Usage:**
```bash
bash .claude/scripts/gather-contributor-metrics.sh "user1,user2,user3" [year1] [year2]
```

**Example:**
```bash
bash .claude/scripts/gather-contributor-metrics.sh "rryter,rfe-css,tthttl" 2024 2025
```

### `gather-git-metrics.sh`
Gathers git commit metrics based on identity patterns.

**Usage:**
```bash
bash .claude/scripts/gather-git-metrics.sh <identities_file> [year1] [year2]
```

**Example:**
```bash
# First create identities file
cat > /tmp/identities.txt << EOF
rryter|reto|ryter|reto.ryter@css.ch|reto@twy.gmbh
rfe-css|raphael|felber|p17875|raphael.felber@css.ch
EOF

# Then run the script
bash .claude/scripts/gather-git-metrics.sh /tmp/identities.txt 2024 2025
```

## Customization

You can modify the scripts to:
- Change the default years being compared
- Adjust the number of top contributors
- Filter out certain contributors
- Add additional metrics
- Customize the report format

## Troubleshooting

**"gh: command not found"**
- Install GitHub CLI: https://cli.github.com/

**"Permission denied"**
- Make scripts executable: `chmod +x .claude/scripts/*.sh`

**Empty or incomplete data**
- Ensure you're authenticated with `gh auth login`
- Check that the repository has the necessary history
- Verify date ranges are correct
