
#!/usr/bin/env bash

set -Eeuo pipefail

# Fusarium 781-genome Mash phylogenomic analysis

# Activate the Conda environment before running this script.
# Required environment: fusarium_tree

PROJECT="/mnt/f/fusarium WGS/ALL GENOMES"

GENOME_DIR="$PROJECT/RESTORED_814"
OUTPUT_DIR="$PROJECT/MASH_ANALYSIS"

TEMP_DIR="/mnt/f/MASHTREE_TMP/mashtree_run2"

TREE="$OUTPUT_DIR/Fusarium_781_Mash_tree_1000bootstraps.nwk"
MATRIX="$OUTPUT_DIR/Fusarium_781_Mash_distance_matrix.tsv"
LOG="$OUTPUT_DIR/Fusarium_781_Mash_analysis.log"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p /mnt/f/MASHTREE_TMP

export TMPDIR=/mnt/f/MASHTREE_TMP

cd "$GENOME_DIR"

shopt -s nullglob
files=( *.fna )

echo "Genome count: ${#files[@]}"

if [[ ${#files[@]} -ne 781 ]]; then
    echo "ERROR: Expected 781 genome assemblies."
    exit 1
fi

if ! command -v mashtree_wrapper.pl >/dev/null 2>&1; then
    echo "ERROR: Mashtree is not installed or not in PATH."
    exit 1
fi

echo "Starting 781-genome Mashtree analysis..."

mashtree_wrapper.pl \
    --tempdir "$TEMP_DIR" \
    --reps 1000 \
    --numcpus 10 \
    --outmatrix "$MATRIX" \
    "${files[@]}" \
    > "$TREE" \
    2> "$LOG"

echo "Analysis exit code: $?"

echo "Checking outputs..."

test -s "$TREE"
test -s "$MATRIX"

echo "Tree and distance matrix were generated."
