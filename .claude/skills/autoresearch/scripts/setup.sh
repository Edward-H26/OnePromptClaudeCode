#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/karpathy/autoresearch.git"
DEFAULT_WORKSPACE="$HOME/autoresearch"

usage() {
    cat <<'USAGE'
Usage: setup.sh [options]

Sets up the autoresearch environment by cloning the repo and installing dependencies.

Options:
    --workspace <path>   Directory to clone into (default: ~/autoresearch)
    --skip-data          Skip data download and tokenizer training
    -h, --help           Show this help
USAGE
}

workspace="$DEFAULT_WORKSPACE"
skip_data=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workspace) workspace="${2:-}"; shift 2 ;;
        --skip-data) skip_data=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "[ERROR] Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [[ -d "$workspace/.git" ]]; then
    echo "autoresearch repo already exists at $workspace"
    echo "Pulling latest changes..."
    git -C "$workspace" pull --ff-only 2>/dev/null || echo "Pull skipped (may have local changes)"
else
    echo "Cloning autoresearch into $workspace..."
    git clone "$REPO_URL" "$workspace"
fi

cd "$workspace"

if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "Installing Python dependencies..."
uv sync

if [[ "$skip_data" == "false" ]]; then
    echo "Running prepare.py (downloading data and training tokenizer)..."
    echo "This may take a while on first run."
    uv run python prepare.py
else
    echo "Skipping data download (--skip-data)"
fi

if [[ ! -f "results.tsv" ]]; then
    printf "turn\tval_bpb\tmemory_gb\tstatus\tdescription\n" > results.tsv
    echo "Created results.tsv"
fi

mkdir -p ".autoresearch/checkpoints" ".autoresearch/accepted"

echo ""
echo "Setup complete at: $workspace"
echo "Ready to run /autoresearch"
