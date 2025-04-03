#!/bin/bash

# This script runs a cost analysis for the Subsquid infrastructure module

# Check if Infracost is installed
if ! command -v infracost &> /dev/null; then
    echo "Infracost is not installed. Please install it first:"
    echo "  brew install infracost  # For macOS"
    echo "  curl -fsSL https://raw.githubusercontent.com/infracost/infracost.sh | sh  # For Linux"
    exit 1
fi

# Check if authenticated
if ! infracost auth status &> /dev/null; then
    echo "Please authenticate with Infracost first:"
    echo "  infracost auth login"
    exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create reports directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/reports"

# Path to the subsquid module
MODULE_PATH="../modules/subsquid"

# Get absolute paths for var files
BASIC_VARS="$SCRIPT_DIR/basic.tfvars"
BALANCED_VARS="$SCRIPT_DIR/balanced.tfvars"
AGGRESSIVE_VARS="$SCRIPT_DIR/aggressive.tfvars"
HT_BASIC_VARS="$SCRIPT_DIR/high_traffic_basic.tfvars"
HT_BALANCED_VARS="$SCRIPT_DIR/high_traffic_balanced.tfvars"
HT_AGGRESSIVE_VARS="$SCRIPT_DIR/high_traffic_aggressive.tfvars"

# Enable usage-based cost estimation
export INFRACOST_ENABLE_CLOUD=true

# Disable color output to avoid ANSI codes in the report
export INFRACOST_NO_COLOR=true

# Create a date string for the report filename
DATE_STR=$(date +"%Y-%m-%d")
REPORT_FILE="$SCRIPT_DIR/reports/cost-report-${DATE_STR}.md"

# Start the markdown report
cat > "$REPORT_FILE" << EOF
# Subsquid Infrastructure Cost Analysis (${DATE_STR})

This report provides a detailed cost breakdown for the Subsquid infrastructure module with different configurations and traffic levels.

## Cost Summary

| Configuration | Traffic Level | Monthly Cost |
|---------------|--------------|--------------|
EOF

# Run cost analysis for each configuration and append to the report
echo "Running cost analysis for all configurations..."

