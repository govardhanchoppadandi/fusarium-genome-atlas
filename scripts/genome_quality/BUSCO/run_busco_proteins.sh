#!/usr/bin/env bash
set -Eeuo pipefail
[[ $# -ge 2 ]] || { echo "Usage: $0 INPUT_DIR OUTPUT_DIR [LINEAGE] [THREADS]" >&2; exit 2; }
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$D/run_busco_batch.sh" proteins "$1" "$2" "${3:-hypocreales_odb12.2}" "${4:-8}"
