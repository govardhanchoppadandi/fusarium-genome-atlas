# 781-Genome Mash Phylogenomic Analysis of *Fusarium*

## 1. Overview

This workflow describes the preparation of a curated collection of 781 *Fusarium* genome assemblies and the construction of a Mash-based phylogenetic tree using Mashtree.

The analysis uses Mash genomic distances, Mashtree phylogenetic reconstruction and QuickTree for tree generation. Bootstrap resampling is performed using 1,000 replicates to estimate support for internal tree groupings.

The workflow was developed using Ubuntu on Windows Subsystem for Linux (WSL), with a Conda environment for the required bioinformatics software.

### Analysis summary

| Parameter | Description |
|---|---|
| Original genome assemblies | 814 |
| Excluded genome assemblies | 33 |
| Retained genome assemblies | 781 |
| Preliminary test genomes | 20 |
| Distance estimation | Mash |
| Phylogenetic reconstruction | Mashtree |
| Tree-building software | QuickTree |
| Bootstrap replicates | 1,000 |
| CPU threads | 10 |
| Tree output | Newick |
| Distance matrix | TSV |

## 2. Dataset Preparation

### 2.1 Original Genome Collection

The initial dataset consisted of 814 genome accessions documented in the master Excel file:

`FUSARIUM_FINAL_MASTER.xlsx`

Each accession was matched with its corresponding genome assembly in the original source directory.

The matching procedure was checked for:

- Unique accessions.
- Corresponding genome assembly files.
- Missing genome matches.
- Multiple genome matches.
- Duplicate genome abbreviations.

The verification confirmed 814 unique accessions with one corresponding source genome file per accession.

### 2.2 Genome Exclusion

Thirty-three selected genome assemblies were excluded from the retained dataset.

The excluded files were moved into:

`REMOVED GENOMES/`

The remaining 781 genome assemblies were retained in:

`RESTORED_814/`

The original source genome directory was preserved.

### 2.3 Excluded Genome List

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

### 2.4 Final Dataset Verification

| Directory | Genome assemblies |
|---|---:|
| Original collection | 814 |
| Excluded collection | 33 |
| Retained collection | 781 |

Genome filenames containing spaces were standardized by removing spaces. All 781 retained genome filenames were verified to contain no spaces.

Verify the retained genome count:

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"

find . -maxdepth 1 -type f -name '*.fna' | wc -l
```

Expected result:

```text
781
```

## 3. Computational Environment

The analysis was performed using Ubuntu under Windows Subsystem for Linux (WSL).

### 3.1 Conda Environment

Activate the analysis environment:

```bash
conda activate fusarium_tree
```

### 3.2 Software

| Software | Version / configuration |
|---|---|
| Mash | 2.3 |
| Mashtree | 0.30 |
| QuickTree | Conda environment |
| Perl | Conda environment |
| Python | Conda environment |
| Operating system | Ubuntu / WSL |

Verify the installed software:

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

## 4. Mashtree Compatibility Corrections

During preliminary testing, two compatibility problems were identified in the installed Mashtree source code. The original files were backed up before modification.

### 4.1 Backup Original Files

```bash
cp "$CONDA_PREFIX/bin/mashtree_wrapper.pl" \
"$CONDA_PREFIX/bin/mashtree_wrapper.pl.backup"

cp "$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm" \
"$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm.backup"
```

### 4.2 Correct PHYLIP Formatting Arguments

The original wrapper contained:

```perl
my $phylipString=$mashtreeDb->toString("phylip","rand");
```

The database method expects:

```perl
toString($genome,$format,$sortBy)
```

The corrected code is:

```perl
my $phylipString=$mashtreeDb->toString([],"phylip","rand");
```

This specifies an empty genome filter, PHYLIP format and randomized ordering.

### 4.3 Correct SQLite Random Ordering

The original database code contained:

```perl
ORDER BY NEWID()
```

The SQLite-compatible expression is:

```perl
ORDER BY RANDOM()
```

This correction addresses the random-ordering operation used during bootstrap processing.

### 4.4 Apply Both Corrections

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

### 4.5 Verify Perl Syntax

```bash
perl -c "$CONDA_PREFIX/bin/mashtree_wrapper.pl"

