#!/usr/bin/env bash
# Run AUGUSTUS gene prediction for genome FASTA files arranged as:
# BASE_DIR/species_name/genome_accession/genome.fna
#
# Usage:
#   bash run_augustus_all_fusarium.sh "/mnt/f/fusarium WGS"
#
# Optional environment variables:
#   AUGUSTUS_SPECIES=fusarium_graminearum
#   AUGUSTUS_CONFIG_PATH=/path/to/augustus/config

set -uo pipefail
export LC_ALL=C

BASE_DIR="${1:-/mnt/f/fusarium WGS}"
AUGUSTUS_SPECIES="${AUGUSTUS_SPECIES:-fusarium_graminearum}"

REPORT="$BASE_DIR/gene_prediction_report.tsv"
LOG="$BASE_DIR/augustus_prediction.log"

# Find the configuration directory for common Conda/Bioconda layouts.
if [[ -z "${AUGUSTUS_CONFIG_PATH:-}" ]]; then
    if [[ -n "${CONDA_PREFIX:-}" && -d "$CONDA_PREFIX/config/species" ]]; then
        export AUGUSTUS_CONFIG_PATH="$CONDA_PREFIX/config"
    elif [[ -n "${CONDA_PREFIX:-}" && -d "$CONDA_PREFIX/share/augustus/config/species" ]]; then
        export AUGUSTUS_CONFIG_PATH="$CONDA_PREFIX/share/augustus/config"
    else
        echo "ERROR: Could not find AUGUSTUS config/species."
        echo "Activate the Conda environment and set AUGUSTUS_CONFIG_PATH if needed."
        exit 1
    fi
fi

if [[ ! -d "$BASE_DIR" ]]; then
    echo "ERROR: Input directory does not exist: $BASE_DIR"
    echo 'Usage: bash run_augustus_all_fusarium.sh "/path/to/fusarium WGS"'
    exit 1
fi

for program in augustus gffread find; do
    if ! command -v "$program" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $program"
        echo "Activate the environment described in README.md."
        exit 1
    fi
done

if [[ ! -d "$AUGUSTUS_CONFIG_PATH/species/$AUGUSTUS_SPECIES" ]]; then
    echo "ERROR: AUGUSTUS species model not found:"
    echo "  $AUGUSTUS_CONFIG_PATH/species/$AUGUSTUS_SPECIES"
    echo "Choose an installed model or configure/train an appropriate one."
    exit 1
fi

# This report describes the current run; the log is also reset each run.
printf 'Genome_Folder\tGenome_FASTA\tStatus\tReason\n' > "$REPORT"
: > "$LOG"

completed=0
skipped=0
failed=0
missing=0
total=0

echo "AUGUSTUS batch gene prediction"
echo "Input directory: $BASE_DIR"
echo "Species model:   $AUGUSTUS_SPECIES"
echo "Config directory: $AUGUSTUS_CONFIG_PATH"
echo "Report: $REPORT"
echo "Log:    $LOG"
echo

# Expected layout: BASE_DIR/species/genome_accession/
# Only directories exactly two levels below BASE_DIR are considered.
while IFS= read -r -d '' asm; do
    ((total+=1))
    genome_name="$(basename "$asm")"

    # Skip if either common protein output filename already exists and is non-empty.
    existing_protein=""
    for p in "$asm/protein.faa" "$asm/proteins.faa"; do
        if [[ -s "$p" ]]; then
            existing_protein="$p"
            break
        fi
    done

    if [[ -n "$existing_protein" ]]; then
        echo "SKIPPED: $asm (non-empty protein FASTA exists)"
        printf '%s\t%s\tSKIPPED\tExisting protein FASTA: %s\n' \
            "$asm" "" "$existing_protein" >> "$REPORT"
        ((skipped+=1))
        continue
    fi

    # Find the first FASTA file directly inside the genome folder.
    fasta=""
    for f in "$asm"/*.fna "$asm"/*.FNA "$asm"/*.fasta "$asm"/*.FASTA "$asm"/*.fa "$asm"/*.FA; do
        if [[ -f "$f" ]]; then
            fasta="$f"
            break
        fi
    done

    if [[ -z "$fasta" ]]; then
        echo "NO FASTA: $asm"
        printf '%s\t%s\tNO_FASTA\tNo .fna/.fasta/.fa file directly in genome folder\n' \
            "$asm" "" >> "$REPORT"
        ((missing+=1))
        continue
    fi

    gff="$asm/genes.gff3"
    prot="$asm/proteins.faa"
    cds="$asm/cds.fna"

    echo "========================================"
    echo "Running: $genome_name"
    echo "Genome:  $fasta"
    echo "========================================"

    if augustus \
        --species="$AUGUSTUS_SPECIES" \
        --gff3=on \
        --UTR=off \
        "$fasta" > "$gff" 2>> "$LOG"; then

        if gffread "$gff" -g "$fasta" -y "$prot" -x "$cds" 2>> "$LOG" \
            && [[ -s "$gff" && -s "$prot" && -s "$cds" ]]; then
            echo "COMPLETED: $genome_name"
            printf '%s\t%s\tCOMPLETED\tGene prediction and sequence extraction successful\n' \
                "$asm" "$fasta" >> "$REPORT"
            ((completed+=1))
        else
            echo "FAILED: protein/CDS extraction for $genome_name"
            printf '%s\t%s\tFAILED\tgffread failed or one or more output files are empty; see log\n' \
                "$asm" "$fasta" >> "$REPORT"
            ((failed+=1))
        fi
    else
        echo "FAILED: AUGUSTUS for $genome_name"
        printf '%s\t%s\tFAILED\tAUGUSTUS failed; see log\n' \
            "$asm" "$fasta" >> "$REPORT"
        ((failed+=1))
    fi
done < <(find "$BASE_DIR" -mindepth 2 -maxdepth 2 -type d -print0 | sort -z)

echo
echo "============== SUMMARY =============="
echo "Genome folders checked: $total"
echo "Completed:              $completed"
echo "Skipped (protein exists): $skipped"
echo "Failed:                 $failed"
echo "No genome FASTA:        $missing"
echo "Report: $REPORT"
echo "Log:    $LOG"
echo "======================================"
