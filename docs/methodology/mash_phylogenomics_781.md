# Fusarium Comparative Genomics: Genome Preparation and Mash Phylogenetic Analysis

## 1. Project overview

This project prepares a curated collection of *Fusarium* genome assemblies and constructs a Mash-based phylogenetic tree using Mashtree.

### Dataset summary

| Description | Number |
|---|---:|
| Original genome accessions in master Excel | 814 |
| Original genome assemblies | 814 |
| Excluded genomes | 33 |
| Retained genome assemblies | 781 |
| Bootstrap replicates planned | 1,000 |
| CPU threads | 10 |

### Main objectives

1. Match genome accessions in the master Excel file with their corresponding genome assemblies.
2. Prepare a standardized genome collection.
3. Exclude the specified 33 genome assemblies.
4. Generate Mash sketches and pairwise genome distances.
5. Construct a phylogenetic tree using Mashtree.
6. Estimate branch support using 1,000 bootstrap replicates.
7. Export the Newick tree and distance matrix for downstream visualization in iTOL.

---

## 2. Project directory structure

The project is stored on a Windows drive and accessed through Ubuntu on WSL.

**Original project directory:**

`F:\fusarium WGS\`

**WSL project directory:**

`/mnt/f/fusarium WGS/`

Main directories:

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

**Important:** The original `WGS` directory was preserved. Genome selection and exclusions were performed in the working dataset.

---

## 3. Genome accession matching and dataset preparation

The master Excel file contained 814 unique genome accessions.

Each accession was matched against the original genome assembly files.

The matching procedure was checked for:

- Unique accessions.
- Corresponding genome assembly files.
- Missing genome matches.
- Multiple genome matches.
- Duplicate abbreviations.

### Matching results

The verification confirmed:

- 814 unique accessions.
- 814 corresponding source genome files.
- No missing matches.
- No multiple matches.
- No duplicate abbreviations.

The matched genome assemblies were organized into:

```text
RESTORED_814/
```

The original source genome directory was not modified.

### Genome exclusions

A total of 33 genomes were excluded from the retained dataset.

The excluded files were moved into:

```text
REMOVED GENOMES/
```

The remaining 781 assemblies were retained in:

```text
RESTORED_814/
```

### Excluded accession list

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

### Final dataset verification

The following checks were performed:

| Directory | Expected files |
|---|---:|
| RESTORED_814 | 781 |
| REMOVED GENOMES | 33 |
| Total | 814 |

Files containing spaces in their names were renamed to standardized filenames without spaces.

Three examples:

```text
Fusas_CBS110258.fna
Fusod_race4.fna
Fuspr_FFSCRH7.fna
```

All 781 retained genome filenames were verified to contain no spaces.

---

## 4. Ubuntu and WSL environment

The analysis was performed using Ubuntu under Windows Subsystem for Linux (WSL).

### Activate the Conda environment

```bash
conda activate fusarium_tree
```

### Software versions

| Software | Version / location |
|---|---|
| Mash | 2.3 |
| Mashtree | 0.30 |
| QuickTree | Conda environment |
| Perl | Conda environment |
| Python | Conda environment |
| Operating environment | Ubuntu / WSL |

### Verify software

```bash
mash --version
```

```bash
which mashtree_wrapper.pl
```

```bash
which quicktree
```

```bash
which python
```

---

## 5. Important Mashtree compatibility corrections

During testing, two compatibility problems were identified in the installed Mashtree code.

The installed files were backed up before modification.

### 5.1 Backup original files

```bash
cp "$CONDA_PREFIX/bin/mashtree_wrapper.pl" \
"$CONDA_PREFIX/bin/mashtree_wrapper.pl.backup"