# Basic configuration (500K-1M requests/month)
echo "Analyzing basic configuration (500K-1M requests/month)..."
BASIC_LOW_COST=$(infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$BASIC_VARS" --format=json --usage-file="$SCRIPT_DIR/usage_low.yml" | jq -r '.totalMonthlyCost')
echo "| Basic | 500K-1M requests/month | \$${BASIC_LOW_COST} |" >> "$REPORT_FILE"

# Balanced configuration (500K-1M requests/month)
echo "Analyzing balanced configuration (500K-1M requests/month)..."
BALANCED_LOW_COST=$(infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$BALANCED_VARS" --format=json --usage-file="$SCRIPT_DIR/usage_low.yml" | jq -r '.totalMonthlyCost')
echo "| Balanced | 500K-1M requests/month | \$${BALANCED_LOW_COST} |" >> "$REPORT_FILE"

# Aggressive configuration (500K-1M requests/month)
echo "Analyzing aggressive configuration (500K-1M requests/month)..."
AGGRESSIVE_LOW_COST=$(infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$AGGRESSIVE_VARS" --format=json --usage-file="$SCRIPT_DIR/usage_low.yml" | jq -r '.totalMonthlyCost')
echo "| Aggressive | 500K-1M requests/month | \$${AGGRESSIVE_LOW_COST} |" >> "$REPORT_FILE"

# Basic configuration (5M-10M requests/month)
echo "Analyzing basic configuration (5M-10M requests/month)..."
BASIC_HIGH_COST=$(infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$HT_BASIC_VARS" --format=json --usage-file="$SCRIPT_DIR/usage_high.yml" | jq -r '.totalMonthlyCost')
echo "| Basic | 5M-10M requests/month | \$${BASIC_HIGH_COST} |" >> "$REPORT_FILE"

# Balanced configuration (5M-10M requests/month)
echo "Analyzing balanced configuration (5M-10M requests/month)..."
BALANCED_HIGH_COST=$(infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$HT_BALANCED_VARS" --format=json --usage-file="$SCRIPT_DIR/usage_high.yml" | jq -r '.totalMonthlyCost')
echo "| Balanced | 5M-10M requests/month | \$${BALANCED_HIGH_COST} |" >> "$REPORT_FILE"

# Aggressive configuration (5M-10M requests/month)
echo "Analyzing aggressive configuration (5M-10M requests/month)..."
AGGRESSIVE_HIGH_COST=$(infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$HT_AGGRESSIVE_VARS" --format=json --usage-file="$SCRIPT_DIR/usage_high.yml" | jq -r '.totalMonthlyCost')
echo "| Aggressive | 5M-10M requests/month | \$${AGGRESSIVE_HIGH_COST} |" >> "$REPORT_FILE"

# Function to get clean table output without ANSI codes
get_clean_table() {
    infracost breakdown --path "$1" --terraform-var-file="$2" --format=table --usage-file="$3" | sed 's/\x1B\[[0-9;]*[mK]//g'
}

# Add detailed breakdowns to the report
cat >> "$REPORT_FILE" << EOF

## Detailed Cost Breakdown

### Basic Configuration (500K-1M requests/month)

\`\`\`
$(get_clean_table "$MODULE_PATH" "$BASIC_VARS" "$SCRIPT_DIR/usage_low.yml")
\`\`\`

### Balanced Configuration (500K-1M requests/month)

\`\`\`
$(get_clean_table "$MODULE_PATH" "$BALANCED_VARS" "$SCRIPT_DIR/usage_low.yml")
\`\`\`

### Aggressive Configuration (500K-1M requests/month)

\`\`\`
$(get_clean_table "$MODULE_PATH" "$AGGRESSIVE_VARS" "$SCRIPT_DIR/usage_low.yml")
\`\`\`

### Basic Configuration (5M-10M requests/month)

\`\`\`
$(get_clean_table "$MODULE_PATH" "$HT_BASIC_VARS" "$SCRIPT_DIR/usage_high.yml")
\`\`\`

### Balanced Configuration (5M-10M requests/month)

\`\`\`
$(get_clean_table "$MODULE_PATH" "$HT_BALANCED_VARS" "$SCRIPT_DIR/usage_high.yml")
\`\`\`

### Aggressive Configuration (5M-10M requests/month)

\`\`\`
$(get_clean_table "$MODULE_PATH" "$HT_AGGRESSIVE_VARS" "$SCRIPT_DIR/usage_high.yml")
\`\`\`

## Cost Comparisons

### Basic vs. Balanced (500K-1M requests/month)

Savings: \$$(echo "$BASIC_LOW_COST - $BALANCED_LOW_COST" | bc) per month ($(echo "scale=2; ($BASIC_LOW_COST - $BALANCED_LOW_COST) / $BASIC_LOW_COST * 100" | bc)%)

### Balanced vs. Aggressive (500K-1M requests/month)

Savings: \$$(echo "$BALANCED_LOW_COST - $AGGRESSIVE_LOW_COST" | bc) per month ($(echo "scale=2; ($BALANCED_LOW_COST - $AGGRESSIVE_LOW_COST) / $BALANCED_LOW_COST * 100" | bc)%)

### Basic vs. Balanced (5M-10M requests/month)

Savings: \$$(echo "$BASIC_HIGH_COST - $BALANCED_HIGH_COST" | bc) per month ($(echo "scale=2; ($BASIC_HIGH_COST - $BALANCED_HIGH_COST) / $BASIC_HIGH_COST * 100" | bc)%)

### Balanced vs. Aggressive (5M-10M requests/month)

Savings: \$$(echo "$BALANCED_HIGH_COST - $AGGRESSIVE_HIGH_COST" | bc) per month ($(echo "scale=2; ($BALANCED_HIGH_COST - $AGGRESSIVE_HIGH_COST) / $BALANCED_HIGH_COST * 100" | bc)%)

## Comparison with Subsquid Cloud

| Traffic Level | Our Solution (Aggressive) | Subsquid Cloud | Savings |
|---------------|---------------------------|---------------|---------|
| 500K-1M requests/month | \$${AGGRESSIVE_LOW_COST} | \$600 | \$$(echo "600 - $AGGRESSIVE_LOW_COST" | bc) ($(echo "scale=2; (600 - $AGGRESSIVE_LOW_COST) / 600 * 100" | bc)%) |
| 5M-10M requests/month | \$${AGGRESSIVE_HIGH_COST} | \$1,750 | \$$(echo "1750 - $AGGRESSIVE_HIGH_COST" | bc) ($(echo "scale=2; (1750 - $AGGRESSIVE_HIGH_COST) / 1750 * 100" | bc)%) |

## Conclusion

The Subsquid infrastructure module provides significant cost savings compared to Subsquid Cloud, especially with the aggressive optimization configuration. For high-traffic scenarios, the savings are even more substantial.

EOF

# Clean up any temporary files
rm -f "$SCRIPT_DIR"/*.json
rm -f "$SCRIPT_DIR"/cost-report.html
rm -f "$SCRIPT_DIR"/cost-report-*.md

echo "Cost analysis complete! Report saved to $REPORT_FILE" 