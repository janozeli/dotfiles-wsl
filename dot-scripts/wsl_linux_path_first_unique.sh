#!/usr/bin/env bash

wsl_linux_path_first_unique() {
    emulate -L zsh 2>/dev/null || return 0

    local -a linux win new
    local -A seen
    linux=(); win=(); new=()
    seen=()

    local p
    for p in $path; do
        [[ -z "$p" ]] && continue
        [[ "$p" != "/" ]] && p="${p%/}"

        if [[ "$p" == /mnt/[a-zA-Z]/* ]]; then
            win+=("$p")
        else
            linux+=("$p")
        fi
    done

    for p in "${linux[@]}" "${win[@]}"; do
        [[ -z "$p" ]] && continue
        if [[ -z "${seen[$p]}" ]]; then
            new+=("$p")
            seen[$p]=1
        fi
    done

    path=("${new[@]}")
    hash -r 2>/dev/null
}

if (return 0 2>/dev/null); then
    :
else
    wsl_linux_path_first_unique
fi
