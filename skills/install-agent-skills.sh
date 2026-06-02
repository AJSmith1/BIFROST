#!/bin/sh

set -eu

usage() {
    cat <<'USAGE'
Usage: skills/install-agent-skills.sh [--dry-run] [--codex-only] [--claude-only]

Symlink repo-owned skills into local Codex and Claude skill directories.

Options:
  --dry-run      Print actions without changing the filesystem.
  --codex-only   Install only into ${CODEX_HOME:-$HOME/.codex}/skills.
  --claude-only  Install only into ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills.
  -h, --help     Show this help.
USAGE
}

dry_run=0
install_codex=1
install_claude=1

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            dry_run=1
            ;;
        --codex-only)
            install_codex=1
            install_claude=0
            ;;
        --claude-only)
            install_codex=0
            install_claude=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
skill_name=julia-docstrings
source_path="$repo_root/skills/$skill_name"

if [ ! -d "$source_path" ]; then
    echo "Missing skill source: $source_path" >&2
    exit 1
fi

install_one() {
    label=$1
    base_dir=$2
    target_dir="$base_dir/skills"
    target_path="$target_dir/$skill_name"

    if [ "$dry_run" -eq 1 ]; then
        echo "[$label] mkdir -p $target_dir"
        echo "[$label] ln -s $source_path $target_path"
        return
    fi

    mkdir -p "$target_dir"

    if [ -L "$target_path" ]; then
        current=$(readlink "$target_path")
        if [ "$current" = "$source_path" ]; then
            echo "[$label] already installed: $target_path"
            return
        fi
        echo "[$label] refusing to replace existing symlink: $target_path -> $current" >&2
        exit 1
    fi

    if [ -e "$target_path" ]; then
        echo "[$label] refusing to overwrite existing path: $target_path" >&2
        exit 1
    fi

    ln -s "$source_path" "$target_path"
    echo "[$label] installed: $target_path -> $source_path"
}

if [ "$install_codex" -eq 1 ]; then
    install_one "codex" "${CODEX_HOME:-$HOME/.codex}"
fi

if [ "$install_claude" -eq 1 ]; then
    install_one "claude" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
fi
