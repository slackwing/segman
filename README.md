# segman

A sentence segmenter for prose manuscripts. Splits running text into
sentences while respecting dialogue, quotations, and inline structures
(parens, brackets, italics) — the cases where a naive period-split goes
wrong.

Available in **Go**, **JavaScript**, and **Rust**. All three pass the
same regression corpus (`tests/scenarios.jsonl`) and produce identical
splits for the same input.

Current version: **1.0.0**

## Layout

```
segman/
├── go/             Go library + CLI (import "github.com/slackwing/segman/go")
├── js/             JavaScript library + CLI (CommonJS + browser globals)
├── rust/           Rust crate (segman) + CLI binary
├── tests/          scenarios.jsonl — language-agnostic regression corpus
├── reference/      the-wildfire.manuscript — full manuscript test fixture
├── tools/          Dev tools (manuscript prep, scenario building, build scripts)
├── integrations/   Drop-in integrations for downstream consumers
│   └── git-hook/   pre-commit hook for manuscript repos (see below)
├── run-tests       Top-level test runner
└── VERSION.json    Single source of truth for the cross-language version string
```

## Using it

### Vendor by copy (recommended for personal projects)

This repo doesn't publish to package registries (yet). Consumers copy
the per-language lib file into their project and stamp where it came
from:

- **Go**: copy `go/segman.go` and `go/go.mod` into your project's
  `internal/segman/` (or wherever). Adjust the package name if your
  project's vendor convention prefers a different one.
- **JS**: copy `js/segman.js`. It exports CommonJS (`module.exports`)
  for Node and a `window.segman` namespace + top-level `segment` global
  for the browser.
- **Rust**: copy `rust/src/lib.rs` into your crate, or pin via
  `Cargo.toml`'s `[dependencies] segman = { git = "..." }`.

### Public API per language

All three expose the same two-symbol surface:

| Lang | Function | Version |
|------|----------|---------|
| Go   | `func Segment(text string) []string` | `const Version = "1.0.0"` |
| JS   | `function segment(text) -> string[]`  | `const VERSION = '1.0.0'` |
| Rust | `pub fn segment(text: &str) -> Vec<String>` | `pub const VERSION: &str = "1.0.0"` |

That's it. No initializer, no options, no state.

## Versioning

`VERSION.json` is the source of truth and is mirrored into each
language's lib at the same string. Bump them together:

```
tools/scripts/bump-version.sh 1.1.0
```

The script updates all four spots and runs the test suite. **Don't
hand-edit the version anywhere** — use the script so they can't drift.

A version bump means: behavior may have changed. Even a patch bump
(1.0.0 → 1.0.1) can produce different segmentations for the same input
if a bug fix changes a rule. Consumers that key downstream data off
segment outputs (sentence IDs, etc.) should record which version
produced their data and treat outputs from different versions as
non-comparable without rebuilding.

## Integrations

### git pre-commit hook for manuscript repos

If you keep your prose in a git repo, the `integrations/git-hook/`
directory has a drop-in `pre-commit` hook that re-runs segman on every
commit and writes a sentence-per-line `<name>.segman` next to each
`<name>.manuscript`. The `.segman` file goes into the same commit, so
GitHub diffs (and any line-based diff tool) show you exactly which
sentences changed instead of highlighting whole paragraphs.

The hook downloads a precompiled `segman-cli` binary from the GitHub
Releases page on first run and caches it. No language runtime
required — works on a poet's laptop the same as a developer's.

See `integrations/git-hook/README.md` for install instructions.

## Building

```
./run-tests              # run all language test suites
./run-tests go           # one language

tools/scripts/build-clis.sh   # build CLI binaries into dist/
```

`dist/` is gitignored. Library consumers don't need this.

## Documentation

- `SPECS.md` — the segmentation rules, with examples.
- `AGENTS.md` — repo conventions for AI assistants editing this codebase.
- `DEVELOPMENT_NOTES.md` — open polish items (per-language examples/,
  godoc, etc.).
