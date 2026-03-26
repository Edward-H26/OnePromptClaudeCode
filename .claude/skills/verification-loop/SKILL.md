---
name: verification-loop
description: A comprehensive 6-phase verification system for Claude Code sessions. Complements existing hooks (tsc-check, stop-build-check) by providing a manual "run all checks" workflow.
origin: ECC-adapted
---

# Verification Loop Skill

A comprehensive verification system for Claude Code sessions.

## When to Use

Invoke this skill:
- After completing a feature or significant code change
- Before creating a PR
- When you want to ensure quality gates pass
- After refactoring

## Verification Phases

### Phase 1: Build Verification
```bash
# TypeScript/JavaScript projects
npm run build 2>&1 | tail -20
pnpm build 2>&1 | tail -20

# Python projects
python -m py_compile main.py
python -m compileall src/ -q
```

If build fails, STOP and fix before continuing.

### Phase 2: Type Check
```bash
# TypeScript projects
npx tsc --noEmit 2>&1 | head -30

# Python projects
pyright . 2>&1 | head -30
mypy . 2>&1 | head -30
```

Report all type errors. Fix critical ones before continuing.

### Phase 3: Lint Check
```bash
# JavaScript/TypeScript
npm run lint 2>&1 | head -30

# Python
ruff check . 2>&1 | head -30
```

### Phase 4: Test Suite
```bash
# JavaScript/TypeScript
npm run test -- --coverage 2>&1 | tail -50

# Python
pytest --cov=mypackage --cov-report=term-missing 2>&1 | tail -50
```

Report:
- Total tests: X
- Passed: X
- Failed: X
- Coverage: X%

### Phase 5: Security Scan
```bash
# Check for hardcoded secrets
grep -rn "sk-" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | head -10
grep -rn "api_key\s*=" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | head -10

# Check for console.log (TypeScript/JavaScript)
grep -rn "console.log" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -10

# Check for print statements (Python)
grep -rn "^\s*print(" --include="*.py" src/ 2>/dev/null | head -10
```

### Phase 6: Diff Review
```bash
git diff --stat
git diff --name-only
```

Review each changed file for:
- Unintended changes
- Missing error handling
- Potential edge cases

## Output Format

After running all phases, produce a verification report:

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## Integration with Existing Hooks

This skill complements PostToolUse hooks but provides deeper verification:
- `tsc-check.sh` catches TypeScript errors immediately on file save
- `stop-build-check-enhanced.sh` runs build checks when stopping
- This skill provides a comprehensive manual verification across all phases
- Use this skill when you need a full quality gate check before submitting work
