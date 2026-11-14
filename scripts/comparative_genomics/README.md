# Fusarium Comparative Genomics: Genome Preparation and Mash Phylogenetic Analysis

## 1. Project Overview

This workflow describes the preparation of a curated collection of *Fusarium* genome assemblies and the construction of a genome-wide Mash-based phylogenetic tree using Mashtree.

The workflow was developed using Ubuntu on Windows Subsystem for Linux (WSL), with a Conda environment for the required bioinformatics software.

The analysis includes genome accession matching, dataset standardization, genome exclusion, Mash sketching, pairwise distance estimation, phylogenetic reconstruction and bootstrap support estimation.

### 1.1 Dataset Summary

| Description | Number |
|---|---:|
| Original genome accessions in master Excel | 814 |
| Original genome assemblies | 814 |
| Excluded genome assemblies | 33 |
| Retained genome assemblies | 781 |
| Preliminary test genomes | 20 |
| Final bootstrap replicates planned | 1,000 |
| CPU threads | 10 |

### 1.2 Main Objectives

1. Match genome accessions in the master Excel file with their corresponding genome assemblies.
2. Prepare a standardized genome collection.
3. Exclude the specified 33 genome assemblies.
4. Generate Mash sketches.
5. Estimate pairwise genome distances.
6. Construct a phylogenetic tree using Mashtree and QuickTree.
7. Estimate branch support using 1,000 bootstrap replicates.
8. Export a Newick tree and distance matrix for downstream visualization and comparative analysis.

---

## 2. Project Directory Structure

The original project is stored on a Windows drive and accessed through Ubuntu using WSL.

**Original Windows project directory:**

`F:\fusarium WGS\`

**Corresponding WSL directory:**

`/mnt/f/fusarium WGS/`

### 2.1 Main Project Organization

```text
fusarium WGS/
│
├── WGS/
│   └── Original genome assemblies
│
└── ALL GENOMES/
    │
    ├── FUSARIUM_FINAL_MASTER.xlsx
    │
    ├── RESTORED_814/
    │   └── 781 retained genome assemblies
    │
    ├── REMOVED GENOMES/
    │   └── 33 excluded genome assemblies
    │
    └── MASH_ANALYSIS/
        ├── Fusarium_781_Mash_tree_1000bootstraps.nwk
        ├── Fusarium_781_Mash_distance_matrix.tsv
        ├── Fusarium_781_Mash_analysis.log
        └── mashtree_temp_781/
```

**Note:** The directory is named `RESTORED_814`, but after exclusions it contains 781 retained genome assemblies.

The original `WGS` directory was preserved. Dataset selection and exclusion were performed in the working project directories.

### 2.2 Temporary Working Directory

To avoid errors caused by spaces in the main project path, a separate temporary directory was created:

```text
/mnt/f/MASHTREE_TMP/
└── mashtree_run2/
```

This directory is used for temporary Mashtree files and intermediate analysis data.

---

## 3. Genome Accession Matching and Dataset Preparation

The master Excel file contained 814 unique genome accessions.

Each accession was matched against the corresponding genome assembly files in the original source directory.

### 3.1 Matching Verification

The matching procedure was checked for:

- Unique genome accessions.
- Corresponding genome assembly files.
- Missing genome matches.
- Multiple genome matches.
- Duplicate genome abbreviations.

The verification confirmed:

- 814 unique accessions.
- 814 corresponding source genome files.
- No missing matches.
- No multiple matches.
- No duplicate abbreviations.

### 3.2 Genome Organization

The matched genome assemblies were organized into:

```text
RESTORED_814/
```

The original source genome directory remained unchanged.

### 3.3 Genome Exclusion

A total of 33 selected genome assemblies were excluded from the retained dataset.

The excluded assemblies were moved into:

```text
REMOVED GENOMES/
```

The remaining 781 genome assemblies were retained in:

```text
RESTORED_814/
```

### 3.4 Excluded Genome Accessions

The following 33 genome identifiers were excluded:

```text
Fgram_CBS119800
Fgram_CBS139514
Fgram_ET20223
Fusgr_MDC_FgU1
Fuscu_PV
Fusas_181126
Fusas_CBS110258
Fusas_SW73
Fusas_SW74
Fpseudo_Fp222
Fusac_1A
Fusac_F829
Fusce_Fcer1134NY13
Fusfu_I1.3
Fusod_FocTR4_190203
Fusod_race4
Fuspr_FFSCRH7
Fuspr_FV32964
Fuspr_Fpro1B7
Fusud_F-02845
Fusve_BIONCL14
Fusve_BRIP14953
Fusve_FV20984
Fusve_FV20984.1
Fusve_FV25055.1
Fusve_FV25058.1
Fusve_FV25228
Fusve_FV28945
Fusve_FV28946
Fusve_FV28946.1
Fusve_FV28947.1
Fusve_FV28948
Fusve_FV34775.1
```

### 3.5 Final Dataset Verification

| Directory | Verified number of files |
|---|---:|
| RESTORED_814 | 781 |
| REMOVED GENOMES | 33 |
| Total | 814 |

Genome filenames containing spaces were standardized by removing spaces.

Examples:

```text
Fusas_CBS110258.fna
Fusod_race4.fna
Fuspr_FFSCRH7.fna
```

All 781 retained genome filenames were verified to contain no spaces.

### 3.6 Verify Genome Count

The following command can be used to verify the retained dataset:

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"

find . -maxdepth 1 -type f -name '*.fna' | wc -l
```

