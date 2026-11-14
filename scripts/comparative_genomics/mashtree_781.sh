
#!/usr/bin/env bash

# ============================================================
# FUSARIUM GENOME ATLAS
# 781-GENOME MASH PHYLOGENOMIC ANALYSIS
# ============================================================
#
# Software:
#   Mash 2.3
#   Mashtree 0.30
#   QuickTree
#
# Analysis:
#   781 Fusarium genome assemblies
#   1000 bootstrap replicates
#   10 CPU threads
#
# Environment:
#   Ubuntu / WSL
#   Conda environment: fusarium_tree
#
# Outputs:
#   Newick phylogenetic tree
#   Mash distance matrix
#   Analysis log
#
# IMPORTANT:
#   This script assumes the locally installed Mashtree
#   compatibility corrections described in the methodology.
#
# ============================================================

set -uo pipefail

# -----------------------------
# 1. PROJECT DIRECTORIES
# -----------------------------

PROJECT="/mnt/f/fusarium WGS/ALL GENOMES"

GENOME_DIR="$PROJECT/RESTORED_814"

OUTPUT_DIR="$PROJECT/MASH_ANALYSIS"

TEMP_DIR="/mnt/f/MASHTREE_TMP/mashtree_run2"

# -----------------------------
# 2. OUTPUT FILES
# -----------------------------

TREE="$OUTPUT_DIR/Fusarium_781_Mash_tree_1000bootstraps.nwk"

MATRIX="$OUTPUT_DIR/Fusarium_781_Mash_distance_matrix.tsv"

LOG="$OUTPUT_DIR/Fusarium_781_Mash_analysis.log"

# -----------------------------
# 3. ANALYSIS PARAMETERS
# -----------------------------

EXPECTED_GENOMES=781

BOOTSTRAP_REPLICATES=1000

THREADS=10

# -----------------------------
# 4. ENVIRONMENT CHECKS
# -----------------------------

echo "=========================================="
echo "FUSARIUM MASH PHYLOGENOMIC ANALYSIS"
echo "=========================================="

if [[ "${CONDA_DEFAULT_ENV:-}" != "fusarium_tree" ]]; then
    echo "ERROR: Activate the fusarium_tree Conda environment first."
    echo "Command: conda activate fusarium_tree"
    exit 1
fi

if ! command -v mashtree_wrapper.pl >/dev/null 2>&1; then
    echo "ERROR: mashtree_wrapper.pl not found."
    exit 1
fi

if ! command -v mash >/dev/null 2>&1; then
    echo "ERROR: Mash not found."
    exit 1
fi

if [[ ! -d "$GENOME_DIR" ]]; then
    echo "ERROR: Genome directory not found:"
    echo "$GENOME_DIR"
    exit 1
fi

# -----------------------------
# 5. TEMPORARY DIRECTORY
# -----------------------------

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p /mnt/f/MASHTREE_TMP

export TMPDIR=/mnt/f/MASHTREE_TMP

# -----------------------------
# 6. IDENTIFY GENOME ASSEMBLIES
# -----------------------------

cd "$GENOME_DIR" || exit 1

shopt -s nullglob

FILES=( *.fna )

GENOME_COUNT=${#FILES[@]}

echo "Genome directory: $GENOME_DIR"
echo "Genome count: $GENOME_COUNT"

if [[ "$GENOME_COUNT" -ne "$EXPECTED_GENOMES" ]]; then
    echo "ERROR: Expected $EXPECTED_GENOMES genomes."
    echo "Found: $GENOME_COUNT"
    exit 1
fi

# -----------------------------
# 7. RECORD SOFTWARE VERSIONS
# -----------------------------

echo "Mash version:"
mash --version

echo "Mashtree executable:"
command -v mashtree_wrapper.pl

echo "CPU threads: $THREADS"
echo "Bootstrap replicates: $BOOTSTRAP_REPLICATES"

# -----------------------------
# 8. RUN MASH PHYLOGENOMICS
# -----------------------------

echo "=========================================="
echo "STARTING PHYLOGENOMIC ANALYSIS"
echo "=========================================="

echo "Started: $(date)"

mashtree_wrapper.pl \
    --tempdir "$TEMP_DIR" \
    --reps "$BOOTSTRAP_REPLICATES" \
    --numcpus "$THREADS" \
    --outmatrix "$MATRIX" \
    "${FILES[@]}" \
    > "$TREE" \
    2> "$LOG"

EXIT_CODE=$?

echo "=========================================="
echo "ANALYSIS FINISHED"
echo "=========================================="

echo "Exit code: $EXIT_CODE"
echo "Finished: $(date)"

if [[ "$EXIT_CODE" -ne 0 ]]; then
    echo "ERROR: Mashtree analysis failed."
    echo "Check log: $LOG"
    exit "$EXIT_CODE"
fi

# -----------------------------
# 9. OUTPUT VALIDATION
# -----------------------------

echo "Checking output files..."

if [[ ! -s "$TREE" ]]; then
    echo "ERROR: Newick tree is missing or empty."
    exit 1
fi

if [[ ! -s "$MATRIX" ]]; then
    echo "ERROR: Distance matrix is missing or empty."
    exit 1
fi

MATRIX_LINES=$(wc -l < "$MATRIX")

echo "Distance matrix lines: $MATRIX_LINES"

if [[ "$MATRIX_LINES" -ne $((EXPECTED_GENOMES + 1)) ]]; then
    echo "WARNING: Matrix does not contain the expected number of lines."
fi

if ! tail -c 100 "$TREE" | grep -q ';'; then
    echo "WARNING: Newick tree termination could not be verified."
fi

echo "=========================================="
echo "OUTPUT FILES"
echo "=========================================="

ls -lh "$TREE" "$MATRIX" "$LOG"

echo "=========================================="
echo "WORKFLOW COMPLETED"
echo "=========================================="
