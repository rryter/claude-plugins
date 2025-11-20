#!/bin/bash
#
# Generate interactive HTML charts for team contributor statistics
# Uses Chart.js for interactive visualizations
#

set -e

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <pr-metrics.json> <git-metrics.json> <output-dir> [report.md]"
    exit 1
fi

PR_JSON="$1"
GIT_JSON="$2"
OUTPUT_DIR="$3"
REPORT_MD="${4:-}"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Extract years from metadata
YEAR1=$(jq -r '.metadata.year1' "$PR_JSON")
YEAR2=$(jq -r '.metadata.year2' "$GIT_JSON")

echo "Generating interactive charts for years: $YEAR1, $YEAR2"

# Generate HTML file
cat > "$OUTPUT_DIR/team-stats-charts.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Team Contributor Statistics</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #F7F9FC;
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        .header {
            background: white;
            padding: 20px 40px;
            margin-bottom: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .logo {
            font-size: 2em;
            font-weight: bold;
            color: #3366CC;
            letter-spacing: 2px;
        }

        h1 {
            color: #1E3A8A;
            text-align: center;
            margin-bottom: 10px;
            font-size: 2.5em;
            font-weight: 600;
        }

        .subtitle {
            text-align: center;
            color: #64748B;
            font-size: 1.1em;
            margin-bottom: 40px;
        }

        .year-section {
            margin-bottom: 50px;
        }

        .year-title {
            color: #1E3A8A;
            font-size: 2em;
            margin-bottom: 20px;
            text-align: center;
            font-weight: 600;
        }

        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(600px, 1fr));
            gap: 30px;
            margin-bottom: 30px;
        }

        .chart-container {
            background: white;
            border-radius: 8px;
            padding: 25px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .chart-container:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.12);
        }

        .chart-title {
            font-size: 1.2em;
            font-weight: 600;
            color: #1E3A8A;
            margin-bottom: 15px;
            text-align: center;
        }

        .chart-wrapper {
            position: relative;
            height: 400px;
        }

        .stats-summary {
            background: white;
            border-radius: 8px;
            padding: 30px;
            margin-bottom: 40px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .stats-summary h2 {
            color: #1E3A8A;
            font-size: 1.5em;
            font-weight: 600;
            margin-bottom: 20px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }

        .stat-card {
            background: #F7F9FC;
            border: 2px solid #E2E8F0;
            color: #1E3A8A;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            transition: all 0.2s ease;
        }

        .stat-card:hover {
            border-color: #3366CC;
            box-shadow: 0 4px 12px rgba(51, 102, 204, 0.1);
        }

        .stat-label {
            font-size: 0.85em;
            color: #64748B;
            margin-bottom: 8px;
            font-weight: 500;
        }

        .stat-value {
            font-size: 2.2em;
            font-weight: 700;
            color: #3366CC;
        }

        .report-section {
            background: white;
            border-radius: 8px;
            padding: 40px;
            margin-bottom: 40px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .report-section h2 {
            color: #1E3A8A;
            font-size: 2em;
            font-weight: 600;
            margin-top: 30px;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #E2E8F0;
        }

        .report-section h2:first-child {
            margin-top: 0;
        }

        .report-section h3 {
            color: #1E3A8A;
            font-size: 1.3em;
            font-weight: 600;
            margin-top: 20px;
            margin-bottom: 10px;
        }

        .report-section p {
            color: #64748B;
            line-height: 1.6;
            margin-bottom: 15px;
        }

        .report-section ul, .report-section ol {
            color: #64748B;
            line-height: 1.8;
            margin-bottom: 15px;
            padding-left: 25px;
        }

        .report-section li {
            margin-bottom: 8px;
        }

        .report-section table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            font-size: 0.95em;
        }

        .report-section table th {
            background: #F7F9FC;
            color: #1E3A8A;
            font-weight: 600;
            padding: 12px;
            text-align: left;
            border-bottom: 2px solid #3366CC;
        }

        .report-section table td {
            padding: 10px 12px;
            border-bottom: 1px solid #E2E8F0;
            color: #64748B;
        }

        .report-section table tr:hover {
            background: #F7F9FC;
        }

        .report-section strong {
            color: #1E3A8A;
            font-weight: 600;
        }

        .report-section code {
            background: #F7F9FC;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            color: #3366CC;
        }

        @media (max-width: 768px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }

            h1 {
                font-size: 1.8em;
            }

            .year-title {
                font-size: 1.5em;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">CSS</div>
        <div style="color: #64748B; font-size: 0.9em;">Team Statistics Dashboard</div>
    </div>

    <div class="container">
        <h1>Team Contributor Statistics</h1>
        <p class="subtitle">Comprehensive analysis of team performance and contributions</p>

        <!-- Report content will be inserted here -->
        <div id="reportContent" class="report-section" style="display:none;"></div>

        <div class="stats-summary">
            <h2>Overview</h2>
            <div class="stats-grid" id="statsGrid"></div>
        </div>

        <div class="year-section">
            <h2 class="year-title">YEAR1_PLACEHOLDER</h2>
            <div class="charts-grid">
                <div class="chart-container">
                    <div class="chart-title">Commits per Month (Line)</div>
                    <div class="chart-wrapper">
                        <canvas id="commitsYear1Line"></canvas>
                    </div>
                </div>
                <div class="chart-container">
                    <div class="chart-title">PRs per Month (Line)</div>
                    <div class="chart-wrapper">
                        <canvas id="prsYear1Line"></canvas>
                    </div>
                </div>
            </div>
            <div class="charts-grid">
                <div class="chart-container">
                    <div class="chart-title">Commits per Month (Stacked)</div>
                    <div class="chart-wrapper">
                        <canvas id="commitsYear1Stacked"></canvas>
                    </div>
                </div>
                <div class="chart-container">
                    <div class="chart-title">PRs per Month (Stacked)</div>
                    <div class="chart-wrapper">
                        <canvas id="prsYear1Stacked"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <div class="year-section">
            <h2 class="year-title">YEAR2_PLACEHOLDER</h2>
            <div class="charts-grid">
                <div class="chart-container">
                    <div class="chart-title">Commits per Month (Line)</div>
                    <div class="chart-wrapper">
                        <canvas id="commitsYear2Line"></canvas>
                    </div>
                </div>
                <div class="chart-container">
                    <div class="chart-title">PRs per Month (Line)</div>
                    <div class="chart-wrapper">
                        <canvas id="prsYear2Line"></canvas>
                    </div>
                </div>
            </div>
            <div class="charts-grid">
                <div class="chart-container">
                    <div class="chart-title">Commits per Month (Stacked)</div>
                    <div class="chart-wrapper">
                        <canvas id="commitsYear2Stacked"></canvas>
                    </div>
                </div>
                <div class="chart-container">
                    <div class="chart-title">PRs per Month (Stacked)</div>
                    <div class="chart-wrapper">
                        <canvas id="prsYear2Stacked"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Data loaded from external pr-data.js and git-data.js files

        // Color palette for contributors (diverse, distinguishable colors)
        const colors = [
            '#3366CC', // CSS blue (primary)
            '#DC2626', // Red
            '#059669', // Green
            '#D97706', // Orange
            '#7C3AED', // Purple
            '#DB2777', // Pink
            '#0891B2', // Cyan
            '#EA580C', // Dark orange
            '#4F46E5', // Indigo
            '#BE185D', // Magenta
            '#0D9488', // Teal
            '#9333EA'  // Violet
        ];

        // Calculate and display summary stats
        function displayStats() {
            const statsGrid = document.getElementById('statsGrid');

            const year1Commits = gitData.contributors.reduce((sum, c) => sum + (c.year1?.commits || 0), 0);
            const year2Commits = gitData.contributors.reduce((sum, c) => sum + (c.year2?.commits || 0), 0);
            const year1PRs = prData.contributors.reduce((sum, c) => sum + (c.year1?.prs || 0), 0);
            const year2PRs = prData.contributors.reduce((sum, c) => sum + (c.year2?.prs || 0), 0);

            const commitChange = year1Commits > 0 ? ((year2Commits - year1Commits) / year1Commits * 100).toFixed(1) : 'N/A';
            const prChange = year1PRs > 0 ? ((year2PRs - year1PRs) / year1PRs * 100).toFixed(1) : 'N/A';

            statsGrid.innerHTML = `
                <div class="stat-card">
                    <div class="stat-label">YEAR1_PLACEHOLDER Commits</div>
                    <div class="stat-value">${year1Commits.toLocaleString()}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">YEAR2_PLACEHOLDER Commits</div>
                    <div class="stat-value">${year2Commits.toLocaleString()}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Commits Change</div>
                    <div class="stat-value">${commitChange}%</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">YEAR1_PLACEHOLDER PRs</div>
                    <div class="stat-value">${year1PRs}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">YEAR2_PLACEHOLDER PRs</div>
                    <div class="stat-value">${year2PRs}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">PRs Change</div>
                    <div class="stat-value">${prChange}%</div>
                </div>
            `;
        }

        // Parse month string to display format
        function parseMonth(monthStr) {
            const date = new Date(monthStr + '-01');
            return date.toLocaleDateString('en-US', { month: 'short' });
        }

        // Generate all months for a year (Jan-Dec or Jan-Current for current year)
        function getAllMonths(year) {
            const months = [];
            const currentYear = new Date().getFullYear();
            const currentMonth = new Date().getMonth(); // 0-11
            const maxMonth = (year === currentYear) ? currentMonth : 11;

            for (let i = 0; i <= maxMonth; i++) {
                const monthStr = `${year}-${String(i + 1).padStart(2, '0')}`;
                months.push(monthStr);
            }
            return months;
        }

        // Fill missing months with 0
        function fillMonthlyData(monthlyData, allMonths, valueKey) {
            const dataMap = {};
            if (monthlyData) {
                monthlyData.forEach(m => {
                    dataMap[m.month] = valueKey === 'commits' ? m.commits : m.count;
                });
            }
            return allMonths.map(month => ({
                month: month,
                value: dataMap[month] || 0
            }));
        }

        // Create line chart
        function createLineChart(canvasId, data, year, metric) {
            const ctx = document.getElementById(canvasId).getContext('2d');
            const allMonths = getAllMonths(year);

            const datasets = data.contributors
                .filter(c => {
                    const yearKey = data.metadata.year1 === year ? 'year1' : 'year2';
                    return c[yearKey];
                })
                .map((contributor, index) => {
                    const yearKey = data.metadata.year1 === year ? 'year1' : 'year2';
                    const monthlyData = metric === 'commits' ?
                        contributor[yearKey].commits_by_month :
                        contributor[yearKey].prs_by_month;

                    const label = contributor.name || contributor.github_username;
                    const filledData = fillMonthlyData(monthlyData, allMonths, metric);
                    const dataPoints = filledData.map(d => ({
                        x: parseMonth(d.month),
                        y: d.value
                    }));

                    return {
                        label: label,
                        data: dataPoints,
                        borderColor: colors[index % colors.length],
                        backgroundColor: colors[index % colors.length] + '20',
                        tension: 0.4,
                        fill: false
                    };
                });

            if (datasets.length === 0) {
                ctx.canvas.parentElement.innerHTML = '<p style="text-align: center; padding: 50px; color: #999;">No data available for this period</p>';
                return;
            }

            new Chart(ctx, {
                type: 'line',
                data: { datasets },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    interaction: {
                        mode: 'index',
                        intersect: false,
                    },
                    plugins: {
                        legend: {
                            position: 'bottom',
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    return context.dataset.label + ': ' + context.parsed.y.toLocaleString();
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                callback: function(value) {
                                    return value.toLocaleString();
                                }
                            }
                        }
                    }
                }
            });
        }

        // Create stacked bar chart
        function createStackedChart(canvasId, data, year, metric) {
            const ctx = document.getElementById(canvasId).getContext('2d');
            const yearKey = data.metadata.year1 === year ? 'year1' : 'year2';
            const allMonths = getAllMonths(year);
            const labels = allMonths.map(parseMonth);

            const datasets = data.contributors
                .filter(c => c[yearKey])
                .map((contributor, index) => {
                    const monthlyData = metric === 'commits' ?
                        contributor[yearKey].commits_by_month :
                        contributor[yearKey].prs_by_month;

                    const filledData = fillMonthlyData(monthlyData, allMonths, metric);
                    const dataPoints = filledData.map(d => d.value);
                    const label = contributor.name || contributor.github_username;

                    return {
                        label: label,
                        data: dataPoints,
                        backgroundColor: colors[index % colors.length],
                    };
                });

            if (datasets.length === 0) {
                ctx.canvas.parentElement.innerHTML = '<p style="text-align: center; padding: 50px; color: #999;">No data available for this period</p>';
                return;
            }

            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: datasets
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    interaction: {
                        mode: 'index',
                        intersect: false,
                    },
                    plugins: {
                        legend: {
                            position: 'bottom',
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    return context.dataset.label + ': ' + context.parsed.y.toLocaleString();
                                }
                            }
                        }
                    },
                    scales: {
                        x: {
                            stacked: true,
                        },
                        y: {
                            stacked: true,
                            beginAtZero: true,
                            ticks: {
                                callback: function(value) {
                                    return value.toLocaleString();
                                }
                            }
                        }
                    }
                }
            });
        }

        // Embedded report markdown (will be replaced by script)
        const reportMarkdown = `__REPORT_CONTENT_PLACEHOLDER__`;

        // Load and render markdown report if available
        function loadReport() {
            if (reportMarkdown && reportMarkdown !== '__REPORT_CONTENT_PLACEHOLDER__') {
                const reportDiv = document.getElementById('reportContent');
                reportDiv.innerHTML = marked.parse(reportMarkdown);
                reportDiv.style.display = 'block';
            }
        }

        // Initialize all charts
        displayStats();
        loadReport();

        // Year 1 charts
        createLineChart('commitsYear1Line', gitData, gitData.metadata.year1, 'commits');
        createLineChart('prsYear1Line', prData, prData.metadata.year1, 'prs');
        createStackedChart('commitsYear1Stacked', gitData, gitData.metadata.year1, 'commits');
        createStackedChart('prsYear1Stacked', prData, prData.metadata.year1, 'prs');

        // Year 2 charts
        createLineChart('commitsYear2Line', gitData, gitData.metadata.year2, 'commits');
        createLineChart('prsYear2Line', prData, prData.metadata.year2, 'prs');
        createStackedChart('commitsYear2Stacked', gitData, gitData.metadata.year2, 'commits');
        createStackedChart('prsYear2Stacked', prData, prData.metadata.year2, 'prs');
    </script>
