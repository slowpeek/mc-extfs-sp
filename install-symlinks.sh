#!/bin/sh

SELF_PATH=$(dirname "$(readlink -f "$0")")

extfs_d=~/.local/share/mc/extfs.d
[ -d "$extfs_d" ] || mkdir -p "$extfs_d"

report() {
    printf '%12s  %s\n' "$script" "$1"
}

error=error:
[ -t 1 ] && error=$(printf '\e[31m%s\e[m' "$error")

for path in "$SELF_PATH"/*/*-sp; do
    [ -f "$path" -a -x "$path" ] || continue

    script=${path##*/}
    if [ -h "$extfs_d/$script" ]; then
        ln -sf "$path" "$extfs_d"
        report 'update existing symlink'
    else
        if [ -e "$extfs_d/$script" ]; then
            report "$error exists already, not a symlink"
            continue
        fi

        ln -s "$path" "$extfs_d"
        report 'create symlink'
    fi
done
