---
name: security-scan
description: Scan Claude Code configuration (.claude/ directory) for security vulnerabilities, misconfigurations, and injection risks. Uses AgentShield when available, otherwise provides a manual checklist.
origin: ECC-adapted
---

# Security Scan Skill

Audit your Claude Code configuration for security issues.

**See Also**: `security-review` skill for reviewing application code security (OWASP, injection, auth, secrets) rather than Claude Code configuration.

## When to Activate

- Setting up a new Claude Code project
- After modifying `settings.json`, `CLAUDE.md`, or MCP configs
- Before committing configuration changes
- When onboarding to a new repository with existing Claude Code configs
- Periodic security hygiene checks

## What to Scan

| File | Checks |
|------|--------|
| `CLAUDE.md` | Hardcoded secrets, auto-run instructions, prompt injection patterns |
| `settings.json` | Overly permissive allow lists, missing deny lists, dangerous bypass flags |
| `mcp.json` | Risky MCP servers, hardcoded env secrets, npx supply chain risks |
| `hooks/` | Command injection via interpolation, data exfiltration, silent error suppression |
| `agents/*.md` | Unrestricted tool access, prompt injection surface, missing model specs |

## Option A: AgentShield (Automated)

If AgentShield is installed:

```bash
npx ecc-agentshield --version

npm install -g ecc-agentshield

npx ecc-agentshield scan
npx ecc-agentshield scan --path /path/to/.claude
npx ecc-agentshield scan --min-severity medium
npx ecc-agentshield scan --format json
npx ecc-agentshield scan --fix
```

### Severity Grades

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | Secure configuration |
| B | 75-89 | Minor issues |
| C | 60-74 | Needs attention |
| D | 40-59 | Significant risks |
| F | 0-39 | Critical vulnerabilities |

## Option B: Manual Security Checklist

When AgentShield is not available, audit manually:

### settings.json Audit
- [ ] No `Bash(*)` in the allow list (unrestricted shell access)
- [ ] No overly broad patterns like `Bash(osascript:*)` or `Bash(open:*)`
- [ ] Deny list includes dangerous commands: `rm -rf /`, `curl | bash`, etc.
- [ ] MCP server commands do not contain hardcoded secrets
- [ ] `npx -y` auto-install entries reviewed for supply chain risk

### CLAUDE.md Audit
- [ ] No hardcoded API keys, tokens, or passwords
- [ ] No instructions that auto-execute dangerous commands
- [ ] No prompt injection vectors (e.g., "ignore previous instructions")
- [ ] Git restrictions properly configured (no auto-commit/push)

### Hooks Audit
- [ ] No `${file}` or `${input}` interpolation in shell commands (injection risk)
- [ ] No `2>/dev/null` or `|| true` that silently swallows errors
- [ ] No data exfiltration (curl/wget to external URLs with local data)
- [ ] All hook scripts have appropriate permissions (not world-writable)

### Agents Audit
- [ ] No agents with unrestricted Bash access
- [ ] Agent prompts and tool scopes are limited to what they need
- [ ] No prompt injection surface in agent descriptions

### MCP Servers Audit
- [ ] No shell-running MCP servers without justification
- [ ] Environment variables used for secrets (not inline in config)
- [ ] Transport methods reviewed (stdio vs HTTP security tradeoffs)

## Interpreting Results

### Critical (fix immediately)
- Hardcoded API keys or tokens in config files
- `Bash(*)` in the allow list
- Command injection in hooks via variable interpolation
- Shell-running MCP servers without access controls

### High (fix before production)
- Auto-run instructions in CLAUDE.md
- Missing deny lists in permissions
- Agents with unnecessary Bash access

### Medium (recommended)
- Silent error suppression in hooks
- Missing validation around sensitive hook or permission changes
- `npx -y` auto-install in MCP configs

### Info (awareness)
- Missing descriptions on MCP servers
- Unused or orphaned configuration entries
