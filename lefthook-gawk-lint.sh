# shellcheck shell=bash
# Lefthook-compatible gawk --lint wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
    exit 0
fi

files=()
for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
        *.awk) files+=("$f") ;;
    esac
done

if [ ${#files[@]} -eq 0 ]; then
    exit 0
fi

status=0
for f in "${files[@]}"; do
    if ! gawk --lint -f "$f" </dev/null >/dev/null; then
        printf 'lefthook-gawk-lint: %s failed gawk --lint\n' "$f" >&2
        status=1
    fi
done
exit "$status"
