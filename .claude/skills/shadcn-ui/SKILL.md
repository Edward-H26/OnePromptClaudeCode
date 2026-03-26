---
name: shadcn-ui
description: Deep knowledge of shadcn/ui components, patterns, theming, and CLI. Detects project config via components.json, enforces composition patterns, and uses registry for component discovery.
---

# shadcn/ui Skill

Provides deep knowledge of shadcn/ui components, patterns, and best practices.

## Activation

This skill activates when a `components.json` file is found in the project, or when the user asks about shadcn/ui, Tailwind components, or UI component libraries.

## Project Context

On activation, run:
```bash
npx shadcn info --json 2>/dev/null || echo "No shadcn config found"
```

This returns: framework, Tailwind version, path aliases, base library (radix or base), icon library, installed components, and resolved paths.

## CLI Commands

| Command | Purpose |
|---|---|
| `npx shadcn init` | Initialize shadcn/ui in a project |
| `npx shadcn add <component>` | Add a component |
| `npx shadcn search <query>` | Search available components |
| `npx shadcn view <component>` | View component source |
| `npx shadcn docs <component>` | Open component documentation |
| `npx shadcn diff` | Show changes since last install |
| `npx shadcn build` | Build registry artifacts |

## Patterns

- Use FieldGroup for forms, ToggleGroup for options.
- Use semantic color variables (not raw hex).
- Use OKLCH color system for theming.
- Follow composition patterns: compound components, slots, variants via `class-variance-authority`.
- Check installed components before suggesting new ones.
- Use `--dry-run` flag when previewing changes.

## Theming

- CSS variables define colors, spacing, radii.
- Dark mode via `.dark` class or `data-theme="dark"`.
- Custom color palettes via OKLCH values.
- Tailwind v3 and v4 both supported.

## When to use

- Building UI components in React + Tailwind projects.
- When `components.json` exists in the project.
- User asks about shadcn, radix, or Tailwind component patterns.
