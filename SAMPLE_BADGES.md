# Sample Dataset Status Badges

This shows how the individual matrix job badges will look when generated:

## Passing Datasets
![ds000001](https://img.shields.io/badge/ds000001-passing-brightgreen) ![ds000005](https://img.shields.io/badge/ds000005-passing-brightgreen) ![ds000017](https://img.shields.io/badge/ds000017-passing-brightgreen) 

## Failed Datasets  
![ds000002](https://img.shields.io/badge/ds000002-failing-red) ![ds000008](https://img.shields.io/badge/ds000008-failing-red)

## Running Datasets
![ds000003](https://img.shields.io/badge/ds000003-running-blue) ![ds000012](https://img.shields.io/badge/ds000012-running-blue)

## Summary Badge
![Total Processed](https://img.shields.io/badge/total_processed-7-blue) ![Success Rate](https://img.shields.io/badge/success_rate-43%25-orange)

## Usage in Documentation

You can embed individual badges in any documentation:

```markdown
# Dataset ds000001 Status
![ds000001](https://img.shields.io/badge/ds000001-passing-brightgreen)

Processing of dataset ds000001 is currently: **PASSING** ✅
```

## Workflow Integration

The badges automatically update when:
- Matrix jobs complete (success/failure)
- New datasets are added to processing
- Workflow is manually triggered
- Processing status changes

Each badge links to the workflow execution for detailed logs and troubleshooting.
