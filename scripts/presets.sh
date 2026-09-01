#!/usr/bin/env bash
# presets.sh - manage shell config presets | just for fun I could have done it from quickshell directly =P
# Usage:
#   presets.sh --save <name> [description]
#   presets.sh --remove <name> [--online]
#   presets.sh --apply <name> [--online]

CONFIG_DIR="$HOME/.config/illogical-impulse"
CONFIG_FILE="$CONFIG_DIR/config.json"
LOCAL_PRESETS_DIR="$CONFIG_DIR/presets"
ONLINE_PRESETS_DIR="$HOME/.cache/quickshell/presets"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCHWALL="$SCRIPT_DIR/colors/switchwall.sh"

mkdir -p "$LOCAL_PRESETS_DIR" "$ONLINE_PRESETS_DIR"

action="$1"
shift

online=false
args=()
for arg in "$@"; do
    if [ "$arg" = "--online" ]; then
        online=true
    else
        args+=("$arg")
    fi
done

name="${args[0]}"
description="${args[1]}"

if [ -z "$name" ]; then
    echo "Error: missing preset name" >&2
    exit 1
fi

if $online; then
    PRESETS_DIR="$ONLINE_PRESETS_DIR"
else
    PRESETS_DIR="$LOCAL_PRESETS_DIR"
fi

case "$action" in
    --save)
        jq 'del(._presetMeta)' "$CONFIG_FILE" > "$PRESETS_DIR/${name}.json"
        if [ -n "$description" ]; then
            jq --arg desc "$description" '._presetMeta = {"description": $desc}' \
                "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
        fi
        ;;
    --remove)
        rm -f "$PRESETS_DIR/${name}.json"
        if $online; then
            rm -rf "$ONLINE_PRESETS_DIR/assets/${name}"
        fi
        ;;
    --apply)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi
        jq -s '.[0] * .[1] | del(._presetMeta)' "$CONFIG_FILE" "$preset_file" \
            > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        "$SWITCHWALL" --noswitch
        ;;
    *)
        echo "Error: unknown action: $action" >&2
        exit 1
        ;;
esac