</body>
</html>
EOF

# Create separate JS data files
cat > "$OUTPUT_DIR/pr-data.js" << EOJS
const prData = $(cat "$PR_JSON");
EOJS

cat > "$OUTPUT_DIR/git-data.js" << EOJS
const gitData = $(cat "$GIT_JSON");
EOJS

# Replace year placeholders in the HTML
sed -i '' "s/YEAR1_PLACEHOLDER/$YEAR1/g" "$OUTPUT_DIR/team-stats-charts.html"
sed -i '' "s/YEAR2_PLACEHOLDER/$YEAR2/g" "$OUTPUT_DIR/team-stats-charts.html"

# Add script tags to load the data files before the closing </head> tag
sed -i '' 's|</head>|    <script src="pr-data.js"></script>\n    <script src="git-data.js"></script>\n</head>|' "$OUTPUT_DIR/team-stats-charts.html"

# Embed report markdown if provided
if [ -n "$REPORT_MD" ] && [ -f "$REPORT_MD" ]; then
    # Escape special characters for JavaScript template literal and save to temp file
    cat "$REPORT_MD" | perl -pe 's/\\/\\\\/g; s/`/\\`/g; s/\$/\\\$/g' > /tmp/report_escaped.txt

    # Use perl with slurp mode to read entire escaped content and replace only first occurrence of placeholder
    perl -i -0pe 'BEGIN{open F,"/tmp/report_escaped.txt"; $r=<F>; close F} s/__REPORT_CONTENT_PLACEHOLDER__/$r/' "$OUTPUT_DIR/team-stats-charts.html"

    rm /tmp/report_escaped.txt
    echo "✓ Report embedded in HTML"
fi

echo ""
echo "✓ Interactive dashboard generated successfully!"
if [ -n "$REPORT_MD" ] && [ -f "$REPORT_MD" ]; then
    echo "  - Report: Included"
else
    echo "  - Report: Not provided (showing charts only)"
fi
echo "📊 Open in browser: file://$OUTPUT_DIR/team-stats-charts.html"
echo ""
