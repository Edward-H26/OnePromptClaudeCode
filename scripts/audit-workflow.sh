#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

source ".claude/hooks/lib/patterns.sh"
source ".claude/hooks/lib/utils.sh"
source ".claude/hooks/lib/plugin-state.sh"
source ".claude/hooks/lib/runtime-state.sh"
source "$ROOT/scripts/lib/audit-helpers.sh"
source "$ROOT/scripts/lib/audit-steps.sh"

echo "[1/11] Shell syntax"
auditShellSyntax

echo "[2/11] Symlink integrity"
auditSymlinkIntegrity

echo "[3/11] Hook script path resolution"
python3 "$ROOT/scripts/lib/audit-hook-paths.py"

echo "[4/11] JSON parse and skill inventory"
python3 "$ROOT/scripts/lib/audit-inventory.py"

echo "[5/11] Hook prompt classification, cache-key safety, and helper smokes"
auditHookSmokes

echo "[6/11] Local stale-reference scan"
python3 "$ROOT/scripts/lib/audit-stale-refs.py"

echo "[7/11] Plugin alignment and public surface"
auditPluginAlignment
python3 "$ROOT/scripts/lib/audit-plugins.py"

echo "[8/11] Secret-pattern scan on public surface"
python3 "$ROOT/scripts/lib/audit-secrets.py"

echo "[9/11] Ignored sensitive-state summary"
python3 "$ROOT/scripts/lib/audit-ignored.py"

echo "[10/11] Public surface summary"
python3 "$ROOT/scripts/lib/audit-surface.py"

echo "[11/11] Cross-validation summary"
python3 -c "
from pathlib import Path
root = Path('.')
skills = {p.name for p in (root / '.claude' / 'skills').iterdir() if (p.is_dir() or p.is_symlink()) and (p / 'SKILL.md').exists()}
agents = {p.stem for p in (root / '.claude' / 'agents').glob('*.md') if p.name != 'README.md'}
commands = {p.stem for p in (root / '.claude' / 'commands').glob('*.md') if p.name != 'README.md'}
hooks = list((root / '.claude' / 'hooks').glob('*.sh'))
templates = {p.stem for p in (root / '.claude' / 'prompt-templates').glob('*.md') if p.name != 'README.md'}
print(f'  Skills: {len(skills)}, Agents: {len(agents)}, Commands: {len(commands)}, Hooks: {len(hooks)}, Templates: {len(templates)}')
"

echo "Workflow audit passed."
