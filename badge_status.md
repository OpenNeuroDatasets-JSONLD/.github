# Dataset Processing Status Badges

This page shows individual status badges for each dataset processed by the CLI workflow.

## About Matrix Job Badges

Each badge represents the status of processing an individual dataset (repository) in the OpenNeuroDatasets-JSONLD organization. The badges are generated from GitHub Actions matrix jobs, where each dataset is processed in parallel.

### Badge Status Meanings

- ![passing](https://img.shields.io/badge/status-passing-brightgreen) - Dataset processed successfully
- ![failing](https://img.shields.io/badge/status-failing-red) - Dataset processing failed
- ![running](https://img.shields.io/badge/status-running-blue) - Dataset processing in progress
- ![cancelled](https://img.shields.io/badge/status-cancelled-yellow) - Dataset processing was cancelled
- ![unknown](https://img.shields.io/badge/status-unknown-lightgrey) - Status unknown or not yet determined

## Current Status

*Badges will be automatically updated here by the badge generation workflow.*

## Usage

### Individual Badge URLs

You can reference individual dataset badges using the following URL pattern:

```
https://img.shields.io/badge/{dataset-name}-{status}-{color}
```

### Matrix Workflow Link

View the full matrix workflow execution: [Run CLI on repo list workflow](../../actions/workflows/run_cli_on_repo_list.yml)

### Embedding in Documentation

To embed these badges in your own documentation:

```markdown
![Dataset Name](https://img.shields.io/badge/ds000001-passing-brightgreen)
```

## Implementation Details

- **Matrix Strategy**: Each dataset is processed as a separate job in the GitHub Actions matrix
- **Parallel Execution**: Datasets are processed simultaneously instead of sequentially
- **Individual Status**: Each matrix job has its own success/failure status
- **Automated Updates**: Badges are regenerated after each workflow completion
- **Artifact Storage**: Processing logs and JSONLD files are stored as separate artifacts per dataset

## Workflow Files

- [`run_cli_on_repo_list.yml`](../.github/workflows/run_cli_on_repo_list.yml) - Main CLI execution with matrix strategy
- [`generate_status_badges.yml`](../.github/workflows/generate_status_badges.yml) - Badge generation workflow

---

*Last updated: This file is automatically updated by the badge generation workflow*