cp "$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm" \
"$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm.backup"
```

### 5.2 Correct the bootstrap PHYLIP formatting arguments

The original wrapper contained:

```perl
my $phylipString=$mashtreeDb->toString("phylip","rand");
```

However, the database method expects the arguments in this order:

```perl
toString($genome,$format,$sortBy)
```

The corrected code is:

```perl
my $phylipString=$mashtreeDb->toString([],"phylip","rand");
```

This supplies an empty genome filter, the PHYLIP format, and randomized ordering.

### 5.3 Correct SQLite random ordering

The original database code contained:

```perl
ORDER BY NEWID()
```

The SQLite-compatible expression is:

```perl
ORDER BY RANDOM()
```

This correction is required for randomized bootstrap distance ordering in the SQLite database.

### 5.4 Apply the corrections

The following Python script was used to make the exact changes:

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

### 5.5 Verify Perl syntax

```bash
perl -c "$CONDA_PREFIX/bin/mashtree_wrapper.pl"

perl -c "$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm"
```

Both files should report:

```text
syntax OK
```

**Reproducibility note:** These corrections modify the installed Conda environment, not the original genome assemblies. Record the installed Mashtree source version and retain the backups when reproducing this workflow.

---

## 6. Preliminary Mashtree test

Before analyzing all 781 genomes, a test was performed using 20 genome assemblies.

The purpose was to verify:

- Genome sketching.
- Distance calculation.
- PHYLIP matrix generation.
- QuickTree construction.
- Bootstrap tree generation.
- Newick output.

### Test command

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

### Test results

The 20-genome test completed successfully after correcting the bootstrap compatibility problems.

Verified results:

- 20 genome labels in the Newick tree.
- 21 lines in the distance matrix (header plus 20 genomes).
- Bootstrap support values present in the tree.
- No bootstrap worker termination errors.

The test established that the corrected workflow could generate a bootstrap-supported tree on the test dataset.

**Note:** Two bootstrap replicates were used for testing only. These are not the final phylogenetic analysis settings.

---

## 7. Important temporary-directory correction

A further problem occurred because the project directory contains spaces:

```text
/mnt/f/fusarium WGS/
```

Mashtree uses internal shell commands to create temporary files. Some of these commands mishandled the spaces in the directory path.

The resulting error included:

```text
Parent directory (/mnt/f/fusarium) is not a directory
```

The solution was to use a separate temporary directory without spaces.

### Create temporary directory

```bash
mkdir -p /mnt/f/MASHTREE_TMP
mkdir -p /mnt/f/MASHTREE_TMP/mashtree_run2
```

### Set TMPDIR

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

The final analysis uses this space-free temporary location.

---

## 8. Final phylogenetic analysis: 781 genomes

### Analysis settings

| Parameter | Setting |
|---|---|
| Number of genomes | 781 |
| Method | Mash / Mashtree |
| Bootstrap replicates | 1,000 |
| CPU threads | 10 |
| Tree format | Newick |
| Distance output | TSV |
| Temporary directory | `/mnt/f/MASHTREE_TMP/mashtree_run2` |

### Create output directories

```bash
mkdir -p "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS"

mkdir -p /mnt/f/MASHTREE_TMP/mashtree_run2
```

### Activate the Conda environment

```bash
conda activate fusarium_tree
```

### Set the temporary directory

```bash
export TMPDIR=/mnt/f/MASHTREE_TMP
```

### Move to the genome directory

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"
```

### Identify all genome assemblies

```bash
shopt -s nullglob

files=( *.fna )

echo "Genome count: ${#files[@]}"
```

Expected:

```text
Genome count: 781
```

### Full Mashtree analysis command

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

The command writes:

1. A bootstrap-supported Newick phylogenetic tree.
2. A pairwise Mash distance matrix.
3. A log containing analysis messages and errors.

---

## 9. Running the analysis safely with tmux

Because the analysis may take a long time, it is run inside a persistent tmux session.

This prevents the process from being terminated simply because the Ubuntu terminal window is closed.

### Start tmux

```bash
tmux new -s fusarium781
```

Inside the session:

```bash
conda activate fusarium_tree

export TMPDIR=/mnt/f/MASHTREE_TMP
```

Then execute the full analysis command from Section 8.

### Detach from tmux

Press:

