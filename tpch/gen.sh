#!/bin/bash
set -euo pipefail

SF=${1:-0.001}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DBGEN_DIR="$SCRIPT_DIR/tpch-dbgen"
BUILD_DIR="$DBGEN_DIR/build"
OUTPUT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)/output/tpch

if [ ! -x "$BUILD_DIR/dbgen" ]; then
    echo 'Compiling tpch-dbgen'
    cmake -S "$DBGEN_DIR" -B "$BUILD_DIR" > /dev/null
    cmake --build "$BUILD_DIR" > /dev/null
fi

cd "$DBGEN_DIR"
rm -f ./*.tbl

echo 'Generating TPC-H dataset'
"$BUILD_DIR/dbgen" -s "$SF" 1> /dev/null 2> /dev/null

mkdir -p "$OUTPUT_DIR"

sed -i 's/|$//' ./*.tbl

mv customer.tbl "$OUTPUT_DIR/customer.csv"
mv lineitem.tbl "$OUTPUT_DIR/lineitem.csv"
mv nation.tbl "$OUTPUT_DIR/nation.csv"
mv orders.tbl "$OUTPUT_DIR/orders.csv"
mv partsupp.tbl "$OUTPUT_DIR/partsupp.csv"
mv part.tbl "$OUTPUT_DIR/part.csv"
mv region.tbl "$OUTPUT_DIR/region.csv"
mv supplier.tbl "$OUTPUT_DIR/supplier.csv"

echo "Done! Data written to $OUTPUT_DIR"
