#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

BENCHMARK=${1:-}
SF=${2:-0.001}

if [[ "$BENCHMARK" != "tpch" && "$BENCHMARK" != "ssb" ]]; then
    echo 'No valid benchmark selected'
    echo "Usage: $0 {tpch|ssb} [scaling_factor]"
    exit 1
fi

echo "Generating dataset for $BENCHMARK benchmark"
echo "Using SF $SF"

"$SCRIPT_DIR/$BENCHMARK/gen.sh" "$SF"
