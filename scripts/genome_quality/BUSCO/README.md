# Fusarium BUSCO pipeline

Reproducible BUSCO 6.1.0 workflow for genome and protein FASTA files, with Conda setup, lineage download, batch execution, combined filtering, and one-sheet Excel reporting.

## Environment

Install Conda/Miniforge, then:

```bash
conda env create -f environment.yml
conda activate fusarium_busco
busco --version
```

Download the lineage (Hypocreales example):

```bash
mkdir -p busco_downloads
busco --download hypocreales_odb12 --download_path busco_downloads
```

Use the lineage identifier accepted by your BUSCO installation, e.g. `hypocreales_odb12.2`.

## Input requirements

Put genome assembly FASTA files (`.fna`, `.fa`, `.fasta`) in one input directory and protein amino-acid FASTA files (`.faa`, `.fa`, `.fasta`) in another. Matching genome/protein sample basenames are needed for pairing.

**Genome mode requires genomic scaffolds/contigs, not CDS-only nucleotide FASTA.** Protein mode requires amino-acid sequences. Verify the source accession and input type before running.

## Run BUSCO

```bash
mkdir -p results/genome results/protein logs

bash scripts/run_busco_genomes.sh \
  inputs/genome results/genome hypocreales_odb12.2 8

bash scripts/run_busco_proteins.sh \
  inputs/protein results/protein hypocreales_odb12.2 8
```

Arguments: input directory, output directory, lineage, CPU threads. The scripts skip samples that already have a BUSCO summary TXT, write individual logs, and do not overwrite existing incomplete output directories. Move an old output directory before intentionally rerunning a sample.

Single-sample examples:

```bash
busco -i inputs/genome/sample_A.fna -o sample_A -m genome \
  -l hypocreales_odb12.2 -c 8 --out_path results/genome

busco -i inputs/protein/sample_A.faa -o sample_A -m proteins \
  -l hypocreales_odb12.2 -c 8 --out_path results/protein
```

## Combine the six species and ALL SPECIES folders

Edit `config/busco_sources.csv` if your folder names differ. Paths in it are relative to the `--root` directory.

```bash
python scripts/summarize_busco.py \
  --root "/mnt/f/fusarium WGS/WGS" \
  --sources config/busco_sources.csv \
  --metadata metadata/sample_metadata.csv \
  --output "ALL_FUSARIUM_BUSCO_GENOME_PROTEIN_SUMMARY.xlsx" \
  --threshold 95
```

The source configuration includes:
- Fusarium tricinctum
- Fusarium poae
- Fusarium graminearum
- Fusarium culmorum
- Fusarium avenaceum
- Fusarium asiaticum
- ALL SPECIES GENOMES / ALL species proteins

The script recursively finds `short_summary*.txt` files. Duplicate sample names are reported; the most recently modified summary is selected for that data type. Review duplicate warnings because identically named samples are not necessarily the same biological isolate.

## Metadata

Fill in `metadata/sample_metadata.csv` using true assembly accessions:

```csv
sample,abbreviation,assembly_accession
sample_A,Ftri,GCA_000000000.1
```

Do not put contig accessions or protein accessions in the assembly accession column. If metadata is not supplied, accession is left blank. Abbreviation defaults to the sample prefix before the first underscore.

## Excel decision rule

The workbook has one sheet and 30 columns in the requested order:
Abbreviation, Assembly Accession, Sample; all genome BUSCO percentages/counts; all protein BUSCO percentages/counts; Genome Decision; Protein Decision; FINAL DECISION.

- KEEP: genome completeness >= threshold AND protein completeness >= threshold.
- REMOVE: either result is missing or either completeness is below threshold.
- Default threshold: 95%.
- Internal stop codons are displayed separately and should be reviewed independently.

## Repository layout

```text
fusarium_busco_git/
├── README.md
├── environment.yml
├── .gitignore
├── config/busco_sources.csv
├── metadata/sample_metadata_template.csv
└── scripts/
    ├── run_busco_batch.sh
    ├── run_busco_genomes.sh
    ├── run_busco_proteins.sh
    └── summarize_busco.py
```

Do not commit large FASTA files, BUSCO result folders, lineage downloads, logs, or generated workbooks unless you intend to publish them. Consider Git LFS or a data repository for large datasets.
