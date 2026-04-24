# Development notes

Open polish items. Most are nice-to-haves rather than blockers.

## Per-language polish

### Go (`go/`)

- [x] Module path normalized to `github.com/slackwing/segman/go`.
- [x] Public `Version` constant exported.
- [ ] `go/examples/` with at least one runnable example.
- [ ] Add godoc comments on the public surface.

### JavaScript (`js/`)

- [x] Public `VERSION` constant exported.
- [x] Browser + Node export shape is consistent (`window.segman` namespace
      + top-level `segment` global; CommonJS via `module.exports`).
- [ ] `package.json` for the lib (today there is none — segman.js is
      consumed as a vendored file). Decide whether to publish to npm.
- [ ] If publishing: ESM build alongside CJS.
- [ ] `js/examples/` with at least one runnable example.
- [ ] JSDoc on the public surface.

### Rust (`rust/`)

- [x] `pub const VERSION: &str = env!("CARGO_PKG_VERSION")` — version
      sourced from Cargo.toml at compile time.
- [x] Crate version bumped to 1.0.0 to match the cross-language version.
- [ ] `rust/examples/` with at least one runnable example.
- [ ] Rustdoc on the public surface.
- [ ] Confirm the public API surface is what we want (no accidental
      `pub` on internals).

## Repo-wide

- [ ] CHANGELOG.md or per-release GitHub release notes.
- [ ] CI: run `./run-tests` on push (segmenter parity is currently
      enforced by hand only).
- [ ] Decide: are CLIs in `tools/scripts/build-clis.sh`'s output
      something a user would want pre-built and tagged in releases? For
      now they're build-on-demand only.

## Pre-commit hook

The old setup had a pre-commit hook that auto-bumped the patch version
and re-generated reference output when the segmenter changed. That
machinery isn't carried into this layout. Replacement: do the bump
manually via `tools/scripts/bump-version.sh`. If the auto-bump becomes
genuinely useful again, restore as a hook in `.git/hooks/pre-commit`.
