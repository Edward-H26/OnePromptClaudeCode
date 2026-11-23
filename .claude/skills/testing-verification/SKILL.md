---
name: testing-verification
description: Verification protocol for finishing a change. Use before claiming any change done, when designing the tests of a change, when a check fails or flakes, and when reporting verification evidence.
---

# Testing and Verification

> **Related**: [website-workflow](../website-workflow/SKILL.md) for browser and UI verification. Source of the method: "How the Claude Code team thinks about verification" (claude.dev blog, 2026-11-16).

## Core rule

Done is proven by running the change on the path that ships, with evidence. Reading the diff proves nothing, and a passing unit test alone does not prove that a feature works.

## Which tests to invest in

1. **End-to-end**: drive the real flow (the command, the driver, the app, the exact file the user opens) and check the result the user sees. Use the project's `verify` skill when one exists; a project without one should get one that boots, drives and inspects the change in minutes.
2. **Property tests**: state what cannot break and let a library (Hypothesis, fast-check, proptest) search for a counterexample. Typical properties are round trips (encode then decode gives the input back), invariants (a budget never goes negative), idempotency (doing it twice equals doing it once) and equivalence (the optimized version equals a naive one).
3. **Differential tests**: when a change replaces existing behavior, run the old and the new on the same random or recorded inputs and compare. Normalize what does not matter and keep a written list of approved differences.

Unit tests support these three; they do not replace them.

## Order: cheap checks first

| Tier | What | When |
|---|---|---|
| 0, seconds | lint, types, import or collection, the tests of the changed code | after every change |
| 1, minutes | the end-to-end smoke run (`verify` skill) | before every delivery |
| 2, long | the full suite and slow statistical tests | once, on the integrated tree, before a push or release |

Run a tier only after the one before it passes. Do not run tier 2 after every change: it blocks shared test capacity and slows every agent.

## When a check fails

- Fix and rerun at most three rounds. A check still failing after the third round stops the work: report the failing output to the user.
- A flaky test is never rerun until it passes, padded with sleeps or retries, or skipped. Find the cause, or delete the test and write down why.
- A type or lint failure is fixed at its root cause, never suppressed.

## Keep the checks honest

- A change never edits the check that judges it. The done criteria and the checks come from the base, and a change to a check is a task of its own.
- A verdict holds only for the tree or file it ran on, named by its hash. Any later edit voids it, so verify the exact artifact that ships (the integrated tree, the file the user will submit).
- A new gate starts in observe mode, logging what it would block, before it enforces.
- A bug that a check should have caught becomes a diff-triggered checklist item (its trigger, its check, the incident behind it) once it has happened twice. Prune items that stop firing.

## Evidence to report

- Each check: the command, its exit code, the counts it printed, and the hash of the tree or file it ran on.
- What could not be run, and why.
- "Verified: none" when nothing ran.
- The delivery note and every drafted commit message state how the change was verified.