Expected result:

```text
781
```

---

## 4. Ubuntu, WSL and Conda Environment

The analysis was performed using Ubuntu under Windows Subsystem for Linux (WSL).

### 4.1 Activate the Conda Environment

```bash
conda activate fusarium_tree
```

### 4.2 Software Used

| Software | Version / Configuration |
|---|---|
| Mash | 2.3 |
| Mashtree | 0.30 |
| QuickTree | Conda environment |
| Perl | Conda environment |
| Python | Conda environment |
| SQLite | Used through Perl DBI |
| Operating environment | Ubuntu / WSL |
| Environment manager | Conda |

### 4.3 Verify Software Installation

Mash:

```bash
mash --version
```

Mashtree wrapper:

```bash
which mashtree_wrapper.pl
```

QuickTree:

```bash
which quicktree
```

Python:

```bash
which python
```

Perl:

```bash
perl --version
```

### 4.4 Record Conda Environment

The complete Conda package list can be recorded using:

```bash
conda list > fusarium_tree_conda_packages.txt
```

For a reproducible environment specification:

```bash
conda env export --no-builds > fusarium_tree_environment.yml
```

---

## 5. Mashtree Compatibility Corrections

During preliminary testing, two compatibility problems were identified in the installed Mashtree source code.

The original installed files were backed up before modification.

These corrections were necessary for the installed version to complete the bootstrap procedure.

### 5.1 Back Up the Original Files

```bash
cp "$CONDA_PREFIX/bin/mashtree_wrapper.pl" \
"$CONDA_PREFIX/bin/mashtree_wrapper.pl.backup"

cp "$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm" \
"$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm.backup"
```

### 5.2 Correct the PHYLIP Formatting Arguments

The original wrapper contained:

```perl
my $phylipString=$mashtreeDb->toString("phylip","rand");
```

However, the database method expects the following argument order:

```perl
toString($genome,$format,$sortBy)
```

The original call incorrectly passed `"phylip"` as the first argument and `"rand"` as the second argument.

The corrected code is:

```perl
my $phylipString=$mashtreeDb->toString([],"phylip","rand");
```

This specifies:

- An empty genome filter.
- PHYLIP output format.
- Randomized ordering.

### 5.3 Correct SQLite Random Ordering

The original database implementation contained:

```perl
ORDER BY NEWID()
```

The installed database uses SQLite.

The SQLite-compatible random-ordering expression is:

```perl
ORDER BY RANDOM()
```

This correction allows the randomized ordering operation used during bootstrap processing to work with SQLite.

### 5.4 Apply the Corrections

The following Python script was used to apply both exact modifications:

```python
from pathlib import Path
import os

wrapper = (
    Path(os.environ["CONDA_PREFIX"])
    / "bin/mashtree_wrapper.pl"
)

dbfile = (
    Path(os.environ["CONDA_PREFIX"])
    / "lib/perl5/site_perl/5.22.0/Mashtree/Db.pm"
)

s = wrapper.read_text()

old = '$mashtreeDb->toString("phylip","rand")'
new = '$mashtreeDb->toString([],"phylip","rand")'

assert s.count(old) == 1

wrapper.write_text(s.replace(old, new))

s = dbfile.read_text()

assert s.count("ORDER BY NEWID()") == 1

dbfile.write_text(
    s.replace("ORDER BY NEWID()", "ORDER BY RANDOM()")
)

print("Both corrections applied successfully.")
```

### 5.5 Verify Perl Syntax

```bash
perl -c "$CONDA_PREFIX/bin/mashtree_wrapper.pl"

perl -c "$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm"
```

Expected result:

```text
syntax OK
```

**Reproducibility note:** These are local compatibility modifications to the installed Conda environment. A new installation may require the same corrections or a compatible upstream software version. The modifications should be documented rather than assumed to be part of the original Mashtree release.

---

## 6. Preliminary Mashtree Test

Before running the complete 781-genome analysis, a preliminary test was performed using 20 genome assemblies.

The purpose was to verify the complete basic workflow.

### 6.1 Test Objectives

The test evaluated:

1. Genome sketching.
2. Pairwise distance calculation.
3. PHYLIP matrix generation.
4. QuickTree construction.
5. Bootstrap tree generation.
6. Newick output generation.

### 6.2 Test Command

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"

files=( *.fna )

subset=( "${files[@]:0:20}" )

mkdir -p /tmp/mashtree_test_run

mashtree_wrapper.pl \
    --tempdir /tmp/mashtree_test_run \
    --reps 2 \
    --numcpus 4 \
    --outmatrix "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/test_distance_matrix.tsv" \
    "${subset[@]}" \
    > "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/test_tree.nwk" \
    2> "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/test_run.log"
```

### 6.3 Test Results

The corrected 20-genome test completed successfully.

Verified results:

- All 20 genome labels were present in the Newick tree.
- The distance matrix contained 21 lines.
- Bootstrap support values were present in the Newick tree.
- No bootstrap worker termination errors were reported.

The test confirmed that the corrected workflow could construct a bootstrap-supported tree on the test dataset.

**Important:** Two bootstrap replicates were used for this preliminary technical test only. They are not the final analysis settings.

---

## 7. Temporary Directory Configuration

The original project directory contains spaces:

```text
/mnt/f/fusarium WGS/
```

During testing, Mashtree internal shell commands failed when temporary files were created using paths containing spaces.

An example error was:

```text
Parent directory (/mnt/f/fusarium) is not a directory
```

The issue was addressed by creating a separate temporary directory without spaces.

### 7.1 Create the Temporary Directory

```bash
mkdir -p /mnt/f/MASHTREE_TMP

mkdir -p /mnt/f/MASHTREE_TMP/mashtree_run2
```

### 7.2 Set TMPDIR

```bash
export TMPDIR=/mnt/f/MASHTREE_TMP
```

Verify:

```bash
echo "$TMPDIR"
```

Expected:

```text
/mnt/f/MASHTREE_TMP
```

The temporary directory is separate from the main project directory to avoid internal path-handling problems.

### 7.3 Storage Considerations

Temporary files can require substantial storage during large genome analyses.

Before running the analysis, check available disk space:

```bash
df -h /mnt/f
```

The temporary directory should be located on a filesystem with sufficient free space.

Do not remove temporary files while Mashtree is running.

---

## 8. Final Mash Phylogenomic Analysis: 781 Genomes

### 8.1 Analysis Parameters

| Parameter | Setting |
|---|---|
| Genome assemblies | 781 |
| Input format | FASTA (`.fna`) |
| Distance method | Mash |
| Tree construction | Mashtree |
| Tree-building executable | QuickTree |
| Bootstrap replicates | 1,000 |
| CPU threads | 10 |
| Tree format | Newick |
| Distance matrix format | TSV |
| Temporary directory | `/mnt/f/MASHTREE_TMP/mashtree_run2` |

### 8.2 Create Output Directories

```bash
mkdir -p "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS"

mkdir -p /mnt/f/MASHTREE_TMP/mashtree_run2
```

### 8.3 Activate the Conda Environment

```bash
conda activate fusarium_tree
```

### 8.4 Configure the Temporary Directory

```bash
export TMPDIR=/mnt/f/MASHTREE_TMP
```

### 8.5 Move to the Genome Directory

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"
```

### 8.6 Identify the Genome Assemblies

```bash
shopt -s nullglob

files=( *.fna )

echo "Genome count: ${#files[@]}"
```

Expected result:

```text
Genome count: 781
```

### 8.7 Execute the Complete Analysis

