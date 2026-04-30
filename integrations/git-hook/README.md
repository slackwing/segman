# segman pre-commit hook

A drop-in git hook that keeps a `<name>.segman` file (one sentence per
line) next to every `<name>.manuscript` in your repo. It re-runs on
every commit that touches a `.manuscript`, so the `.segman` file is
always up to date.

Why? Diffs of paragraph-level prose are painful to review — a one-word
edit can highlight the entire paragraph. With sentence-per-line files
checked in alongside the manuscript, GitHub (and any line-based diff
tool) shows you exactly which sentences changed.

## Install

In your manuscript repo:

```sh
mkdir -p .githooks
curl -fsSL \
  https://github.com/slackwing/segman/raw/v1.1.0/integrations/git-hook/pre-commit \
  -o .githooks/pre-commit
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
git add .githooks/pre-commit
```

Commit `.githooks/pre-commit` so collaborators inherit the hook on
clone. Each collaborator runs `git config core.hooksPath .githooks`
once per clone — git intentionally won't auto-install hooks (security).

## What happens on commit

1. The hook scans the staged file list for any `*.manuscript`.
2. For each one, it runs `segman-cli <file>` and writes the output to
   `<name>.segman` next to the manuscript.
3. It `git add`s the `.segman` file so it's part of the same commit.

The first commit on a fresh machine downloads the matching
`segman-cli-<os>-<arch>` binary from this repo's GitHub Releases into
`~/.cache/segman/<version>/`. ≈3 MB. Subsequent commits use the cached
binary — no network.

If anything fails (download, segman crash), the commit is aborted with
a clear message. To bypass deliberately (e.g. while offline):

```sh
git commit --no-verify
```

## Versioning

The hook is pinned to a specific segman version via `SEGMAN_VERSION` at
the top of the file. To upgrade:

1. Edit `SEGMAN_VERSION` in `.githooks/pre-commit` to the new tag.
2. Commit. The next commit will download the new binary.

Re-segmenting an existing manuscript file with a new segman version
will regenerate its `.segman` and stage the diff — review it the same
way you'd review any other change.

## Supported platforms

- macOS (Apple Silicon and Intel)
- Linux (x86_64, ARM64)
- Windows (x86_64, via Git Bash / MSYS / WSL)

If your platform isn't on the list, either build segman from source
(see the segman repo's README) and put the binary in the cache dir
manually, or open an issue.
