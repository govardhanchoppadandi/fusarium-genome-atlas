#!/usr/bin/env bash
set -Eeuo pipefail
MODE="$1"; INPUT_DIR="$2"; OUTPUT_DIR="$3"
LINEAGE="${4:-hypocreales_odb12.2}"; THREADS="${5:-8}"

if ! command -v busco >/dev/null 2>&1; then
  echo "[ERROR] BUSCO not found. Activate the Conda environment." >&2
  exit 1
fi
[[ -d "$INPUT_DIR" ]] || { echo "[ERROR] Missing input directory: $INPUT_DIR" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR" logs
shopt -s nullglob
files=()
for ext in fna fa fasta faa; do
  for f in "$INPUT_DIR"/*."$ext"; do [[ -f "$f" ]] && files+=("$f"); done
done
[[ ${#files[@]} -gt 0 ]] || { echo "[ERROR] No FASTA files in $INPUT_DIR" >&2; exit 1; }

failed=0
for input in "${files[@]}"; do
  filename="$(basename "$input")"; sample="${filename%.*}"
  if [[ -d "$OUTPUT_DIR/$sample" ]] && compgen -G "$OUTPUT_DIR/$sample/short_summary*.txt" >/dev/null; then
    echo "[SKIP] $sample summary already exists"; continue
  fi
  if [[ -e "$OUTPUT_DIR/$sample" ]]; then
    echo "[ERROR] Incomplete output exists: $OUTPUT_DIR/$sample (move it before retrying)"
    failed=$((failed+1)); continue
  fi
  echo "[RUN] $MODE $sample"
  if busco -i "$input" -o "$sample" -m "$MODE" -l "$LINEAGE" -c "$THREADS" \
      --out_path "$OUTPUT_DIR" >"logs/${MODE}_${sample}.log" 2>&1; then
    echo "[DONE] $sample"
  else
    echo "[FAILED] $sample; see logs/${MODE}_${sample}.log"
    failed=$((failed+1))
  fi
done
echo "Failed/incomplete samples: $failed"
[[ "$failed" -eq 0 ]]