```bash
mashtree_wrapper.pl \
    --tempdir /mnt/f/MASHTREE_TMP/mashtree_run2 \
    --reps 1000 \
    --numcpus 10 \
    --outmatrix "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/Fusarium_781_Mash_distance_matrix.tsv" \
    "${files[@]}" \
    > "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/Fusarium_781_Mash_tree_1000bootstraps.nwk" \
    2> "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/Fusarium_781_Mash_analysis.log"

echo "Analysis exit code: $?"
```

### 8.8 Expected Outputs

The command produces three principal output files:

1. `Fusarium_781_Mash_tree_1000bootstraps.nwk` — phylogenetic tree in Newick format.
2. `Fusarium_781_Mash_distance_matrix.tsv` — pairwise Mash distance matrix.
3. `Fusarium_781_Mash_analysis.log` — analysis messages, progress and errors.

The Newick file is written to standard output, while diagnostic messages are redirected to the log file.

---

## 9. Running Long Analyses with tmux

The 781-genome analysis is computationally intensive and may take a considerable amount of time.

The workflow uses tmux to keep the analysis running independently of the visible terminal window.

### 9.1 Start a tmux Session

```bash
tmux new -s fusarium781
```

### 9.2 Activate the Environment

Inside the tmux session:

```bash
conda activate fusarium_tree
```

### 9.3 Configure TMPDIR

```bash
export TMPDIR=/mnt/f/MASHTREE_TMP
```

### 9.4 Execute the Full Analysis

Run the complete command described in Section 8.

### 9.5 Detach from the Session

Press:

```text
Ctrl + B
```

Release the keys and press:

```text
D
```

The tmux session remains active.

### 9.6 Reconnect to the Session

```bash
tmux attach -t fusarium781
```

### 9.7 List Active tmux Sessions

```bash
tmux ls
```

### 9.8 Monitor the Analysis Log

```bash
tail -10 "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/Fusarium_781_Mash_analysis.log"
```

### 9.9 Check Running Processes

```bash
pgrep -af 'mashtree|mash|quicktree'
```

**Important:** tmux protects against ordinary terminal closure. It does not protect against terminating WSL, shutting down Windows, restarting the computer or power loss. Keep the computer powered on during the analysis.

---

## 10. Final Output Verification

The final outputs must be checked before the analysis is considered complete.

### 10.1 Navigate to the Analysis Directory

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS"
```

### 10.2 Check Output Files

```bash
ls -lh Fusarium_781_Mash*
```

The tree and distance matrix must both exist and have nonzero file sizes.

### 10.3 Verify the Distance Matrix

```bash
wc -l Fusarium_781_Mash_distance_matrix.tsv
```

Expected:

```text
782 Fusarium_781_Mash_distance_matrix.tsv
```

This represents one header line and 781 genome rows, assuming the standard matrix output contains one row per genome.

### 10.4 Verify the Newick Tree

```bash
ls -lh Fusarium_781_Mash_tree_1000bootstraps.nwk
```

The tree file must not be empty.

Check its final characters:

```bash
tail -c 100 Fusarium_781_Mash_tree_1000bootstraps.nwk
```

A valid complete Newick tree should terminate with a semicolon.

### 10.5 Check for Errors

```bash
grep -iE 'error|terminated|fatal' Fusarium_781_Mash_analysis.log
```

Unexpected errors or terminated bootstrap workers must be investigated.

### 10.6 Check Bootstrap Messages

```bash
grep -i 'bootstrap' Fusarium_781_Mash_analysis.log | tail -20
```

The bootstrap stage must finish successfully before the resulting tree is considered final.

### 10.7 Validation Criteria

| Validation item | Expected condition |
|---|---|
| Genome input count | 781 |
| Distance matrix | Nonempty |
| Distance matrix rows | 782 |
| Newick tree | Nonempty |
| Newick termination | Semicolon |
| Genome labels | 781 unique tips |
| Bootstrap processing | Completed |
| Unexpected fatal errors | None |
| Analysis exit code | 0 |

A zero-byte tree, missing matrix or incomplete log does not represent a successful analysis.

---

## 11. Downstream Phylogenetic Visualization

The resulting Newick tree can be visualized using the Interactive Tree Of Life (iTOL).

Website:

https://itol.embl.de/

### 11.1 Tree Visualization

Upload:

`Fusarium_781_Mash_tree_1000bootstraps.nwk`

The tree can be displayed using different layouts, including:

- Rectangular.
- Circular.
- Radial.
- Unrooted.

Bootstrap support values can be displayed on internal branches where supported by the tree format.

### 11.2 Distance Matrix

The matrix file:

`Fusarium_781_Mash_distance_matrix.tsv`

can be retained for:

- Pairwise genomic distance comparisons.
- Genome clustering.
- Distance-based exploratory analysis.
- Comparative genomic visualization.
- Additional phylogenomic investigations.

The distance matrix and Newick tree are separate analytical outputs and should be archived together.

---

## 12. Reproducibility and Data Management

The following practices should be maintained:

1. Preserve the original genome assemblies.
2. Retain the master Excel file.
3. Preserve the list of excluded genome accessions.
4. Record the genome selection and matching procedure.
5. Record all software versions.
6. Document the Mashtree compatibility corrections.
7. Retain the exact genome filename list used in the final run.
8. Record the bootstrap replicate count and CPU settings.
9. Retain the analysis log.
10. Validate the tree and distance matrix before publication.
11. Keep temporary analysis files until the final outputs have been validated.
12. Avoid publishing incomplete or unverified results as final phylogenetic outputs.

### 12.1 Save the Conda Environment

```bash
conda list > fusarium_tree_conda_packages.txt
```

```bash
conda env export --no-builds > fusarium_tree_environment.yml
```

### 12.2 Record Software Versions

```bash
mash --version > mash_version.txt
```

```bash
mashtree --version > mashtree_version.txt 2>&1
```

The installed wrapper location can be recorded using:

```bash
which mashtree_wrapper.pl
```

QuickTree location:

```bash
which quicktree
```

### 12.3 Preserve the Exact Genome Input List

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"

printf '%s\n' *.fna > Fusarium_781_genome_file_list.txt
```

