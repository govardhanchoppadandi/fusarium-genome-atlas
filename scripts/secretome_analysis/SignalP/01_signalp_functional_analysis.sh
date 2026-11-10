
cat > ~/01_signalp_functional_analysis.sh <<'BASH'
#!/bin/bash
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

declare -A SEEN
for PROT in "${FILES[@]}"; do
    NAME=$(basename "$PROT")
    NAME="${NAME%.*}"

    if [[ -n "${SEEN[$NAME]+x}" ]]; then
        echo "ERROR: Duplicate output name: $NAME"
        exit 1
    fi

    SEEN[$NAME]="$PROT"
done

COMPLETED=0
SKIPPED=0
FAILED=0
COUNT=0

echo "=========================================="
echo "SIGNALP 6 - VALIDATED FUNCTIONAL ANALYSIS"
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

    # Preserve the existing completed-result skip logic.
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
    TMP_INPUT="$DIR/.signalp_input.tmp.$$"
    TMP_SP="$DIR/.signal_positive.tmp.$$"
    TMP_LOG="$DIR/.signalp.log.tmp.$$"

    # ------------------------------------------
    # STEP 1: VALIDATE AND NORMALIZE INPUT FASTA
    # ------------------------------------------

    if ! python - "$PROT" "$TMP_INPUT" <<'PY'
import sys
from collections import Counter
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

source = sys.argv[1]
destination = sys.argv[2]

# Keep standard amino acids and X.
# Convert all other characters to X.
VALID = set("ACDEFGHIKLMNPQRSTVWYX")

records = list(SeqIO.parse(source, "fasta"))

if not records:
    raise RuntimeError("No FASTA records found")

cleaned = []
replacements = Counter()
modified = 0

for record in records:

    original = str(record.seq).upper()

    if not original:
        raise RuntimeError(f"Empty protein: {record.id}")

    sequence = []

    for aa in original:
        if aa in VALID:
            sequence.append(aa)
        else:
            sequence.append("X")
            replacements[aa] += 1

    sequence = "".join(sequence)

    if len(sequence) != len(original):
        raise RuntimeError(f"Length changed: {record.id}")

    if sequence != original:
        modified += 1

    cleaned.append(
        SeqRecord(
            Seq(sequence),
            id=record.id,
            name=record.name,
            description=record.description
        )
    )

SeqIO.write(cleaned, destination, "fasta")

# Verify the generated FASTA.
verified = list(SeqIO.parse(destination, "fasta"))

if len(verified) != len(records):
    raise RuntimeError("FASTA record count changed")

for record in verified:
    invalid = set(str(record.seq)) - VALID
    if invalid:
        raise RuntimeError(
            f"Invalid characters in {record.id}: {invalid}"
        )

print("FASTA validation successful")
print("Input proteins:", len(records))
print("Validated proteins:", len(verified))
print("Modified proteins:", modified)
print("Replacements:", dict(replacements))
print("Total characters replaced:", sum(replacements.values()))
print("Invalid characters remaining: 0")
PY
    then
        FAILED=$((FAILED + 1))
        STAMP=$(date +%Y%m%d_%H%M%S)

        mv "$TMP_SIG" "$DIR/signalp_failed_$STAMP"
        mv "$TMP_LOG" "$DIR/signalp_failed_$STAMP.log"

        [ ! -f "$TMP_INPUT" ] || \
            mv "$TMP_INPUT" "$DIR/signalp_input_failed_$STAMP.faa"

        echo "FAILED: FASTA validation for $NAME"
        continue
    fi

    # ------------------------------------------
    # STEP 2: RUN SIGNALP 6
    # ------------------------------------------

    if ! python -m signalp.predict \
        --fastafile "$TMP_INPUT" \
        --organism euk \
        --output_dir "$TMP_SIG" \
        --format none \
        --mode fast \
        --bsize 32 > "$TMP_LOG" 2>&1; then

        FAILED=$((FAILED + 1))
        STAMP=$(date +%Y%m%d_%H%M%S)

        mv "$TMP_SIG" "$DIR/signalp_failed_$STAMP"
        mv "$TMP_LOG" "$DIR/signalp_failed_$STAMP.log"
        mv "$TMP_INPUT" "$DIR/signalp_input_failed_$STAMP.faa"

        echo "FAILED: SignalP for $NAME"
        continue
    fi

    if [ ! -s "$TMP_SIG/prediction_results.txt" ]; then

        FAILED=$((FAILED + 1))
        STAMP=$(date +%Y%m%d_%H%M%S)

        mv "$TMP_SIG" "$DIR/signalp_failed_$STAMP"
        mv "$TMP_LOG" "$DIR/signalp_failed_$STAMP.log"
        mv "$TMP_INPUT" "$DIR/signalp_input_failed_$STAMP.faa"

        echo "FAILED: prediction_results.txt missing for $NAME"
        continue
    fi

    # ------------------------------------------
    # STEP 3: EXTRACT COMPLETE POSITIVE SEQUENCES
    # From validated input, preserving IDs.
    # ------------------------------------------

    if ! INPUT_FASTA="$TMP_INPUT" \
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
        f"SignalP IDs not found in validated FASTA: "
        f"{list(missing)[:5]}"
    )

selected = [
    record for record in records
    if record.id in sp_ids
]

SeqIO.write(selected, output_fasta, "fasta")

print("Input proteins:", len(records))
print("Signal peptide-positive proteins:", len(selected))
print("SignalP-positive FASTA created:", output_fasta)
PY
    then

        FAILED=$((FAILED + 1))
        STAMP=$(date +%Y%m%d_%H%M%S)

        mv "$TMP_SIG" "$DIR/signalp_failed_$STAMP"
        mv "$TMP_LOG" "$DIR/signalp_failed_$STAMP.log"
        mv "$TMP_INPUT" "$DIR/signalp_input_failed_$STAMP.faa"

        rm -f "$TMP_SP"

        echo "FAILED: FASTA extraction for $NAME"
        continue
    fi

    # ------------------------------------------
    # STEP 4: PUBLISH SUCCESSFUL RESULTS
    # Preserve previous results as backups.
    # ------------------------------------------

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

    # Keep the validated input as an audit copy.
    mv "$TMP_INPUT" "$DIR/signalp_validated_input.faa"

    {
        echo "INPUT_SIZE=$INPUT_SIZE"
        echo "INPUT_MTIME=$INPUT_MTIME"
        echo "VALIDATION=completed"
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
BASH

chmod +x ~/01_signalp_functional_analysis.sh

bash ~/01_signalp_functional_analysis.sh
