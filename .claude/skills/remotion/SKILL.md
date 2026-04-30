---
name: remotion
description: Active-mode skill for programmatic video creation with Remotion. Use when the user wants to scaffold a Remotion project, create a composition, render a video, or animate frames using React components. Triggers on keywords like "remotion", "render video", "composition", "create-video", or file patterns like *Composition*.tsx.
---

# Remotion

Active-mode skill for creating videos programmatically with Remotion, the React-based video framework. Claude scaffolds, edits, and renders video projects without asking per-step, subject to the workspace's `careful` and `freeze` safety boundaries.

## Mode

This skill operates in **active mode**. When triggered with a clear intent, Claude runs the matching command directly without asking per step:

| User intent (any phrasing) | Authorized command (Claude runs it) |
|---|---|
| "scaffold", "create a new video project", "bootstrap" | `npx create-video@latest video/<name> --template blank` then `cd video/<name> && npm install` |
| "write a composition", "add a scene", "animate X" | Write/Edit `src/*.tsx` directly, register in `src/Root.tsx` |
| "preview", "open the studio", "see it live" | `cd video/<name> && npm start` (Remotion Studio on :3000) |
| "render", "export", "build the video" | `cd video/<name> && npm run build` |
| "generate Veo clips", "use Veo", "make it with real footage" | `cd video/<name> && npm run veo` |
| **"render with Veo"**, "build:veo", "generate + render", "the full pipeline" | **`cd video/<name> && npm run build:veo`** (runs the Veo generator, then the full render) |

Claude pauses and asks only for:

- Destructive actions: deleting a project folder, overwriting an existing MP4 that was produced by a user-run command, `rm -rf`
- Expensive actions without clear cost consent: kicking off a Veo render when `GEMINI_API_KEY` is not set, or when the user has not specified the project folder
- Actions that would breach an active `freeze` boundary

Safety is provided by the workspace `careful` / `freeze` boundaries and `settings.json` allow/ask/deny lists, not by per-step prompts inside this skill.

## Prerequisites

- Node.js 18+ (verified on this workspace at v24.7.0)
- ffmpeg on PATH (verified at `/opt/homebrew/bin/ffmpeg`)
- Chrome / Chromium (auto-installed by Remotion on first render)

## When to Invoke

- "Create a video that shows X"
- "Scaffold a Remotion project"
- "Render a 10-second intro with fade-in text"
- "Generate a data-driven animation from this CSV"
- File triggers: `*/remotion/*`, `*Composition*.tsx`, `remotion.config.ts`

## Project Layout Convention

New video projects scaffold at `<cwd>/video/<name>/`. The `/video/` directory is gitignored by this workspace so node_modules and rendered MP4s never pollute the public surface.

```
video/
  demo/
    src/
      Composition.tsx
      Root.tsx
      index.ts
    out/
    remotion.config.ts
    package.json
```

## Quick Workflows

### Scaffold a new video project

```bash
cd <cwd>
npx create-video@latest video/<name> --template blank
cd video/<name>
npm install
```

`--template blank` is the non-interactive shorthand. Other useful templates: `hello-world`, `audiogram`, `still-images`, `prompt-to-video`.

### Run the live preview server

```bash
cd video/<name>
npx remotion preview
```

Opens http://localhost:3000 with a React-based live preview.

### Render a composition

```bash
cd video/<name>
npx remotion render <CompositionId> out/<name>.mp4
```

Common flags:
- `--codec h264` (default), `vp8`, `vp9`, `prores`, `gif`
- `--frames 0-149` render a specific range
- `--concurrency auto` or a number of workers
- `--scale 0.5` only for fast preview iteration — omit for production renders

## Composition Primer

Every video is a React component that receives the current frame. Minimal example:

```tsx
import { AbsoluteFill, useCurrentFrame, interpolate } from "remotion";

export function Intro() {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ backgroundColor: "black", justifyContent: "center", alignItems: "center" }}>
      <h1 style={{ color: "white", opacity, fontSize: 96 }}>Hello Remotion</h1>
    </AbsoluteFill>
  );
}
```

Register in `src/Root.tsx`:

```tsx
import { Composition } from "remotion";
import { Intro } from "./Intro";

export const RemotionRoot = () => (
  <Composition id="Intro" component={Intro} durationInFrames={150} fps={30} width={1920} height={1080} />
);
```

## AI-Generated Media

### MCP servers (no auth, enabled by default)

