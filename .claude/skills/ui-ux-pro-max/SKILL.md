---
name: ui-ux-pro-max
description: AI-powered design intelligence with 67 UI styles, 161 color palettes, 57 font pairings, 99 UX guidelines, and 25 chart types across 15+ tech stacks. Use before building any UI to get design system recommendations, style selection, typography, and color decisions. Complements ui-styling (implementation) by providing design direction.
license: MIT
version: 2.5.0
author: NextLevelBuilder
---

# UI/UX Pro Max

Design intelligence toolkit providing searchable databases of UI styles, color palettes, font pairings, chart types, and UX guidelines. Uses a BM25 + regex hybrid search engine over curated CSV databases.

**Relationship to other skills:**
- `ui-ux-pro-max` provides **design decisions** (what to build, which style, which colors)
- `ui-styling` provides **implementation patterns** (how to build with shadcn/ui + Tailwind)
- `frontend-dev-guidelines` provides **code architecture** (React patterns, file structure)

## Prerequisites

Python 3.x (no external dependencies required).

## How to Use This Skill

| Scenario | Start From |
|----------|------------|
| New project or page | Step 1 (analyze) then Step 2 (design system) |
| New component | Step 3 (domain search: style, ux) |
| Choose style, color, or font | Step 2 (design system) |
| Review existing UI | Pre-Delivery Checklist below |
| Add charts or data viz | Step 3 (domain search: chart) |
| Stack best practices | Step 4 (stack search) |
| Improve or optimize UI | Step 3 (domain search: ux) |

## Workflow

### Step 1: Analyze User Requirements

Extract from the user request:
- **Product type**: SaaS, e-commerce, portfolio, healthcare, fintech, entertainment, tool
- **Target audience**: Consumer, enterprise, developer, creative professional
- **Style keywords**: glassmorphism, minimalism, brutalism, dark mode, vibrant, elegant
- **Tech stack**: React, Next.js, Vue, Svelte, Astro, Flutter, SwiftUI, etc.

### Step 2: Generate Design System (Required for New Projects)

Always start with `--design-system` for comprehensive recommendations with reasoning:

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system [-p "Project Name"]
```

This searches domains in parallel (product, style, color, landing, typography), applies reasoning rules from `ui-reasoning.csv`, and returns a complete design system: pattern, style, colors, typography, effects, and anti-patterns.

**Persist the design system for cross-session retrieval:**

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Project Name"
```

Creates `design-system/MASTER.md` (global source of truth) and optionally page-specific overrides:

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Project Name" --page "dashboard"
```

### Step 3: Domain Searches (Supplement as Needed)

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --domain <domain> [-n <max_results>]
```

| Domain | Use For | Example |
|--------|---------|---------|
| `product` | Product type patterns | `--domain product "saas enterprise"` |
| `style` | UI styles and effects | `--domain style "glassmorphism dark"` |
| `color` | Color palettes | `--domain color "fintech professional"` |
| `typography` | Font pairings with Google Fonts imports | `--domain typography "modern elegant"` |
| `chart` | Chart types and library recommendations | `--domain chart "real-time dashboard"` |
| `ux` | Best practices and anti-patterns | `--domain ux "animation accessibility"` |
| `landing` | Page structure and CTA strategies | `--domain landing "hero social-proof"` |
| `react` | React/Next.js performance | `--domain react "suspense memo rerender"` |
| `web` | App interface guidelines | `--domain web "touch targets safe areas"` |
| `prompt` | AI prompts and CSS keywords for a style | `--domain prompt "minimalism"` |

### Step 4: Stack-Specific Guidelines

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --stack <stack>
```

Available stacks: `html-tailwind` (default), `react`, `nextjs`, `astro`, `vue`, `nuxtjs`, `nuxt-ui`, `svelte`, `swiftui`, `react-native`, `flutter`, `shadcn`, `jetpack-compose`, `angular`, `laravel`, `threejs`

### Output Formats

```bash
# ASCII box (default, best for terminal)
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "fintech crypto" --design-system

# Markdown (best for documentation)
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "fintech crypto" --design-system -f markdown
```

## Rule Categories by Priority

| Priority | Category | Impact | Domain | Key Checks |
|----------|----------|--------|--------|------------|
| 1 | Accessibility | CRITICAL | `ux` | Contrast 4.5:1, alt text, keyboard nav, aria labels |
| 2 | Touch and Interaction | CRITICAL | `ux` | Min size 44x44px, 8px+ spacing, loading feedback |
| 3 | Performance | HIGH | `ux` | WebP/AVIF, lazy loading, CLS < 0.1 |
| 4 | Style Selection | HIGH | `style` | Match product type, consistency, SVG icons |
| 5 | Layout and Responsive | HIGH | `ux` | Mobile-first breakpoints, no horizontal scroll |
| 6 | Typography and Color | MEDIUM | `typography`, `color` | Base 16px, line-height 1.5, semantic tokens |
| 7 | Animation | MEDIUM | `ux` | Duration 150-300ms, motion conveys meaning |
| 8 | Forms and Feedback | MEDIUM | `ux` | Visible labels, error near field, progressive disclosure |
| 9 | Navigation | HIGH | `ux` | Predictable back, bottom nav 5 max, deep linking |
| 10 | Charts and Data | LOW | `chart` | Legends, tooltips, accessible colors |

## Pre-Delivery Checklist

Before delivering UI code:

**Visual Quality:**
- No emojis used as icons (use SVG/vector icons)
- Consistent icon family and style
- Semantic theme tokens used consistently (no hardcoded hex)
- Pressed states do not shift layout bounds

**Interaction:**
- All tappable elements provide pressed feedback (150-300ms)
- Touch targets meet minimum (44x44pt iOS, 48x48dp Android)
- Screen reader focus order matches visual order
- Disabled states visually clear and non-interactive

**Light/Dark Mode:**
- Primary text contrast 4.5:1+ in both modes
- Dividers and interaction states visible in both modes
- Both themes tested before delivery

**Layout:**
- Safe areas respected for headers, tab bars, bottom CTAs
- 4/8dp spacing rhythm maintained
- Verified on small phone, large phone, and tablet
- Long-form text measure readable on larger devices

**Accessibility:**
- All meaningful images/icons have accessibility labels
- Color is not the only indicator
- Reduced motion and dynamic text size supported

## Query Tips

- Use multi-dimensional keywords: `"entertainment social vibrant content-dense"` not just `"app"`
- Use `--design-system` first, then `--domain` to deep-dive specific dimensions
- Add `--stack <stack>` for implementation-specific guidance
- Re-run with different keywords if initial results do not match intent