```text
Ctrl + B
```

Release the keys, then press:

```text
D
```

The analysis continues running in the detached session.

### Reconnect to the analysis

```bash
tmux attach -t fusarium781
```

### Check whether the session exists

```bash
tmux ls
```

### Monitor the analysis log

```bash
tail -10 "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/Fusarium_781_Mash_analysis.log"
```

### Check running processes

```bash
pgrep -af 'mashtree|mash|quicktree'
```

**Important:** tmux protects against closing the terminal, but it does not protect against terminating WSL or shutting down/restarting Windows. Keep the computer powered on during the analysis.

---

## 10. Final output verification

After the analysis finishes, check the output files.

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS"

ls -lh Fusarium_781_Mash*
```

### Check distance matrix

```bash
wc -l Fusarium_781_Mash_distance_matrix.tsv
```

Expected:

```text
782 Fusarium_781_Mash_distance_matrix.tsv
```

This represents one header line and 781 genome rows.

### Check tree file size

```bash
ls -lh Fusarium_781_Mash_tree_1000bootstraps.nwk
```

The file should not be empty.

### Check Newick tree ending

```bash
tail -c 100 Fusarium_781_Mash_tree_1000bootstraps.nwk
```

The Newick tree should terminate with a semicolon.

### Check errors

```bash
grep -iE 'error|terminated|fatal' Fusarium_781_Mash_analysis.log
```

No unexpected errors or terminated bootstrap workers should remain.

### Check bootstrap messages

```bash
grep -i 'bootstrap' Fusarium_781_Mash_analysis.log | tail -20
```

The final analysis should complete the bootstrap stage before the tree is considered final.

**Do not treat an incomplete or zero-byte Newick file as a successful result.**

---

## 11. Expected final outputs

| Output | Description |
|---|---|
| `Fusarium_781_Mash_tree_1000bootstraps.nwk` | Bootstrap-supported phylogenetic tree |
| `Fusarium_781_Mash_distance_matrix.tsv` | Pairwise Mash distance matrix |
| `Fusarium_781_Mash_analysis.log` | Analysis log |

### Downstream analysis

The Newick tree can be uploaded to:

https://itol.embl.de/

The distance matrix can be retained for further comparative genomic analyses, clustering, distance comparisons, and downstream visualization.

---

## 12. Important reproducibility considerations

1. Preserve the original genome assemblies.
2. Keep the master Excel file and the excluded-genome list.
3. Record all software versions and Conda environment information.
4. Retain the corrected Mashtree source files or document the two compatibility patches.
5. Keep the exact genome filename list used for the final analysis.
6. Record the final command, bootstrap replicate count, and CPU settings.
7. Retain the analysis log.
8. Verify the final Newick tree and distance matrix before downstream use.
9. Do not delete temporary files until the analysis is completed and outputs have been validated.
10. Do not claim the final 781-genome tree is complete until the 1,000-bootstrap run has finished successfully.

### Record the software environment

The following commands can be used to document the software environment:

```bash
conda list > fusarium_tree_conda_packages.txt
```

```bash
mash --version > mash_version.txt
```

```bash
mashtree --version > mashtree_version.txt 2>&1
```

---

## 13. Current analysis status

At the time this workflow was documented:

- The dataset preparation was completed.
- The final dataset contained 781 genome assemblies.
- The 20-genome bootstrap test passed.
- The Mashtree compatibility corrections were applied.
- The space-free temporary directory was configured.
- The 781-genome, 1,000-bootstrap analysis was started.
- The log showed genome sketching activity.

**The final full-scale phylogenetic analysis is still in progress and must be validated after completion.**

---

## Acknowledgment of methods

The phylogenetic workflow uses Mash-based genomic distances and Mashtree for tree construction, with QuickTree used in the tree-building stage. The analysis is intended to provide a genome-wide distance-based phylogenetic overview of the curated *Fusarium* collection.

The exact software versions, genome selection procedure, bootstrap settings, and output files should accompany any publication or public repository release.
