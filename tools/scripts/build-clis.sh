#!/usr/bin/env bash
#
# Build segman CLIs into dist/. Library consumers don't need this — they
# vendor go/segman.go, js/segman.js, etc. directly. This is for local dev
# use of the standalone CLIs (segman-go-cli, segman-rust-cli, etc.) and
# for the manuscript-prep tools under tools/manuscript and
# tools/scenario-building.
#
# dist/ is gitignored; running this is always safe.

set -euo pipefail

cd "$(dirname "$0")/../.."
mkdir -p dist

echo "== Go segman CLI =="
(cd go && go build -o ../dist/segman-go-cli ./cmd/segman)

echo "== JS segman CLI =="
cp js/segman-cli.js dist/segman-node-cli
chmod +x dist/segman-node-cli

echo "== Rust segman CLI =="
(cd rust && cargo build --release --bin segman-cli)
cp rust/target/release/segman-cli dist/segman-rust-cli

echo "== Manuscript + scenario-building tools (Go) =="
(cd tools/manuscript/00-sanitize-manuscript && go build -o ../../../dist/00-sanitize-manuscript .)
(cd tools/scenario-building/01-segment-reference && go build -o ../../../dist/01-segment-reference .)
(cd tools/scenario-building/02-inspect-segments && go build -o ../../../dist/02-inspect-segments .)
(cd tools/scenario-building/03-add-scenario && go build -o ../../../dist/03-add-scenario .)

echo "== Bash tools =="
cp tools/manuscript/04-manuscript-context dist/04-manuscript-context
chmod +x dist/04-manuscript-context

echo
echo "Built into dist/:"
ls -lh dist/
