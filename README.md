# multidbgen

`multidbgen` generates datasets for multiple analytical database benchmarks
from a single repository. It currently supports **TPC-H** and the **Star Schema
Benchmark (SSB)**. Each benchmark's upstream data generator is kept as a git
submodule, and the helper scripts build the generator, run it, and place the
resulting table files in `output/`.

| Benchmark | Upstream generator | Generated tables |
|-----------|--------------------|------------------|
| TPC-H | [eyalroz/tpch-dbgen](https://github.com/eyalroz/tpch-dbgen) | `customer`, `lineitem`, `nation`, `orders`, `part`, `partsupp`, `region`, `supplier` |
| SSB | [eyalroz/ssb-dbgen](https://github.com/eyalroz/ssb-dbgen) | `customer`, `date`, `lineorder`, `part`, `supplier` |

## Repository layout

```text
.
├── gen_dataset.sh          # single entry point for both benchmarks
├── tpch/
│   ├── gen.sh              # TPC-H build + generation wrapper
│   └── tpch-dbgen/         # TPC-H submodule (dbgen, qgen, query templates)
├── ssb/
│   ├── gen.sh              # SSB build + generation wrapper
│   └── ssb-dbgen/          # SSB submodule (dbgen)
├── samples/                # small pre-generated datasets for reference
│   ├── tpch/
│   └── ssb/
└── output/                 # generated datasets (ignored by git)
    ├── tpch/
    └── ssb/
```

## Requirements

- `git`
- `bash`
- A C compiler (`gcc` or `clang`) and `make` (or another CMake-supported build tool)
- CMake 3.13 or newer (the scripts use `cmake -S` / `cmake -B`)
- A POSIX-like shell environment (Linux, WSL, or macOS with GNU `sed`)

On Debian/Ubuntu, the build dependencies can be installed with:

```bash
sudo apt-get install build-essential cmake git
```

## Setup

### Clone with submodules

```bash
git clone --recurse-submodules git@github.com:vudala/multidbgen.git
cd multidbgen
```

### Initialize submodules in an existing clone

If the repository was cloned without `--recurse-submodules`, fetch the
generators with:

```bash
git submodule update --init --recursive
```

Verify that both submodules are present:

```bash
git submodule status
ls tpch/tpch-dbgen ssb/ssb-dbgen
```

The submodules are pinned to specific commits. To update them to the latest
upstream revision recorded by their configured branches:

```bash
git submodule update --remote --merge
```

## Quick start

Generate a small TPC-H dataset:

```bash
./gen_dataset.sh tpch 0.01
```

Generate a small SSB dataset:

```bash
./gen_dataset.sh ssb 0.01
```

If no scaling factor is given, the scripts use `0.001`:

```bash
./gen_dataset.sh tpch
```

The first run builds the selected generator with CMake. This can take a short
while; subsequent runs reuse the build.

The generated files are written to:

```text
output/tpch/
output/ssb/
```

The output directory is ignored by git, so generated data will not be committed.

## Using the benchmark wrappers

The benchmark-specific wrappers can also be run directly:

```bash
./tpch/gen.sh 0.01
./ssb/gen.sh 0.01
```

Each wrapper:

1. Builds the submodule's `dbgen` binary if it is not already built.
2. Removes any old `.tbl` files from the submodule directory.
3. Runs `dbgen` with the requested scaling factor.
4. Removes the trailing `|` from each line.
5. Moves the results to `output/<benchmark>/` with a `.csv` extension.

### TPC-H output files

```text
output/tpch/customer.csv
output/tpch/lineitem.csv
output/tpch/nation.csv
output/tpch/orders.csv
output/tpch/part.csv
output/tpch/partsupp.csv
output/tpch/region.csv
output/tpch/supplier.csv
```

### SSB output files

```text
output/ssb/customer.csv
output/ssb/date.csv
output/ssb/lineorder.csv
output/ssb/part.csv
output/ssb/supplier.csv
```

**Note:** despite the `.csv` extension, the generated files are pipe-delimited
(`|`) text files, not comma-separated files. The wrapper only renames them and
strips the trailing pipe. Configure your database loader with `|` as the field
separator. Text fields may contain commas, so do not load these files with a
comma delimiter.

## Scaling factors

The scaling factor is passed directly to the upstream `dbgen` utility. Larger
values produce more rows and larger files. Use a small value such as `0.001` or
`0.01` for smoke tests; `1` is the standard validation scale for TPC-H and
produces roughly 1 GB of raw data. SSB and TPC-H use different row counts at
the same scaling factor.

Examples:

```bash
./gen_dataset.sh tpch 0.001   # tiny test dataset
./gen_dataset.sh tpch 1       # validation-scale TPC-H dataset
./gen_dataset.sh ssb 0.01     # small SSB dataset
```

## Using the generators directly

The wrapper scripts are conveniences. You can also invoke the upstream tools
yourself when you need finer control. Both generators write their `.tbl` files
into the current working directory and expect `dists.dss` to be available
there.

### TPC-H: dbgen and qgen

```bash
cd tpch/tpch-dbgen
cmake -S . -B build
cmake --build build

./build/dbgen -v -s 0.01 -b dists.dss
./build/qgen -s 0.01 1
```

`dbgen` creates the TPC-H table files. Use `-T` to generate only selected
tables, for example `-T c` for `customer`, `-T o` for `orders`/`lineitem`, or
`-T L` for `lineitem` only. Run `./build/dbgen -h` for the complete option list.

`qgen` generates a parameterized TPC-H query. In the example above, `1` selects
the template `queries/1.sql`; the query is printed to standard output. Use
`-d` for default substitution values, `-r <seed>` to set the random seed, or
`-p <n>` to generate a query stream permutation. Run `./build/qgen -h` for all
options.

### SSB: dbgen

```bash
cd ssb/ssb-dbgen
cmake -S . -B build
cmake --build build

./build/dbgen -v -s 0.01 -b dists.dss
```

Use `-T` to generate only one table, for example `-T l` for `lineorder`,
`-T c` for `customer`, `-T p` for `part`, `-T s` for `supplier`, or `-T d`
for `date`. Run `./build/dbgen -h` for the complete option list.

## Sample data and schemas

The `samples/` directory contains small pre-generated datasets:

```text
samples/tpch/
samples/ssb/
```

These files are intended for inspecting table layouts and for quick tests. They
retain the original trailing pipe from `dbgen` and are not regenerated by the
scripts.

Schema definitions are available in the submodules:

- TPC-H: `tpch/tpch-dbgen/doc/dss.ddl`
- SSB: `ssb/ssb-dbgen/doc/ssb.ddl`

## Troubleshooting

- **Submodule directories are empty:** run
  `git submodule update --init --recursive`.
- **CMake command not found:** install CMake and a C compiler (see
  [Requirements](#requirements)).
- **CMake is too old:** the scripts require CMake 3.13 or newer because they use
  `cmake -S` and `cmake -B`.
- **A submodule build is stale:** remove its build directory and rerun the
  wrapper, for example `rm -rf tpch/tpch-dbgen/build`.
- **`dists.dss` cannot be found:** run the generator from its submodule
  directory, or pass `-b /path/to/dists.dss` explicitly.
- **The generated files do not load as CSV:** use `|` as the field separator.
  The `.csv` extension is only a naming convention used by this repository.

## Further documentation

Each submodule contains its own README with details about the generator:

- `tpch/tpch-dbgen/README.md`
- `ssb/ssb-dbgen/README.md`
