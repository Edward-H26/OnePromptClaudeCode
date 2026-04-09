function Resolve-ClaudeHome {
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $candidate = $scriptDir
    while ($candidate -ne [System.IO.Path]::GetPathRoot($candidate)) {
        if ((Test-Path "$candidate/hooks") -and (Test-Path "$candidate/skills")) {
            return $candidate
        }
        $candidate = Split-Path -Parent $candidate
    }
    $homeClaude = Join-Path $HOME ".claude"
    if (Test-Path $homeClaude) {
        return (Resolve-Path $homeClaude).Path
    }
    return ""
}

function Get-RepoCacheKey {
    param([string]$Repo = ".")
    if (-not $Repo) { $Repo = "." }
    $normalized = if ($Repo -eq ".") { "root" } else { $Repo }
    $safeName = $normalized -replace "[/\\]", "_" -replace "[^a-zA-Z0-9_.-]", "_"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Repo)
    $crc = 0xFFFFFFFF
    foreach ($b in $bytes) {
        $crc = $crc -bxor $b
        for ($i = 0; $i -lt 8; $i++) {
            if ($crc -band 1) { $crc = ($crc -shr 1) -bxor 0xEDB88320 } else { $crc = $crc -shr 1 }
        }
    }
    $checksum = ($crc -bxor 0xFFFFFFFF) -band 0xFFFFFFFF
    return "${safeName}-${checksum}"
}

function Get-RepoForFile {
    param([string]$FilePath)
    $projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
    $relativePath = $FilePath.Replace("$projectDir/", "").Replace("$projectDir\", "")
    $dirPath = Split-Path -Parent $relativePath
    while ($dirPath -and $dirPath -ne ".") {
        $fullPath = Join-Path $projectDir $dirPath
        if ((Test-Path "$fullPath/package.json") -or
            (Test-Path "$fullPath/tsconfig.json") -or
            (Test-Path "$fullPath/tsconfig.app.json") -or
            (Test-Path "$fullPath/tsconfig.build.json") -or
            (Test-Path "$fullPath/pyproject.toml") -or
            (Test-Path "$fullPath/setup.py") -or
            (Test-Path "$fullPath/requirements.txt") -or
            (Test-Path "$fullPath/go.mod") -or
            (Test-Path "$fullPath/Cargo.toml") -or
            (Test-Path "$fullPath/pom.xml") -or
            (Test-Path "$fullPath/build.gradle") -or
            (Test-Path "$fullPath/build.gradle.kts") -or
            (Test-Path "$fullPath/Gemfile") -or
            (Test-Path "$fullPath/Makefile") -or
            (Test-Path "$fullPath/.git")) {
            return $dirPath
        }
        $dirPath = Split-Path -Parent $dirPath
    }
    if ((Test-Path "$projectDir/package.json") -or
        (Test-Path "$projectDir/tsconfig.json") -or
        (Test-Path "$projectDir/pyproject.toml") -or
        (Test-Path "$projectDir/setup.py") -or
        (Test-Path "$projectDir/requirements.txt") -or
        (Test-Path "$projectDir/go.mod") -or
        (Test-Path "$projectDir/Cargo.toml") -or
        (Test-Path "$projectDir/pom.xml") -or
        (Test-Path "$projectDir/build.gradle") -or
        (Test-Path "$projectDir/build.gradle.kts") -or
        (Test-Path "$projectDir/Gemfile") -or
        (Test-Path "$projectDir/Makefile") -or
        (Test-Path "$projectDir/.git")) {
        return "."
    }
    return ""
}

function Get-TscCommand {
    param([string]$RepoPath)
    if (Test-Path "$RepoPath/tsconfig.app.json") {
        return "npx tsc --project tsconfig.app.json --noEmit"
    } elseif (Test-Path "$RepoPath/tsconfig.build.json") {
        return "npx tsc --project tsconfig.build.json --noEmit"
    } elseif (Test-Path "$RepoPath/tsconfig.json") {
        $content = Get-Content "$RepoPath/tsconfig.json" -Raw
        if ($content -match '"references"') {
            if (Test-Path "$RepoPath/tsconfig.src.json") {
                return "npx tsc --project tsconfig.src.json --noEmit"
            }
            return "npx tsc --build --noEmit"
        }
        return "npx tsc --noEmit"
    }
    return ""
}

function Test-TscCommand {
    param([string]$TscCmd)
    if (-not $TscCmd) { return $false }
    $allowedPattern = "^(npx\s+tsc|node_modules[\\/]\.bin[\\/]tsc|tsc)(\s+[a-zA-Z0-9_./:@%+=,-]+)*\s*$"
    if ($TscCmd -match "[;&|<>`\$\(\)]") { return $false }
    if ($TscCmd -notmatch $allowedPattern) { return $false }
    return $true
}