This file documents the genome filenames included in the analysis.

---

## 13. Repository Organization

The workflow is documented within the Fusarium Genome Atlas repository.

Relevant repository structure:

```text
fusarium-genome-atlas/
│
├── docs/
│   ├── figures/
│   └── methodology/
│       ├── mash_phylogenomics_781.md
│       └── secretome_effector_workflow.md
│
├── scripts/
│   ├── comparative_genomics/
│   │   ├── README.md
│   │   └── mashtree_781.sh
│   │
│   ├── gene_prediction/
│   ├── genome_quality/
│   ├── metadata_retrieval/
│   └── secretome_analysis/
│
├── .gitignore
├── LICENSE
├── README.md
└── requirements.txt
```

The comparative genomics directory contains the executable Bash workflow and its corresponding documentation.

The detailed methodology is maintained separately under `docs/methodology/`.

---

## 14. Analysis Status

The dataset preparation and preliminary technical testing have been completed.

The workflow has undergone the following stages:

| Workflow stage | Status |
|---|---|
| Original accession collection | Completed |
| Accession-to-assembly matching | Completed |
| Genome exclusion | Completed |
| Filename standardization | Completed |
| Final dataset verification | Completed |
| Mashtree compatibility corrections | Completed |
| 20-genome preliminary test | Completed |
| Full 781-genome analysis | Awaiting final validation |
| 1,000-bootstrap tree | Awaiting final validation |
| Final distance matrix | Awaiting final validation |
| iTOL visualization | Pending final tree |

The full-scale analysis must be marked complete only after the Newick tree, distance matrix, bootstrap processing and analysis log have been successfully validated.

---

## 15. Methodological Notes

This workflow uses Mash-based genomic distances to summarize genome-wide sequence similarity and Mashtree for phylogenetic reconstruction.

QuickTree is used during the tree-building stage.

Bootstrap replicates are used to estimate support for internal tree groupings under the implemented resampling procedure.

The resulting tree represents a distance-based genome-wide phylogenetic overview of the selected *Fusarium* assemblies.

Interpretation should consider the limitations of distance-based phylogenetic methods, genome assembly quality, taxonomic identification and the composition of the selected dataset.

Bootstrap support should not be interpreted as a direct measure of evolutionary divergence or species identity.

The tree should be evaluated alongside additional evidence, including genome quality, taxonomic information, marker-based phylogeny and comparative genomic analyses.

---

## 16. Acknowledgment

This workflow forms part of the *Fusarium Genome Atlas*, a comparative genomics project focused on the genomic diversity, evolutionary relationships, genome architecture and pathogenicity-associated features of *Fusarium*.

The workflow is intended to support reproducible genome-wide distance analysis and downstream phylogenomic investigation.

Software versions, dataset composition, analysis parameters and final output files should be documented when reporting or publishing the results.
