#!/usr/bin/env bash
set -euo pipefail

print_usage() {
    cat <<'EOF'
Usage: bash .claude/skills/web-artifacts-builder/scripts/init.sh <project-name> [--skip-install]
EOF
}

project_name=""
skip_install="false"

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            print_usage
            exit 0
            ;;
        --skip-install)
            skip_install="true"
            ;;
        *)
            if [[ -n "$project_name" ]]; then
                echo "Only one project name is supported." >&2
                exit 1
            fi
            project_name="$arg"
            ;;
    esac
done

if [[ -z "$project_name" ]]; then
    print_usage >&2
    exit 1
fi

if [[ -e "$project_name" ]]; then
    echo "Target already exists: $project_name" >&2
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

package_name="$(printf "%s" "$project_name" | tr "[:upper:]" "[:lower:]" | tr -cs "a-z0-9" "-")"
package_name="${package_name#-}"
package_name="${package_name%-}"

if [[ -z "$package_name" ]]; then
    package_name="artifact-app"
fi

mkdir -p "$project_name/src"

cat > "$project_name/.gitignore" <<'EOF'
node_modules
dist
bundle.html
EOF

cat > "$project_name/package.json" <<EOF
{
  "name": "$package_name",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@tailwindcss/vite": "^4.1.2",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "@vitejs/plugin-react": "^4.3.4",
    "tailwindcss": "^4.1.2",
    "typescript": "^5.8.3",
    "vite": "^5.4.19"
  }
}
EOF

cat > "$project_name/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["DOM", "DOM.Iterable", "ES2020"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src"],
  "references": []
}
EOF

cat > "$project_name/vite.config.ts" <<'EOF'
import { fileURLToPath, URL } from "node:url";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url))
    }
  }
});
EOF

cat > "$project_name/index.html" <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Artifact App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

cat > "$project_name/src/main.tsx" <<'EOF'
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
EOF

cat > "$project_name/src/App.tsx" <<'EOF'
export default function App() {
  return (
    <main className="min-h-screen bg-zinc-950 px-6 py-16 text-zinc-50">
      <div className="mx-auto flex max-w-5xl flex-col gap-10">
        <section className="grid gap-6 rounded-3xl border border-white/10 bg-white/5 p-8 shadow-2xl shadow-black/20 backdrop-blur">
          <span className="w-fit rounded-full border border-emerald-400/30 bg-emerald-400/10 px-3 py-1 text-sm font-medium text-emerald-200">
            Artifact Starter
          </span>
          <div className="grid gap-4">
            <h1 className="max-w-3xl text-4xl font-semibold tracking-tight text-white sm:text-6xl">
              Build a shareable React artifact, then inline it into one HTML file.
            </h1>
            <p className="max-w-2xl text-base leading-7 text-zinc-300 sm:text-lg">
              Edit <code className="rounded bg-white/10 px-2 py-1 text-sm">src/App.tsx</code>, run the bundle helper, and ship the generated <code className="rounded bg-white/10 px-2 py-1 text-sm">bundle.html</code>.
            </p>
          </div>
        </section>

        <section className="grid gap-4 rounded-3xl border border-white/10 bg-zinc-900/80 p-8">
          <h2 className="text-2xl font-semibold text-white">Starter checklist</h2>
          <ul className="grid gap-3 text-zinc-300">
            <li>Adjust the title, copy, and layout for the actual artifact.</li>
            <li>Keep assets local so the bundler can inline them.</li>
            <li>Run the bundle helper from the project root after each major change.</li>
          </ul>
        </section>
      </div>
    </main>
  );
}
EOF

cat > "$project_name/src/index.css" <<'EOF'
@import "tailwindcss";

:root {
  color-scheme: dark;
  font-family: "Instrument Sans", "Segoe UI", sans-serif;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
  background: #09090b;
}

code {
  font-family: "IBM Plex Mono", "SFMono-Regular", monospace;
}
EOF

if [[ "$skip_install" == "false" ]]; then
    (
        cd "$project_name"
        npm install
    )
fi

printf "Created %s\n" "$project_name"
