# Snakemake Executor MWE

Minimal working example for testing Snakemake with different executors (local, LSF, AWS Batch).

Uses Biopython (Python dependency) and seqkit (CLI tool) to verify conda environments work correctly across execution backends.

## Prerequisites

- [Conda](https://docs.conda.io/en/latest/) or [Mamba](https://mamba.readthedocs.io/)

## Install

Create the snakemake environment (includes all executor plugins):

```bash
conda env create -f envs/snakemake.yaml
conda activate snakemake-executors
```

Create the workflow conda environment (used by rules):

```bash
conda env create -f envs/bioenv.yaml
```

## Run Locally

```bash
snakemake
```

This uses `profiles/default/` automatically.

## Run on LSF

Edit `profiles/lsf/config.yaml` if you need to change the queue:

```yaml
default-resources:
  lsf_queue: normal  # change to your queue
```

Then run:

```bash
snakemake --profile profiles/lsf
```

Monitor jobs:

```bash
bjobs -w
```

## Run on AWS Batch

1. Edit `profiles/aws-batch/config.yaml` with your queue ARN:

```yaml
default-resources:
  aws_batch_job_queue: arn:aws:batch:us-east-1:123456789:job-queue/your-queue
```

2. Ensure AWS credentials are configured (`aws configure` or environment variables)

3. Run:

```bash
snakemake --profile profiles/aws-batch
```

## Expected Output

After a successful run:

```
results/
├── sample_A_biopython.json   # Biopython stats (JSON)
├── sample_A_seqkit.txt       # seqkit stats
├── sample_B_biopython.json
├── sample_B_seqkit.txt
├── sample_C_biopython.json
├── sample_C_seqkit.txt
└── combined_report.txt       # Aggregated results
```

Verify execution hosts:

```bash
grep "hostname" results/combined_report.txt
```

## Dry Run

Add `-n` to any command to see what would run without executing:

```bash
snakemake -n
```
