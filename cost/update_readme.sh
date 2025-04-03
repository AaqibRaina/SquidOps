#!/bin/bash

# This script updates the cost tables in the main README.md based on Infracost outputs

# Generate cost breakdowns for all configurations
echo "Generating cost breakdowns..."
infracost breakdown --path ../modules/subsquid --terraform-var-file=basic.tfvars --format=json --out-file=basic.json
infracost breakdown --path ../modules/subsquid --terraform-var-file=balanced.tfvars --format=json --out-file=balanced.json
infracost breakdown --path ../modules/subsquid --terraform-var-file=aggressive.tfvars --format=json --out-file=aggressive.json

infracost breakdown --path ../modules/subsquid --terraform-var-file=high_traffic_basic.tfvars --format=json --out-file=high_traffic_basic.json
infracost breakdown --path ../modules/subsquid --terraform-var-file=high_traffic_balanced.tfvars --format=json --out-file=high_traffic_balanced.json
infracost breakdown --path ../modules/subsquid --terraform-var-file=high_traffic_aggressive.tfvars --format=json --out-file=high_traffic_aggressive.json

# Extract total monthly costs
BASIC_COST=$(jq -r '.totalMonthlyCost' basic.json)
BALANCED_COST=$(jq -r '.totalMonthlyCost' balanced.json)
AGGRESSIVE_COST=$(jq -r '.totalMonthlyCost' aggressive.json)

HT_BASIC_COST=$(jq -r '.totalMonthlyCost' high_traffic_basic.json)
HT_BALANCED_COST=$(jq -r '.totalMonthlyCost' high_traffic_balanced.json)
HT_AGGRESSIVE_COST=$(jq -r '.totalMonthlyCost' high_traffic_aggressive.json)

# Update the README.md with the new costs
echo "Updating README.md with new cost estimates..."

# Create a temporary file
TMP_FILE=$(mktemp)

# Update the 500K-1M requests/month table
cat ../README.md | sed -E "s/\| \*\*Total\*\* \| \*\*\\\$[0-9]+-[0-9]+\*\* \| \*\*\\\$[0-9]+-[0-9]+\*\* \| \*\*\\\$[0-9]+-[0-9]+\*\* \|/| **Total** | **\$$BASIC_COST** | **\$$BALANCED_COST** | **\$$AGGRESSIVE_COST** |/" > $TMP_FILE

# Update the 5M-10M requests/month table
cat $TMP_FILE | sed -E "s/\| \*\*Total\*\* \| \*\*\\\$[0-9]+-[0-9]+\*\* \| \*\*\\\$[0-9]+-[0-9]+\*\* \| \*\*\\\$[0-9]+-[0-9]+\*\* \|.*5M-10M.*/| **Total** | **\$$HT_BASIC_COST** | **\$$HT_BALANCED_COST** | **\$$HT_AGGRESSIVE_COST** | <!-- 5M-10M -->/" > ../README.md

# Clean up
rm $TMP_FILE
echo "README.md updated successfully!"

# Generate an HTML report for easy sharing
echo "Generating HTML cost report..."
infracost breakdown --path ../modules/subsquid --terraform-var-file=balanced.tfvars --format=html --out-file=cost-report.html
echo "HTML report generated: cost-report.html" 