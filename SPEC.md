# SPEC — nix-lefthook-gawk-lint

## §G Goal

Lefthook-compatible `gawk --lint` wrapper. Run gawk parse-time lint on every
`.awk` file staged for commit or pushed, blocking the operation when any file
fails to parse cleanly. Packaged as a Nix flake `writeShellApplication`.
Opensource-safe: zero credentials, zero local paths, zero private refs.

## §C Constraints

- C1: Pure bash — only `gawk` as a runtime dependency, no Python/Ruby/etc
- C2: Nix flake — `writeShellApplication` pkg, plain `mkShell` devShells
- C3: MIT license
- C4: Multi-platform: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`,
  `aarch64-linux`
- C5: Detached from parent project — no credential leaks, no hardcoded local
  paths, no private repo refs
- C6: Config via env var — `LEFTHOOK_GAWK_LINT_TIMEOUT` only, no config files
- C7: Exit non-zero when any `.awk` file fails `gawk --lint` — hard
  enforcement, blocks commit and push
- C8: Flattened inputs — `flake = false` `-src` inputs plus `nixpkgs-lock`,
  no `nix-dev-shell-agentic`, no transitive flake dep-tree explosion

## §I Interfaces

- I.cli: `lefthook-gawk-lint <file>...` — main binary; filters args to
  existing `*.awk` files, runs `gawk --lint -f <file> </dev/null` on each;
  exit 1 if any fails (blocks operation), exit 0 otherwise
- I.env: `LEFTHOOK_GAWK_LINT_TIMEOUT` (seconds, default `30`) — wraps the
  binary in `timeout` inside `lefthook.yml` / `lefthook-remote.yml`
- I.remote: `lefthook-remote.yml` — consumers add as a lefthook remote;
  defines `pre-commit` and `pre-push` `gawk-lint` commands globbed to `*.awk`
- I.flake: `packages.${system}.default` — the `lefthook-gawk-lint` Nix pkg
- I.devshell: `devShells.${system}.default` + `.#ci` — dev/CI shells; both
  carry the pkg, bats-with-libs, and the bundled lefthook wrapper suite
- I.ci: `.github/workflows/ci.yml` — linux + macos via
  `nix-lefthook-ci-action` (enters `.#ci`, runs lefthook install +
  pre-commit + pre-push `--all-files`)
- I.pins: `.github/workflows/update-pins.yml` — scheduled `nix flake update
  nixpkgs-lock` + auto PR

## §V Invariants

- V1: Each existing `*.awk` argument is checked with `gawk --lint`; exit 1 if
  any file fails to parse — hard requirement, blocks commit and push
- V2: No-argument invocation exits 0 immediately (lefthook passes empty file
  lists when nothing matches the glob)
- V3: Non-`.awk` arguments are filtered out before linting — mixed input
  succeeds when every `.awk` file passes
- V4: Missing file paths are skipped silently — `[ -f "$f" ]` guard, no crash
- V5: Lint runs with stdin redirected from `/dev/null` and stdout discarded —
  only the parse-time exit status and stderr diagnostics matter
- V6: Any single failing file makes the whole batch fail — `status=1` latches
  across the loop, the failing path is printed to stderr
- V7: `LEFTHOOK_GAWK_LINT_TIMEOUT` bounds each hook run via `timeout`
  (default 30s) in both `lefthook.yml` and `lefthook-remote.yml`
- V8: Hook script is sourced by `writeShellApplication` — no shebang, no `set`
  line in `lefthook-gawk-lint.sh`; the wrapper supplies `set -euo pipefail`
- V9: No credentials, secrets, tokens, API keys, or private paths in any
  tracked file
- V10: No hardcoded local filesystem paths (enforced by the
  `nix-lefthook-git-no-local-paths` hook)
- V11: `dev.sh` exports `BATS_LIB_PATH` from the `@BATS_LIB_PATH@` placeholder
  and runs `lefthook install` only when `.git/hooks/pre-commit` is missing
- V12: `flake.nix` carries the lefthook wrapper suite inline via
  `lefthookWrappersFor` — `lefthook-bats-unit` and `lefthook-file-size-check`
  get multi-input handling, `lefthook-nix-no-embedded-shell` gets the
  `SCANNER` prefix, the rest go through the `wrap` helper
- V13: Both devShells share `ciCommon` (pkg, bats-with-libs, bats, coreutils,
  gawk, git, lefthook, nix, parallel, wrappers); `.#ci` sets `BATS_LIB_PATH`,
  `.#default` expands `dev.sh` as its `shellHook`
- V14: CI runs both pre-commit and pre-push on linux + macos; macOS is gated
  to `push` / `workflow_dispatch` events
- V15: All linters pass: nixfmt, shellcheck, shfmt, statix, deadnix,
  nix-no-embedded-shell, bats-parse, bats-unit, yamllint, nix-flake-check,
  typos, trailing-whitespace, missing-final-newline, git-conflict-markers,
  editorconfig-checker, git-no-local-paths, file-size-check
- V16: `config/lefthook/file_size_limits.yml` raises the `nix` limit to 10240
  so the flattened `flake.nix` (15 inline wrappers) stays under the cap
- V17: Inputs are flattened — `nixpkgs-lock` + `nixpkgs` (follows) + 15
  `flake = false` `-src` leaves, no `nix-dev-shell-agentic` flake input

## §T Tasks

| id | status | task | cites |
| -- | ------ | ---- | ----- |
| T1 | x | core wrapper: filter `*.awk` args, `gawk --lint` each, exit 1 on any failure | V1,V3,V4,V5,V6,I.cli |
| T2 | x | no-arg / no-match fast path → exit 0 | V2,I.cli |
| T3 | x | source-only script shape for `writeShellApplication` (no shebang/set) | V8,C1 |
| T4 | x | timeout env config in lefthook.yml + lefthook-remote.yml | V7,I.env,I.remote |
| T5 | x | Nix flake pkg (`writeShellApplication`, runtimeInputs = gawk) | C1,C2,I.flake |
| T6 | x | flattened inputs: nixpkgs-lock + 15 flake=false leaves, no agentic | C8,V17 |
| T7 | x | inline lefthook wrapper suite via lefthookWrappersFor | V12,V15 |
| T8 | x | devShells .#ci + .#default sharing ciCommon | V13,I.devshell |
| T9 | x | dev.sh — BATS_LIB_PATH placeholder + conditional lefthook install | V11 |
| T10 | x | lefthook-remote.yml for consumers (pre-commit + pre-push) | I.remote |
| T11 | x | unit tests: lefthook-gawk-lint.bats (7 tests, assert_failure on bad awk) | V1,V2,V3,V4,V6 |
| T12 | x | unit tests: dev.bats (3 tests) | V11 |
| T13 | x | GitHub Actions CI: linux + macos via nix-lefthook-ci-action | V14,I.ci |
| T14 | x | update-pins workflow: scheduled nixpkgs-lock update + auto PR | I.pins |
| T15 | x | linter suite via lefthook remotes | V15 |
| T16 | x | file_size_limits.yml: nix → 10240 for flattened flake.nix | V16 |
| T17 | x | opensource audit: no credentials/local-paths/private-refs tracked | V9,V10,C5 |
| T18 | x | .gitignore: `result`, `result-*`, `.direnv` | V9,C5 |