Two MCP servers are declared in `.claude/settings.local.example.json` and should be copied into `.claude/settings.local.json` on first use:

| MCP | Purpose | Auth |
|---|---|---|
| `remotion-docs` (`@remotion/mcp`) | Official Remotion docs indexed for AI lookup | none |
| `remotion-app` (`remotion-mcp-server`) | Interactive live-preview composition builder | none |

To activate on a fresh machine:

```bash
cp .claude/settings.local.example.json .claude/settings.local.json
# restart Claude Code so the MCP servers boot
```

### Veo video generation via direct Gemini API

Veo 3.1 is Google's text-to-video model, producing ~8-second clips **with synchronized native audio** (dialogue, ambient, music, SFX). It is accessed directly through the Gemini REST API at `https://generativelanguage.googleapis.com/v1beta/models/{MODEL_ID}:predictLongRunning`.

**Preview endpoints were deprecated on 2026-04-02**. Use the GA `-001` model IDs below, selectable via the `VEO_MODEL` env var (default is the best-quality model):

| Model ID | When to use | Approx cost | Quality |
|---|---|---|---|
| `veo-3.1-generate-001` (default) | Best overall quality, hero renders, pitch decks | ~$0.35/sec | #1 on MovieGenBench and VBench (early 2026) |
| `veo-3.1-fast-generate-001` | Faster iteration, social clips, drafts | ~50% of standard | Slightly lower than standard |
| `veo-3.1-lite-generate-001` | Budget-sensitive batches, 720p/1080p only (no 4K) | Lowest | 54.6% win-rate vs Fast |

The skill ships with `video/demo/scripts/generate-veo.mjs` which:

- Reads `GEMINI_API_KEY` from environment
- Submits one or more prompts to the configured model (`VEO_MODEL` override supported)
- Polls the long-running operation until each clip completes (typically 11 s to 6 min per clip, up to `maxMinutes=7` deadline)
- Downloads each MP4 to `video/demo/public/clips/`
- Writes a manifest at `video/demo/public/clips/manifest.json` that the Remotion composition reads at render time to decide whether to render a scene as a Veo clip or an animated fallback

Override examples:
```bash
VEO_MODEL=veo-3.1-fast-generate-001 npm run veo
VEO_MODEL=veo-3.1-lite-generate-001 npm run veo
```

### Where to put `GEMINI_API_KEY`

Pick ONE of these patterns, in order of increasing security:

1. **Shell rc file** (quickest):
   ```bash
   echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.zshrc
   source ~/.zshrc
   ```

2. **Project-local `.env.local`** (scoped to this repo, gitignored via `*.local`):
   ```bash
   echo 'GEMINI_API_KEY=your-key-here' >> .env.local
   # load before running scripts: set -a; source .env.local; set +a
   ```

3. **macOS Keychain + shell rc lookup** (most secure):
   ```bash
   security add-generic-password -s "GEMINI_API_KEY" -a "$USER" -w "your-key-here"
   echo 'export GEMINI_API_KEY="$(security find-generic-password -s GEMINI_API_KEY -w)"' >> ~/.zshrc
   source ~/.zshrc
   ```

4. **direnv** (per-directory env):
   ```bash
   echo 'export GEMINI_API_KEY="your-key-here"' >> .envrc
   direnv allow
   ```

Verify the key is live in the current shell with `echo "${GEMINI_API_KEY:0:8}..."` before running Veo scripts.

## Repo Rules

- Scaffolded projects go under `<cwd>/video/` which is gitignored
- Do not commit rendered MP4s
- Do not run `npx remotion render` without first verifying `remotion.config.ts` and the referenced composition ID exist
- Respect the active `freeze` boundary: do not scaffold or render outside the frozen directory
- Production renders run at full composition resolution (no `--scale` flag). Use `--scale 0.5` only for fast iteration smoke tests.

## Troubleshooting

- **"Cannot find Chrome"**: run `npx remotion browser` to install the headless browser
- **Render hangs**: lower `--concurrency` to 2 or 4
- **ffmpeg not found**: already verified at `/opt/homebrew/bin/ffmpeg` on this workspace
- **Interactive template picker blocks automation**: always pass `--template <id>` explicitly
- **Port 3000 in use**: `npx remotion preview --port 3001`

## External Resources

- [Remotion docs](https://www.remotion.dev/docs/)
- [Remotion + Claude Code guide](https://www.remotion.dev/docs/ai/claude-code)
- [Official Remotion Agent Skills](https://www.remotion.dev/docs/ai/skills)
