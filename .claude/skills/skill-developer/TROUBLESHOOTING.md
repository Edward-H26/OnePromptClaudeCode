# Skill Activation Troubleshooting

## Skill suggestion does not appear

Check:

1. The skill name in `SKILL.md` matches the key in `skill-rules.json`
2. The prompt actually matches the configured keywords or intent patterns
3. `skill-activation-prompt.sh` can parse the JSON input
4. `jq` is installed, because the shell hook depends on it

Manual test:

```bash
echo '{"session_id":"debug","prompt":"debug this skill trigger"}' | \
  bash .claude/hooks/skill-activation-prompt.sh
```

## Trigger is too noisy

Check:

- generic keywords such as `fix`, `work`, or `system`
- regex patterns that are too broad
- missing `keywordExclusions`

Prefer narrower triggers over trying to suppress noise later.

## File-trigger expectations are wrong

Check:

- `fileTriggers.pathPatterns`
- `fileTriggers.pathExclusions`
- `fileTriggers.contentPatterns`

Also confirm which hook actually consumes that information in this repo. Do not assume a hidden PreToolUse guardrail exists.

## Hook docs do not match behavior

Check the real files:

```bash
ls .claude/hooks
sed -n '1,220p' .claude/hooks/skill-activation-prompt.sh
sed -n '1,220p' .claude/hooks/tsc-check.sh
sed -n '1,220p' .claude/hooks/workflow-step-tracker.sh
```

If documentation references `.ts` wrappers, root `settings.json`, or `.claude/hooks/state/`, update the docs.

## Settings path confusion

In this repo, the active project settings file is:

```text
.claude/settings.json
```

Point workflow docs at `.claude/settings.json`, not the ignored root `settings.json` runtime file.
