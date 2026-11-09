# Fusarium Genome Gene Prediction Using AUGUSTUS

## 1. Overview

This module performs gene prediction on *Fusarium* genome assemblies using AUGUSTUS.

It is part of the Fusarium Genome Atlas project, a literature-curated comparative genomics resource for wheat-associated *Fusarium*.

The workflow processes genome assemblies arranged in species-specific and accession-specific folders and generates predicted gene models, protein sequences and coding DNA sequences.

## 2. Objectives

- Predict protein-coding gene models from genome assemblies.
- Generate GFF3 gene annotation files.
- Extract predicted protein sequences.
- Extract predicted coding DNA sequences (CDS).
- Maintain a report of completed, skipped, failed and missing-FASTA records.

## 3. Software Requirements

- Linux or Windows Subsystem for Linux (WSL2)
- Conda or Miniconda
- AUGUSTUS
- gffread

Install the environment:

```bash
conda env create -f environment.yml
conda activate fusarium_gene
```

Verify the installation:

```bash
which augustus
which gffread
augustus --version
gffread --version
```

Set the AUGUSTUS configuration directory:

```bash
export AUGUSTUS_CONFIG_PATH="$CONDA_PREFIX/config"
```

## 4. Input Data Organization

The script expects genome assemblies in the following directory structure:

```text
DATA_ROOT/
├── Species_1/
│   ├── Genome_Accession_1/
│   │   └── genome.fna
│   └── Genome_Accession_2/
│       └── genome.fna
└── Species_2/
    └── Genome_Accession_3/
        └── genome.fna
```

Supported genome FASTA extensions include `.fna`, `.fasta` and `.fa`, including uppercase variants.

The script searches exactly two directory levels below the data root.

## 5. AUGUSTUS Species Model

The current workflow uses the AUGUSTUS species model:

`fusarium_graminearum`

This model is applied to all processed genomes in the current configuration.

**Scientific limitation:** A model trained for *F. graminearum* may not be optimal for other *Fusarium* species. Cross-species predictions should be considered preliminary unless evaluated using suitable species-specific parameters, trusted annotations or a validated training procedure.

The model can be changed using the `AUGUSTUS_SPECIES` environment variable, provided the selected model is installed.

## 6. Execution

Activate the Conda environment:

```bash
conda activate fusarium_gene
```

Set the configuration directory:

```bash
export AUGUSTUS_CONFIG_PATH="$CONDA_PREFIX/config"
```

Make the script executable:

```bash
chmod +x run_augustus_all_fusarium.sh
```

Run the workflow:

```bash
bash run_augustus_all_fusarium.sh "/mnt/f/fusarium WGS"
```

The input directory can be changed by supplying a different path as the first argument.

## 7. Output Files

For each processed genome, the workflow generates:

| Output | Description |
|---|---|
| `genes.gff3` | Predicted gene models |
| `proteins.faa` | Predicted protein sequences |
| `cds.fna` | Predicted coding DNA sequences |

Two additional files are generated in the main data directory:

- `gene_prediction_report.tsv` — processing status for each genome.
- `augustus_prediction.log` — diagnostic messages from AUGUSTUS and gffread.

## 8. Processing Status

The script reports the following statuses:

- `COMPLETED` — gene prediction and sequence extraction succeeded.
- `SKIPPED` — a non-empty `protein.faa` or `proteins.faa` already exists.
- `FAILED` — AUGUSTUS or sequence extraction failed.
- `NO_FASTA` — no supported genome FASTA file was found in the genome directory.

The report and log are reset at the beginning of each execution.

## 9. Reproducibility

For reproducible analysis, record:

- Genome assembly accession.
- AUGUSTUS version.
- AUGUSTUS species model.
- Conda environment and software versions.
- Input genome assembly files.
- Execution date and command.
- Any model training or validation procedures.

## 10. Role in the Fusarium Genome Atlas

Predicted gene models and protein sequences will support subsequent analyses, including:

- Comparative gene content analysis.
- Ortholog identification.
- Candidate effector prediction.
- CAZyme identification.
- Functional annotation.
- Comparative phylogenomics.
- Genome evolution and host-association studies.

Predicted gene models are computational annotations and should not be interpreted as experimentally validated genes or virulence factors.
