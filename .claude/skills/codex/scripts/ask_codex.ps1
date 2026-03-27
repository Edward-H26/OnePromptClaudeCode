#!/usr/bin/env powershell

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$referenceScript = Join-Path $repoRoot "references\codex\scripts\ask_codex.ps1"

if (-not (Test-Path $referenceScript -PathType Leaf)) {
    Write-Error "[ERROR] Missing vendored Codex PowerShell bridge: $referenceScript"
    exit 1
}

& $referenceScript @args
exit $LASTEXITCODE
