#!/bin/bash

# This script runs a complete cost analysis for all configurations

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

# Path to the subsquid module
MODULE_PATH="../modules/subsquid"

# Get absolute paths for var files
BASIC_VARS="$SCRIPT_DIR/basic.tfvars"
BALANCED_VARS="$SCRIPT_DIR/balanced.tfvars"
AGGRESSIVE_VARS="$SCRIPT_DIR/aggressive.tfvars"
HT_BASIC_VARS="$SCRIPT_DIR/high_traffic_basic.tfvars"
HT_BALANCED_VARS="$SCRIPT_DIR/high_traffic_balanced.tfvars"
HT_AGGRESSIVE_VARS="$SCRIPT_DIR/high_traffic_aggressive.tfvars"

# Generate cost breakdowns for all configurations
echo "=== Generating cost breakdowns ==="
echo ""

echo "Basic configuration (500K-1M requests/month):"
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$BASIC_VARS" --format=table
echo ""

echo "Balanced configuration (500K-1M requests/month):"
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$BALANCED_VARS" --format=table
echo ""

echo "Aggressive configuration (500K-1M requests/month):"
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$AGGRESSIVE_VARS" --format=table
echo ""

echo "Basic configuration (5M-10M requests/month):"
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$HT_BASIC_VARS" --format=table
echo ""

echo "Balanced configuration (5M-10M requests/month):"
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$HT_BALANCED_VARS" --format=table
echo ""

echo "Aggressive configuration (5M-10M requests/month):"
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$HT_AGGRESSIVE_VARS" --format=table
echo ""

# Generate JSON files for comparison
echo "=== Generating JSON files for comparison ==="
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$BASIC_VARS" --format=json --out-file=basic.json
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$BALANCED_VARS" --format=json --out-file=balanced.json
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$AGGRESSIVE_VARS" --format=json --out-file=aggressive.json

# Compare configurations
echo "=== Comparing configurations ==="
echo ""

echo "Basic vs Balanced (500K-1M requests/month):"
infracost diff --path basic.json --compare-to balanced.json
echo ""

echo "Balanced vs Aggressive (500K-1M requests/month):"
infracost diff --path balanced.json --compare-to aggressive.json
echo ""

echo "Basic vs Aggressive (500K-1M requests/month):"
infracost diff --path basic.json --compare-to aggressive.json
echo ""

# Generate HTML report
echo "=== Generating HTML report ==="
infracost breakdown --path "$MODULE_PATH" --terraform-var-file="$BALANCED_VARS" --format=html --out-file=cost-report.html
echo "HTML report generated: cost-report.html"

# Update README
echo "=== Updating README with cost estimates ==="
./update_readme.sh

echo "Cost analysis complete!" 