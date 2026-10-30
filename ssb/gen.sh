#!/bin/bash
set -euo pipefail

SF=${1:-0.001}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DBGEN_DIR="$SCRIPT_DIR/ssb-dbgen"
BUILD_DIR="$DBGEN_DIR/build"
OUTPUT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)/output/ssb

if [ ! -x "$BUILD_DIR/dbgen" ]; then
    echo 'Compiling ssb-dbgen'
    cmake -S "$DBGEN_DIR" -B "$BUILD_DIR" > /dev/null
    cmake --build "$BUILD_DIR" > /dev/null
fi

cd "$DBGEN_DIR"
rm -f ./*.tbl

echo 'Generating SSB dataset'
"$BUILD_DIR/dbgen" -s "$SF" 1> /dev/null 2> /dev/null

mkdir -p "$OUTPUT_DIR"

sed -i 's/|$//' ./*.tbl

mv lineorder.tbl "$OUTPUT_DIR/lineorder.csv"
mv customer.tbl "$OUTPUT_DIR/customer.csv"
mv part.tbl "$OUTPUT_DIR/part.csv"
mv supplier.tbl "$OUTPUT_DIR/supplier.csv"
mv date.tbl "$OUTPUT_DIR/date.csv"

echo "Done! Data written to $OUTPUT_DIR"
