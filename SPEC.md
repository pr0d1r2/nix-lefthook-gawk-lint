# Flatten SPEC — nix-lefthook-gawk-lint

## Goal
Remove the `nix-dev-shell-agentic` flake input (and its transitive
explosion) from `flake.nix`, preserving the `lefthook-gawk-lint` package
output and keeping CI (`nix develop .#ci` + remote lefthook hooks) and bats
green.

## Before
- flake.lock: 59 nodes.
- Inputs: nixpkgs-lock, nixpkgs(follows), nix-dev-shell-agentic(flake).
- Outputs: packages.<sys>.default = lefthook-gawk-lint; devShells ci/default
  via nix-dev-shell-agentic.lib.mkShells.

## Consumption of the agentic devShell here
- `.envrc` = `use flake` → devShells.<sys>.default.
- CI (nix-lefthook-ci-action, default devshell=ci) enters
  `nix develop .#ci` and runs lefthook install / pre-commit / pre-push
  --all-files.
- lefthook.yml `remotes:` invoke wrapper binaries that must be on PATH in
  the ci shell: lefthook-{nixfmt,shellcheck,shfmt,statix,deadnix,
  nix-no-embedded-shell,bats-unit,yamllint,typos,trailing-whitespace,
  missing-final-newline,git-conflict-markers,editorconfig-checker,
  git-no-local-paths,file-size-check}; bare `bats` (bats-parse), bare
  `nix flake check` (nix-flake-check); plus lefthook, git, coreutils,
  parallel, gawk.
- bats unit tests need BATS_LIB_PATH + lefthook-gawk-lint on PATH.

NOTE vs statix template: gawk has TWO extra remotes — nix-lefthook-statix
and nix-lefthook-nix-no-embedded-shell — so 15 src leaves (statix used 13).

## Changes
### Inputs
Remove nix-dev-shell-agentic. Add `flake = false` `-src` inputs for each
sibling wrapper the remotes invoke (15 leaves). Result inputs: nixpkgs-lock,
nixpkgs(follows), + 15 flake=false leaves. No flake input → no dep-tree
explosion.

### packages (UNCHANGED logic)
packages.<sys>.default = writeShellApplication { name="lefthook-gawk-lint";
runtimeInputs=[pkgs.gawk]; text=readFile ./lefthook-gawk-lint.sh; }.

### devShells (plain mkShell)
lefthookWrappersFor helper (from proven tdd-order-bats/statix template:
bats-unit + file-size-check get special multi-input handling,
nix-no-embedded-shell gets SCANNER-prefix handling, rest via `wrap`).
batsWithLibsFor helper. ciCommon = [self pkg, batsWithLibs, bats, coreutils,
git, lefthook, nix, parallel, gawk] ++ wrappers.
- ci = mkShell { packages = ciCommon; BATS_LIB_PATH = "${batsWithLibs}/share/bats"; }
- default = mkShell { packages = ciCommon; shellHook = dev.sh expanded; }

### Side changes possibly required to land green
1. config/lefthook/file_size_limits.yml: nix 4096 → 10240 (flattened flake.nix grows with 15 inline wrappers; proven template repos use nix:10240). Pure config, no logic.
2. lefthook-gawk-lint.sh: reformat 4-space → 2-space (shfmt remote main now defaults to `-i 2`). Whitespace-only; wrapper behavior identical.

## Validation gate (all must pass)
1. nix flake check — PASS.
2. nix flake show — packages.<sys>.default = lefthook-gawk-lint; devShells ci+default UNCHANGED.
3. nix build .#default + smoke (no-arg → 0, clean awk → 0, bad awk → 1).
4. bats tests/unit/ inside nix develop .#ci — PASS.
5. lefthook run pre-commit --all-files inside .#ci — PASS.
6. lock nodes << 59.

## Then
Branch flatten-drop-agentic, commit, push, DRAFT PR.
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
