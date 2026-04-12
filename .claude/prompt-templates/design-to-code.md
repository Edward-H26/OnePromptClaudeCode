# Design-to-Code Template

## How to Use

Copy this into Claude Code and replace the placeholders.

```text
[FIGMA_URL]: Optional Figma file or node URL.
[DESIGN_DESCRIPTION]: What the UI should look like and do.
[DIRECTORY]: Project root.
[TARGET_STACK]: Target stack, such as "React + Tailwind".
[DESIGN_SYSTEM]: Existing tokens, components, or style system.
```

## Execution Prompt

You are implementing a design in **[DIRECTORY]**.

- Figma: [FIGMA_URL]
- Design brief: [DESIGN_DESCRIPTION]
- Target stack: [TARGET_STACK]
- Existing design system: [DESIGN_SYSTEM]

## Workflow

### 1. Inspect the Existing Surface

1. Apply `search-first` before adding new components or tokens.
2. Read the existing layout, component, and styling patterns first.
3. If a runnable UI exists, inspect it in browser tooling before editing.

### 2. Capture the Design

1. If `[FIGMA_URL]` is present, use the installed Figma tooling to inspect the relevant nodes and screenshots.
2. If no Figma file exists, work from `[DESIGN_DESCRIPTION]` and the current design system.
3. If no design system exists yet, use `ui-ux-pro-max` to generate one:
   ```bash
   python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system -p "Project Name"
   ```
4. For specific design decisions (style, color, typography), run targeted domain searches:
   ```bash
   python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain style
   python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain color
   python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain typography
   ```
5. Reuse existing tokens, components, and layout primitives before adding new ones.

### 3. Implement

1. Use `frontend-dev-guidelines` for application structure.
2. Use `ui-styling` for styling, responsive behavior, and accessibility.
3. Use `ui-ux-pro-max` for stack-specific best practices: `--stack <target_stack>`.
4. Use the `frontend-design` plugin only when the task truly needs stronger visual direction.
5. For multi-screen or complex component implementations, use `/super-ralph` to autonomously build, test, and integrate each piece.
6. Keep the implementation scoped to the described screen, component, or flow.

### 4. Verify

1. Run the smallest useful build, type, lint, and test checks for the touched UI surface.
2. Use browser tooling to compare the result against the design intent.
3. If the UI change is substantial, use `/design-review` or `/qa`.
4. Report the visual result, checks run, and any remaining gaps.

## Rules

- Match the requested design intent, but do not invent extra screens or flows.
- Reuse the existing project design system before creating new tokens or components.
- Do not commit, push, or create a PR.
