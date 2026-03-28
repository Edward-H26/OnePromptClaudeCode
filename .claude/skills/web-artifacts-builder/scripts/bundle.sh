#!/usr/bin/env bash
set -euo pipefail

print_usage() {
    cat <<'EOF'
Usage: bash .claude/skills/web-artifacts-builder/scripts/bundle.sh
Run this from the artifact project root.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    print_usage
    exit 0
fi

if [[ ! -f "package.json" || ! -f "index.html" ]]; then
    echo "Run this from the artifact project root." >&2
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    echo "node is required." >&2
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required." >&2
    exit 1
fi

if [[ ! -d "node_modules" ]]; then
    npm install
fi

npm run build

node <<'EOF'
import fs from "node:fs/promises";
import path from "node:path";

const distDir = path.resolve("dist");
const htmlPath = path.join(distDir, "index.html");
let html = await fs.readFile(htmlPath, "utf8");

async function replaceAsync(source, pattern, replacer) {
  let result = "";
  let lastIndex = 0;

  for (const match of source.matchAll(pattern)) {
    const index = match.index ?? 0;
    result += source.slice(lastIndex, index);
    result += await replacer(match);
    lastIndex = index + match[0].length;
  }

  result += source.slice(lastIndex);
  return result;
}

function resolveAsset(assetPath) {
  return path.join(distDir, assetPath.replace(/^\/+/, ""));
}

html = html.replace(/<link[^>]+rel="modulepreload"[^>]*>\s*/g, "");

html = await replaceAsync(
  html,
  /<link[^>]+rel="stylesheet"[^>]+href="([^"]+)"[^>]*>\s*/g,
  async (match) => {
    const css = await fs.readFile(resolveAsset(match[1]), "utf8");
    return `<style>\n${css}\n</style>\n`;
  }
);

html = await replaceAsync(
  html,
  /<script[^>]+type="module"[^>]+src="([^"]+)"[^>]*><\/script>\s*/g,
  async (match) => {
    const js = await fs.readFile(resolveAsset(match[1]), "utf8");
    return `<script type="module">\n${js}\n</script>\n`;
  }
);

await fs.writeFile("bundle.html", html);
EOF

printf "Wrote %s\n" "$(pwd)/bundle.html"
