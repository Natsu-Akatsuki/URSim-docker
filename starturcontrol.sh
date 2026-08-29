#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOADER="$SCRIPT_DIR/dynlibs/ld-linux-x86-64.so.2"
PRODUCT_VERSION="$(sed -n 's/.*marketingVersion.* "\([0-9\.]*\)".*;/\1/p' "$SCRIPT_DIR/metadata.n3")"

if [[ -z "$PRODUCT_VERSION" ]]; then
    PRODUCT_VERSION=5.14.0
fi

# URSim 5.26 bundles a newer glibc than Ubuntu 20.04. Its bundled loader must
# load URControl; using /lib64/ld-linux-x86-64.so.2 mixes incompatible glibcs.
HOME="$SCRIPT_DIR" "$LOADER" \
    --library-path "$SCRIPT_DIR/dynlibs" \
    "$SCRIPT_DIR/URControl" -m "$PRODUCT_VERSION" -r \
    >"$SCRIPT_DIR/URControl.log" 2>&1 &

printf '%s\n' "$!" >"$SCRIPT_DIR/.urcontrol.pid"
