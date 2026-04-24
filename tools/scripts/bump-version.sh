#!/usr/bin/env bash
#
# Bump the segman version everywhere it appears. Usage:
#   tools/scripts/bump-version.sh 1.1.0
#
# Updates VERSION.json, go/segman.go, js/segman.js, rust/Cargo.toml.
# Runs the test suite afterward to make sure nothing broke.

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <new-version>" >&2
    exit 2
fi

NEW="$1"
if ! [[ "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "version must look like X.Y.Z (got $NEW)" >&2
    exit 2
fi

cd "$(dirname "$0")/../.."

# 1. VERSION.json (root source-of-truth document)
sed -i -E 's/"version"[[:space:]]*:[[:space:]]*"[^"]+"/"version": "'"$NEW"'"/' VERSION.json

# 2. Go: const Version = "..."
sed -i -E 's/^(const Version = ").+(")$/\1'"$NEW"'\2/' go/segman.go

# 3. JS: const VERSION = '...'
sed -i -E "s/^const VERSION = '.+';$/const VERSION = '$NEW';/" js/segman.js

# 4. Rust: Cargo.toml [package] version
sed -i -E 's/^version = ".+"$/version = "'"$NEW"'"/' rust/Cargo.toml

echo "Bumped to $NEW. Files updated:"
echo "  VERSION.json     -> $(grep version VERSION.json | tr -d ' ,"')"
echo "  go/segman.go     -> $(grep '^const Version' go/segman.go)"
echo "  js/segman.js     -> $(grep '^const VERSION' js/segman.js)"
echo "  rust/Cargo.toml  -> $(grep '^version' rust/Cargo.toml | head -1)"
echo
echo "Running tests…"
./run-tests
