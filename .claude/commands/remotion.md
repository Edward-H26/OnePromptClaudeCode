---
description: Scaffold, edit, or render a Remotion video project in active mode
argument-hint: "Instruction, e.g., 'scaffold a 30-second product demo' or 'render the Intro composition as MP4'"
---

Route the instruction in `$ARGUMENTS` to the Remotion active-mode skill.

## Decision Tree

1. **Scaffold intent** ("scaffold", "create", "new project", "bootstrap")
   - Target folder: `video/<name>/` under current working directory
   - Run: `npx create-video@latest video/<name> --template blank`
   - `cd video/<name> && npm install`
   - Confirm `src/Root.tsx` exists; report project path

2. **Composition-authoring intent** ("add a scene", "create an intro", "animate X")
   - Verify a Remotion project exists under `./video/` or the current project root
   - Write the new `.tsx` component in `src/`
   - Register it in `src/Root.tsx` via `<Composition id=... component=... />`
   - Optionally run render as a smoke test

3. **Render intent** ("render", "export", "output the video")
   - Verify the project path and composition ID
   - Run: `cd video/<name> && npm run build` (or `npx remotion render <CompositionId> out/<filename>.mp4` if the npm script is not defined)
   - Verify the MP4 was created, report path + file size

4. **Veo-only intent** ("generate Veo clips", "make the scenes")
   - Pre-check: `test -n "$GEMINI_API_KEY"`; stop and ask the user to export the key if missing
   - Run: `cd video/<name> && npm run veo`
   - Report: number of clips generated, manifest path, any failed clips

5. **Full-pipeline intent** ("render with Veo", "build:veo", "generate + render", "the full pipeline")
   - Pre-check: `test -n "$GEMINI_API_KEY"`; stop and ask if missing
   - Pre-check: a Remotion project exists under `./video/<name>/` with the `build:veo` script in `package.json`
   - Run: `cd video/<name> && npm run build:veo`
   - This chains the Veo generator then the full render — typical wall time 15–30 min at `veo-3.1-generate-001`
   - Verify the MP4 was created, report path + file size + manifest status

## Safety

- Never overwrite an existing `video/<name>/` without explicit confirmation
- Never delete rendered MP4s without explicit confirmation
- Respect any active `freeze` boundary
- Abort if `/careful` is active and the render flag set includes destructive options

## Deliverable

Final report must include:
- Project path (if scaffolded)
- Composition name(s) touched
- Render output path and file size (if rendered)
- Any error that blocked completion, with the exact command and error text
