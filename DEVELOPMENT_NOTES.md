# Development notes

Carried-over open items from earlier dev journals (PLAN_V3.md and
SUMMARY.md, both deliberately not migrated). Most are "polish before
external consumers care" — useful reading if you're touching the
relevant area.

## Per-language polish

### Go (`exports/lib/segman-go/`)

- [ ] Verify Go module structure is correct for external `go get`.
- [ ] Confirm `go.mod` is configured for the public import path
      (`github.com/slackwing/segman/...` once the repo layout settles).
- [ ] Add `func Version() string` exported publicly (today it's only
      used internally).
- [ ] `go/examples/` with at least one runnable example.
- [ ] Add godoc comments on the public surface.

### JavaScript (`exports/lib/segman-js/`)

- [ ] Add `package.json` (today there is none — segman.js is consumed
      as a vendored file).
- [ ] Decide on `module.exports` vs ESM. CommonJS is fine for
      vendor-by-copy; ESM matters if/when this is published.
- [ ] Export `getVersion()` from the public surface.
- [ ] JSDoc on the public surface.
- [ ] `js/examples/` with at least one runnable example.

### Rust (`exports/lib/segman-rust/`)

- [ ] Verify `Cargo.toml` has correct library configuration for
      external use.
- [ ] Add `pub fn version() -> &'static str`.
- [ ] Confirm public API surface is what we want (no accidental
      `pub` on internal items).
- [ ] Rustdoc on the public surface.
- [ ] `rust/examples/` with at least one runnable example.
- [ ] Decide whether the `segment-manuscript` binary stays in this
      crate or moves to a separate CLI crate.

## Build / release

- [ ] Decide on a versioned-release process beyond just bumping
      `VERSION.json` (tags? a changelog? a release script?).
- [ ] Pre-commit hook auto-staging policy for VERSION.json bumps.

## Phase 6 (deep refactor) candidates

These came up during the manuscript-studio vendoring extraction and
deserve their own pass:

- [ ] Flatten the `src/` + `exports/lib/` split. Today the source
      lives in `src/segman/{go,js,rust}` and the build output is
      copied to `exports/lib/segman-{go,js,rust}`. For a library
      repo, having those be the same directory (or having `lib/`
      be the source-of-truth) is more conventional and less
      confusing for consumers.
- [ ] README.md at repo root with install + usage + version policy.
- [ ] Per-language `CHANGELOG.md` or a single root one — pick one.
