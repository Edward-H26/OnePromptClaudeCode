#!/usr/bin/env powershell

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$referenceScript = Join-Path $repoRoot "references\codex\scripts\ask_codex.ps1"

if (-not $env:CLAUDE_PROJECT_DIR) {
    $env:CLAUDE_PROJECT_DIR = $repoRoot
}

if (-not $env:AUTO_CODEX_HOME) {
    $env:AUTO_CODEX_HOME = Join-Path $repoRoot ".claude\runtime\codex\home"
}

if (-not $env:AUTO_CODEX_RUNTIME_DIR) {
    $env:AUTO_CODEX_RUNTIME_DIR = Join-Path $repoRoot ".claude\runtime\codex\runs"
}

if (-not (Test-Path $referenceScript -PathType Leaf)) {
    Write-Error "[ERROR] Missing vendored Codex PowerShell bridge: $referenceScript"
    exit 1
}

& $referenceScript @args
exit $LASTEXITCODE
