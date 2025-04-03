# Cost Analysis for Subsquid Infrastructure

This directory contains configuration files and scripts for analyzing the cost of the Subsquid infrastructure using Infracost.

## Prerequisites

1. Install Infracost:
   ```bash
   # For macOS
   brew install infracost
   
   # For Linux
   curl -fsSL https://raw.githubusercontent.com/infracost/infracost.sh | sh
   ```

2. Authenticate with Infracost:
   ```bash
   infracost auth login
   ```

## Configuration Files

This directory contains three configuration files for different cost optimization levels:

- `basic.tfvars`: Basic configuration with minimal cost optimizations
- `balanced.tfvars`: Balanced configuration with moderate cost optimizations
- `aggressive.tfvars`: Aggressive configuration with maximum cost optimizations

## Running Cost Analysis

### Generate Cost Breakdown

```bash
# For basic configuration
infracost breakdown --path ../modules/subsquid --terraform-var-file=basic.tfvars --format=table

# For balanced configuration
infracost breakdown --path ../modules/subsquid --terraform-var-file=balanced.tfvars --format=table

# For aggressive configuration
infracost breakdown --path ../modules/subsquid --terraform-var-file=aggressive.tfvars --format=table
```

### Compare Configurations

```bash
# Compare basic vs balanced
infracost diff --path ../modules/subsquid --terraform-var-file=basic.tfvars --compare-to ../modules/subsquid --terraform-var-file=balanced.tfvars

# Compare balanced vs aggressive
infracost diff --path ../modules/subsquid --terraform-var-file=balanced.tfvars --compare-to ../modules/subsquid --terraform-var-file=aggressive.tfvars
```

### Generate HTML Report

```bash
infracost breakdown --path ../modules/subsquid --terraform-var-file=balanced.tfvars --format=html --out-file=cost-report.html
```

## Updating the README

After running the cost analysis, you can update the main README.md with the latest cost estimates:

```bash
./update_readme.sh
```

This script extracts the cost information from Infracost outputs and updates the cost tables in the main README.md file. 