perl -c "$CONDA_PREFIX/lib/perl5/site_perl/5.22.0/Mashtree/Db.pm"
```

Both files should report:

```text
syntax OK
```

**Reproducibility note:** These are local compatibility modifications to the installed Mashtree environment. A fresh installation may require the same corrections or a compatible software version.

## 5. Preliminary 20-Genome Test

Before performing the complete analysis, a preliminary test was conducted using 20 genome assemblies.

The test evaluated:

- Mash genome sketching.
- Pairwise distance calculation.
- PHYLIP matrix generation.
- QuickTree construction.
- Bootstrap tree generation.
- Newick output.

### 5.1 Test Command

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

### 5.2 Test Results

The preliminary test completed successfully after the compatibility corrections.

Verified results:

- 20 genome labels in the Newick tree.
- 21 lines in the distance matrix.
- Bootstrap support values present.
- No bootstrap worker termination errors.

Two bootstrap replicates were used for technical testing only. The final analysis uses 1,000 replicates.

## 6. Temporary Directory Configuration

The main project path contains spaces:

```text
/mnt/f/fusarium WGS/
```

During testing, Mashtree internal shell commands failed when temporary files were created using paths containing spaces.

An example error was:

```text
Parent directory (/mnt/f/fusarium) is not a directory
```

To avoid this issue, a separate temporary directory without spaces was created.

### 6.1 Create Temporary Directory

```bash
mkdir -p /mnt/f/MASHTREE_TMP

mkdir -p /mnt/f/MASHTREE_TMP/mashtree_run2
```

### 6.2 Set TMPDIR

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

The final analysis uses this separate temporary directory.

## 7. Final 781-Genome Mash Phylogenomic Analysis

### 7.1 Analysis Parameters

| Parameter | Setting |
|---|---|
| Genome assemblies | 781 |
| Distance method | Mash |
| Phylogenetic reconstruction | Mashtree |
| Tree construction | QuickTree |
| Bootstrap replicates | 1,000 |
| CPU threads | 10 |
| Tree format | Newick |
| Distance matrix | TSV |
| Temporary directory | `/mnt/f/MASHTREE_TMP/mashtree_run2` |

### 7.2 Create Output Directories

```bash
mkdir -p "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS"

mkdir -p /mnt/f/MASHTREE_TMP/mashtree_run2
```

### 7.3 Activate Conda Environment

```bash
conda activate fusarium_tree
```

### 7.4 Configure Temporary Directory

```bash
export TMPDIR=/mnt/f/MASHTREE_TMP
```

### 7.5 Navigate to the Genome Directory

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"
```

### 7.6 Identify Genome Assemblies

```bash
shopt -s nullglob

files=( *.fna )

echo "Genome count: ${#files[@]}"
```

Expected:

```text
Genome count: 781
```

### 7.7 Full Analysis Command

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

### 7.8 Expected Output Files

| Filename | Description |
|---|---|
| `Fusarium_781_Mash_tree_1000bootstraps.nwk` | Phylogenetic tree with bootstrap support |
| `Fusarium_781_Mash_distance_matrix.tsv` | Pairwise Mash distance matrix |
| `Fusarium_781_Mash_analysis.log` | Analysis progress and diagnostic log |

## 8. Running the Analysis with tmux

The full analysis may take considerable time. The tmux utility allows the process to continue independently of the visible terminal window.

### 8.1 Start tmux

```bash
tmux new -s fusarium781
```

### 8.2 Activate the Environment

```bash
conda activate fusarium_tree
```

### 8.3 Configure Temporary Directory

```bash
export TMPDIR=/mnt/f/MASHTREE_TMP
```

### 8.4 Execute the Full Analysis

Run the command described in Section 7.7.

### 8.5 Detach Safely

Press:

```text
Ctrl + B
```

Release both keys, then press:

```text
D
```

The analysis continues in the background.

### 8.6 Reconnect to the Session

```bash
tmux attach -t fusarium781
```

### 8.7 Check Active Sessions

```bash
tmux ls
```

### 8.8 Monitor Analysis Progress

```bash
tail -10 "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS/Fusarium_781_Mash_analysis.log"
```

Check running processes:

```bash
pgrep -af 'mashtree|mash|quicktree'
```

**Important:** tmux protects against ordinary terminal closure, but not against terminating WSL, restarting Windows, shutting down the computer or power loss.

## 9. Final Output Validation

The analysis should be considered complete only after the tree, matrix and bootstrap processing have been validated.

