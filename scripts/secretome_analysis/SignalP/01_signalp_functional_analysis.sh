#!/usr/bin/env bash
# SignalP 6 batch workflow for top-level protein FASTA files.
# DeepTMHMM is intentionally NOT run by this script.

set -Eeuo pipefail

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate secretome

BASE="/mnt/f/fusarium WGS/ALL PROTEINS FOR FUNCTIONAL ANALSYSI"
OUT="/mnt/f/fusarium WGS/secretome analysis/functional_analysis"

mkdir -p "$OUT"

if [ ! -d "$BASE" ]; then
    echo "ERROR: Input folder not found: $BASE"
    exit 1
fi

shopt -s nullglob
FILES=(
    "$BASE"/*.faa "$BASE"/*.fasta "$BASE"/*.fa
    "$BASE"/*.FAA "$BASE"/*.FASTA "$BASE"/*.FA
)

TOTAL=${#FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "ERROR: No FASTA files found."
    exit 1
fi

# Avoid collisions if files with different extensions share the same basename.
declare -A SEEN
for PROT in "${FILES[@]}"; do
    NAME=$(basename "$PROT")
    NAME="${NAME%.*}"
    if [[ -n "${SEEN[$NAME]+x}" ]]; then
        echo "ERROR: Duplicate output name: $NAME"
        echo "Files: ${SEEN[$NAME]} and $PROT"
        exit 1
    fi
    SEEN[$NAME]="$PROT"
done

COMPLETED=0
SKIPPED=0
FAILED=0
COUNT=0

echo "=========================================="
echo "SIGNALP 6 - FUNCTIONAL ANALYSIS"
echo "Input files: $TOTAL"
echo "Input: $BASE"
echo "Output: $OUT"
echo "Subfolders will NOT be processed."
echo "=========================================="

for PROT in "${FILES[@]}"; do
    COUNT=$((COUNT + 1))

    NAME=$(basename "$PROT")
    NAME="${NAME%.*}"

    DIR="$OUT/$NAME"
    SIGOUT="$DIR/signalp"
    SP="$DIR/signal_positive.faa"
    DONE="$DIR/signalp.done"

    mkdir -p "$DIR"

    INPUT_SIZE=$(stat -c %s "$PROT")
    INPUT_MTIME=$(stat -c %Y "$PROT")

    # A result is skipped only if the completion marker, SignalP report,
    # extracted FASTA, and input-file fingerprint all match.
    if [ -f "$DONE" ] &&
       [ -f "$SIGOUT/prediction_results.txt" ] &&
       [ -f "$SP" ] &&
       grep -Fxq "INPUT_SIZE=$INPUT_SIZE" "$DONE" &&
       grep -Fxq "INPUT_MTIME=$INPUT_MTIME" "$DONE"; then

        SKIPPED=$((SKIPPED + 1))
        echo "[$COUNT/$TOTAL] SKIP: $NAME (already completed)"
        continue
    fi

    echo
    echo "[$COUNT/$TOTAL] Processing: $NAME"

    TMP_SIG=$(mktemp -d "$DIR/.signalp_tmp.XXXXXX")
    TMP_SP="$DIR/.signal_positive.tmp.$$"
    TMP_LOG="$DIR/.signalp.log.tmp.$$"

    # Run SignalP. Failed temporary outputs and logs are retained for diagnosis.
    if ! python -m signalp.predict \
        --fastafile "$PROT" \
        --organism euk \
        --output_dir "$TMP_SIG" \
        --format none \
        --mode fast \
        --bsize 32 > "$TMP_LOG" 2>&1; then

        FAILED=$((FAILED + 1))
        STAMP=$(date +%Y%m%d_%H%M%S)
        mv "$TMP_SIG" "$DIR/signalp_failed_$STAMP"
        mv "$TMP_LOG" "$DIR/signalp_failed_$STAMP.log"
        echo "FAILED: $NAME - see signalp_failed_$STAMP.log"
        continue
    fi

    if [ ! -s "$TMP_SIG/prediction_results.txt" ]; then
        FAILED=$((FAILED + 1))
        STAMP=$(date +%Y%m%d_%H%M%S)
        mv "$TMP_SIG" "$DIR/signalp_failed_$STAMP"
        mv "$TMP_LOG" "$DIR/signalp_failed_$STAMP.log"
        echo "FAILED: prediction_results.txt missing for $NAME"
        continue
    fi

    # Select IDs predicted as SP, then write their complete original sequences.
    if ! INPUT_FASTA="$PROT" \
         PREDICTION_FILE="$TMP_SIG/prediction_results.txt" \
         OUTPUT_FASTA="$TMP_SP" \
         python - <<'PY'
import os
from Bio import SeqIO

input_fasta = os.environ["INPUT_FASTA"]
prediction_file = os.environ["PREDICTION_FILE"]
output_fasta = os.environ["OUTPUT_FASTA"]

sp_ids = set()

with open(prediction_file) as handle:
    for line in handle:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split()
        if len(fields) >= 2 and fields[1] == "SP":
            sp_ids.add(fields[0])

records = list(SeqIO.parse(input_fasta, "fasta"))
record_ids = {record.id for record in records}

missing = sp_ids - record_ids
if missing:
    raise RuntimeError(
        f"{len(missing)} SignalP IDs were not found in the original FASTA. "
        f"Examples: {list(missing)[:5]}"
    )

selected = [record for record in records if record.id in sp_ids]
SeqIO.write(selected, output_fasta, "fasta")

print(f"Input proteins: {len(records)}")
print(f"Signal peptide-positive proteins: {len(selected)}")
print(f"SignalP-positive FASTA created: {output_fasta}")
PY
    then
        FAILED=$((FAILED + 1))
        STAMP=$(date +%Y%m%d_%H%M%S)
        mv "$TMP_SIG" "$DIR/signalp_failed_$STAMP"
        mv "$TMP_LOG" "$DIR/signalp_failed_$STAMP.log"
        rm -f "$TMP_SP"
        echo "FAILED: FASTA extraction for $NAME"
        continue
    fi

    # Keep previous outputs as timestamped backups before replacing them.
    STAMP=$(date +%Y%m%d_%H%M%S)

    if [ -e "$SIGOUT" ]; then
        mv "$SIGOUT" "$DIR/signalp_backup_$STAMP"
    fi

    if [ -e "$SP" ]; then
        mv "$SP" "$DIR/signal_positive_backup_$STAMP.faa"
    fi

    if [ -e "$DONE" ]; then
        mv "$DONE" "$DIR/signalp.done.backup_$STAMP"
    fi

    if [ -e "$DIR/signalp.log" ]; then
        mv "$DIR/signalp.log" "$DIR/signalp_previous_$STAMP.log"
    fi

    mv "$TMP_SIG" "$SIGOUT"
    mv "$TMP_SP" "$SP"
    mv "$TMP_LOG" "$DIR/signalp.log"

    {
        echo "INPUT_SIZE=$INPUT_SIZE"
        echo "INPUT_MTIME=$INPUT_MTIME"
        echo "COMPLETED=$(date)"
    } > "$DONE"

    COMPLETED=$((COMPLETED + 1))
    echo "COMPLETED: $NAME"
done

echo
echo "=========================================="
echo "SIGNALP RUN SUMMARY"
echo "Total input files: $TOTAL"
echo "Newly completed: $COMPLETED"
echo "Already completed/skipped: $SKIPPED"
echo "Failed: $FAILED"
echo "Output folder: $OUT"
echo "=========================================="
