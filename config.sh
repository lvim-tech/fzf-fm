#!/usr/bin/env bash

CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/config"
# CONFIG_FILE="$HOME/.config/lvim-fm/config"

if [[ -f "$CONFIG_FILE" ]]; then
	source "$CONFIG_FILE"
else
	echo "Configuration file not found: $CONFIG_FILE"
	exit 1
fi

builtin cd "$1" || return

mkdir -p "$LVIM_FM_WORKING_DIR"
chmod 777 "$LVIM_FM_WORKING_DIR"

echo "$PWD" >"$LVIM_FM_WORKING_DIR/base-directory"

if [[ -f $LVIM_FM_WORKING_DIR/pwd ]]; then
	builtin cd "$(cat "$LVIM_FM_WORKING_DIR/pwd")" || return
fi

# if [[ $(cat "$LVIM_FM_WORKING_DIR/mode") == EXECUTE/* ]]; then
#     echo "SELECT" >"$LVIM_FM_WORKING_DIR/mode"
# fi

if [[ ! -f $LVIM_FM_WORKING_DIR/action ]]; then
	echo "menu" >"$LVIM_FM_WORKING_DIR/action"
fi

if [[ ! -f $LVIM_FM_WORKING_DIR/mode ]]; then
	echo "SELECT" >"$LVIM_FM_WORKING_DIR/mode"
fi

cat /dev/null >"$LVIM_FM_WORKING_DIR"/mode-items