### 9.1 Navigate to the Output Directory

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/MASH_ANALYSIS"
```

### 9.2 Check Output Files

```bash
ls -lh Fusarium_781_Mash*
```

### 9.3 Verify Distance Matrix

```bash
wc -l Fusarium_781_Mash_distance_matrix.tsv
```

Expected:

```text
782 Fusarium_781_Mash_distance_matrix.tsv
```

This represents one header line and 781 genome rows.

### 9.4 Verify Newick Tree

```bash
ls -lh Fusarium_781_Mash_tree_1000bootstraps.nwk
```

The file must exist and must not be empty.

Check the ending:

```bash
tail -c 100 Fusarium_781_Mash_tree_1000bootstraps.nwk
```

A complete Newick tree should terminate with a semicolon.

### 9.5 Check for Errors

```bash
grep -iE 'error|terminated|fatal' Fusarium_781_Mash_analysis.log
```

Unexpected errors or terminated bootstrap workers must be investigated.

### 9.6 Check Bootstrap Messages

```bash
grep -i 'bootstrap' Fusarium_781_Mash_analysis.log | tail -20
```

### 9.7 Final Validation Criteria

| Validation | Expected result |
|---|---|
| Input genome count | 781 |
| Distance matrix | Nonempty |
| Matrix line count | 782 |
| Newick tree | Nonempty |
| Newick termination | Semicolon |
| Genome labels | 781 unique tips |
| Bootstrap processing | Completed |
| Fatal errors | None |
| Exit code | 0 |

A zero-byte tree, missing matrix or incomplete bootstrap run must not be treated as a successful analysis.

## 10. Phylogenetic Tree Visualization

The final Newick tree can be visualized using the Interactive Tree Of Life (iTOL).

Website:

https://itol.embl.de/

### Tree Input

Upload:

`Fusarium_781_Mash_tree_1000bootstraps.nwk`

The tree can be displayed using rectangular, circular, radial or unrooted layouts.

Bootstrap support values can be displayed on internal branches where supported by the tree format.

### Distance Matrix

The file:

`Fusarium_781_Mash_distance_matrix.tsv`

can be retained for pairwise distance comparisons, clustering and additional comparative genomic analyses.

Both files should be archived together.

## 11. Reproducibility and Data Management

For reproducible analysis:

1. Preserve the original genome assemblies.
2. Retain the master Excel file.
3. Preserve the 33 excluded genome identifiers.
4. Record the software versions.
5. Document the Mashtree compatibility corrections.
6. Preserve the exact genome filename list.
7. Record the bootstrap replicate count and CPU settings.
8. Retain the analysis log.
9. Validate the final Newick tree and distance matrix.
10. Do not publish incomplete results as final outputs.

### 11.1 Record Conda Packages

```bash
conda list > fusarium_tree_conda_packages.txt
```

### 11.2 Export the Conda Environment

```bash
conda env export --no-builds > fusarium_tree_environment.yml
```

### 11.3 Record Mash Version

```bash
mash --version > mash_version.txt
```

### 11.4 Record Mashtree Version

```bash
mashtree --version > mashtree_version.txt 2>&1
```

### 11.5 Preserve the Genome Input List

```bash
cd "/mnt/f/fusarium WGS/ALL GENOMES/RESTORED_814"

printf '%s\n' *.fna > Fusarium_781_genome_file_list.txt
```

This records the genome filenames used for the analysis.

## 12. Analysis Status

The following stages have been completed:

- Collection of 814 original genome accessions.
- Accession-to-assembly matching.
- Exclusion of 33 genome assemblies.
- Retention of 781 genome assemblies.
- Filename standardization.
- Final dataset verification.
- Mashtree compatibility corrections.
- Preliminary 20-genome bootstrap test.

The full 781-genome, 1,000-bootstrap analysis requires final validation of the Newick tree, distance matrix, analysis log and exit code before being declared complete.

## 13. Methodological Note

Mash-based genomic distances provide a genome-wide measure of sequence similarity. Mashtree uses these distances for phylogenetic reconstruction, with QuickTree used during tree construction.

Bootstrap support values estimate the stability of internal groupings under the implemented resampling procedure.

The resulting phylogeny represents a distance-based overview of genomic relationships among the selected *Fusarium* assemblies.

Interpretation should consider assembly quality, genome composition, taxonomic identification and the limitations of distance-based phylogenetic methods.

Bootstrap support should not be interpreted as a direct measure of evolutionary divergence or species identity.
