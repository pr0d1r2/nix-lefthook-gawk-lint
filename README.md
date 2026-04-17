# nix-lefthook-gawk-lint

[![CI](https://github.com/pr0d1r2/nix-lefthook-gawk-lint/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-gawk-lint/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [gawk --lint](https://www.gnu.org/software/gawk/) wrapper, packaged as a Nix flake.

Filters `.awk` files from staged arguments and runs gawk parse-time lint on them. Exits 0 when no matching files are found.

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just the wrapper binary in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-gawk-lint
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-gawk-lint = {
  url = "github:pr0d1r2/nix-lefthook-gawk-lint";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-gawk-lint.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    gawk-lint:
      glob: "*.awk"
      run: timeout ${LEFTHOOK_GAWK_LINT_TIMEOUT:-30} lefthook-gawk-lint {staged_files}
```

### Configuring timeout

The default timeout is 30 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_GAWK_LINT_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-gawk-lint  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT
