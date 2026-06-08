#!/usr/bin/env bash
set -euo pipefail

# Safely merge .claude/settings.local.example.json into .claude/settings.local.json.
# Rules:
#   - User's existing values WIN on conflict (example is fill-in only)
#   - New top-level blocks (like mcpServers) get added if not present
#   - Always writes a timestamped backup before replacing
#   - Shows the diff before applying unless --yes is used

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE="${REPO_ROOT}/.claude/settings.local.example.json"
ACTIVE="${REPO_ROOT}/.claude/settings.local.json"
AUTO_APPLY=false

for arg in "$@"; do
  case "$arg" in
    --yes|--auto|--apply)
      AUTO_APPLY=true
      ;;
    --help|-h)
      cat <<EOF
Usage: $0 [--yes]

Options:
  --yes, --auto, --apply   Merge non-interactively
  --help                   Show this help
EOF
      exit 0
      ;;
    *)
      echo "error: unknown argument: ${arg}" >&2
      exit 1
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [[ ! -f "${EXAMPLE}" ]]; then
  echo "error: ${EXAMPLE} does not exist" >&2
  exit 1
fi

if [[ ! -f "${ACTIVE}" ]]; then
  echo "note: ${ACTIVE} does not exist yet. Copying example verbatim."
  cp "${EXAMPLE}" "${ACTIVE}"
  echo "created: ${ACTIVE}"
  exit 0
fi

# jq -s '.[0] * .[1]' does a RECURSIVE deep merge where the right file wins on conflict.
# We pass example first, active second, so existing user values override example defaults.
merged="$(jq -s '.[0] * .[1]' "${EXAMPLE}" "${ACTIVE}")"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
printf "%s\n" "${merged}" > "${tmp}"

if [[ ! -s "${tmp}" ]]; then
  echo "error: merged output is empty (likely jq failure). aborting." >&2
  exit 1
fi

if cmp -s "${ACTIVE}" "${tmp}"; then
  echo "up to date: ${ACTIVE}"
  exit 0
fi

echo ""
echo "=== diff (active -> merged) ==="
diff -u "${ACTIVE}" "${tmp}" || true
echo "=== end diff ==="
echo ""

if [[ "${AUTO_APPLY}" == true ]]; then
  reply="y"
else
  read -r -p "Apply this merge? (y/N) " reply
fi

if [[ "${reply}" =~ ^[Yy]$ ]]; then
  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup="${ACTIVE}.bak.${timestamp}"
  cp "${ACTIVE}" "${backup}"
  echo "backup: ${backup}"
  mv "${tmp}" "${ACTIVE}"
  trap - EXIT
  echo "merged: ${ACTIVE}"
  echo "rollback with: mv ${backup} ${ACTIVE}"
else
  echo "aborted. no changes made."
fi
