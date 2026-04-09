---
name: autoresearch
description: Autonomous ML research loop based on Karpathy's autoresearch. Iteratively modifies train.py, runs 5-minute training sessions, evaluates val_bpb improvements, and keeps or discards changes via local snapshots. Use when user wants to run autonomous ML experiments.
---

# Autoresearch Skill

Autonomous ML research loop. Modify train.py, train, evaluate, keep or discard, repeat.

## Setup

Before starting, verify the workspace exists:

```bash
ls <workspace>/train.py <workspace>/prepare.py
```

If missing, run the setup script:

```bash
bash "~/.claude/skills/autoresearch/scripts/setup.sh" --workspace <workspace>
```

## The Experiment Loop

For each turn, execute this exact cycle:

### Step 1: Read Current State

```bash
cd <workspace>
mkdir -p .autoresearch/checkpoints .autoresearch/accepted
tail -20 results.tsv
cat train.py
```

Review prior experiments in results.tsv. Identify what worked, what failed, and what remains unexplored relative to the research goal.

### Step 2: Form Hypothesis

Based on the goal, prior results, and current train.py state, decide what to try next. Consider:

- **If risk = conservative**: Small hyperparameter tweaks, minor architectural adjustments
- **If risk = medium**: Moderate changes like new activation functions, learning rate schedules, layer configurations
- **If risk = aggressive**: Major rewrites like new optimizers, fundamentally different architectures, novel training techniques

**Focus area** constrains what you modify:
- `architecture`: Model structure (layers, attention, MLP, normalization)
- `optimizer`: Optimizer algorithm, learning rates, schedules, weight decay
- `hyperparams`: Batch size, depth, aspect ratio, window patterns
- `data`: Data loading, packing, sequence length, tokenization
- `all`: Anything in train.py is fair game

### Step 3: Edit train.py

Make the experimental change. Only modify `train.py`. Never modify `prepare.py`.

Keep changes focused: one hypothesis per experiment. Do not bundle multiple unrelated changes.

### Step 4: Snapshot

Create a local checkpoint before running:

```bash
cd <workspace>
TURN_ID="turn-<N>"
cp train.py ".autoresearch/checkpoints/${TURN_ID}-before.py"
```

### Step 5: Run Training

```bash
cd <workspace> && uv run train.py > run.log 2>&1
```

This takes approximately 5 minutes (300 seconds). Wait for completion.

If the run exceeds 10 minutes, kill it:
```bash
pkill -f "train.py"
```

### Step 6: Extract Results

```bash
grep "^val_bpb:\|^peak_vram_mb:\|^training_seconds:\|^total_tokens_M:\|^num_steps:" <workspace>/run.log
```

If output is empty (crash), read the error:
```bash
tail -50 <workspace>/run.log
```

### Step 7: Decide Keep or Discard

Extract the val_bpb value and compare to the previous best.

**KEEP** if:
- val_bpb improved by at least `min_improvement` (default 0.001)
- OR val_bpb is equal/slightly worse but the code is significantly simpler

**DISCARD** if:
- val_bpb is worse
- val_bpb improved by less than `min_improvement` and the change adds complexity
- The run crashed

**On crash**: If the fix is trivial (typo, missing import), fix and rerun. If the idea is fundamentally broken, log as crash and move on.

To discard:
```bash
cd <workspace> && cp ".autoresearch/checkpoints/${TURN_ID}-before.py" train.py
```

### Step 8: Log Results

Append to results.tsv:

```bash
cd <workspace>
printf "%s\t%s\t%s\t%s\t%s\n" "$TURN_ID" "<val_bpb>" "<peak_vram_gb>" "<keep|discard|crash>" "<description>" >> results.tsv
```

If the run is a keep, also persist the accepted version:

```bash
cd <workspace> && cp train.py ".autoresearch/accepted/${TURN_ID}.py"
```

### Step 9: Report Progress

After each turn, output a brief status:

```
Turn N: <description>
  val_bpb: <value> (prev best: <value>, delta: <+/- value>)
  Status: KEEP / DISCARD / CRASH
  Running best: <best val_bpb so far>
```

Every `report_every` turns, output a summary table of all experiments.

### Step 10: Loop

If turns remaining > 0 (or unlimited), go to Step 1.

When all turns are complete, output the final report.

## Final Report Format

```markdown
# Autoresearch Report
Goal: <research goal>
Turns: <N completed>
Best val_bpb: <value> (improved from <baseline> by <delta>)

## Experiment Log
| # | Turn | val_bpb | VRAM (GB) | Status | Description |
|---|--------|---------|-----------|--------|-------------|
| 1 | turn-1 | 0.9979 | 44.0 | keep | baseline |
| 2 | turn-2 | 0.9932 | 44.2 | keep | increase matrix LR |
...

## Key Findings
- <What worked and why>
- <What did not work>
- <Remaining opportunities>
```

## Rules

1. **Never stop to ask permission during the loop.** The user may be away. Continue autonomously.
2. **Never modify prepare.py.** Only train.py is fair game.
3. **One change per experiment.** Isolate variables for clear attribution.
4. **Log everything.** Every experiment goes in results.tsv, even crashes.
5. **Simplicity wins.** Equal results with simpler code is a keep.
6. **Respect VRAM constraints.** If max_vram is set, estimate memory impact before trying large model changes.
7. **Local snapshots are your safety net.** Always snapshot before running. Always restore on discard.
