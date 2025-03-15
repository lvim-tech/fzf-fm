#!/usr/bin/env bash

function execute {
    local items=$1
    local command=$2

    if [[ $command = "copy" ]]; then
        for item in $items; do
            if [[ -d "$item" ]]; then
                cp -R "$item" .
            elif [[ -f "$item" ]]; then
                cp "$item" .
            fi
        done
    elif [[ $command = "cut" ]]; then
        for item in $items; do
            if [[ -d "$item" ]]; then
                mv "$item" .
            elif [[ -f "$item" ]]; then
                mv "$item" .
            fi
        done
    elif [[ $command = "delete" ]]; then
        for item in $items; do
            if [[ -d "$item" ]]; then
                rm -rf "$item"
            elif [[ -f "$item" ]]; then
                rm "$item"
            fi
        done
    fi
}

function process_copy {
    execute "$selected" copy
    cat /dev/null >"$LVIM_FM_WORKING_DIR"/mode-items
    echo 'SELECT' >"$LVIM_FM_WORKING_DIR"/mode
}

function process_cut {
    execute "$selected" cut
    cat /dev/null >"$LVIM_FM_WORKING_DIR"/mode-items
    echo 'SELECT' >"$LVIM_FM_WORKING_DIR"/mode
}

function process_delete {
    execute "$selected" delete
    cat /dev/null >"$LVIM_FM_WORKING_DIR"/mode-items
    echo 'SELECT' >"$LVIM_FM_WORKING_DIR"/mode
}

function print_pre_process {
    cat "$LVIM_FM_WORKING_DIR"/mode-items
}
