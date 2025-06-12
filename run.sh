#!/usr/bin/env nix-shell
#! nix-shell -i bash -p gccForLibs

set -euo pipefail

source venv/bin/activate

libdir="$(dirname "$(realpath "$(command -v g++)")")/../lib"
echo "libdir: $libdir"
export LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

python phi3-qa.py -m cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4 -e cpu
