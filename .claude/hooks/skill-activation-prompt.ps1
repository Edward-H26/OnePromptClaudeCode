$input = [Console]::In.ReadToEnd()
$data = $input | ConvertFrom-Json
$prompt = $data.prompt

if (-not $prompt) { exit 0 }

$promptLower = $prompt.ToLower()

. "$PSScriptRoot/lib/utils.ps1"
$claudeHome = Resolve-ClaudeHome
$rulesPath = Join-Path $claudeHome "skills/skill-rules.json"

if (-not (Test-Path $rulesPath)) { exit 0 }

$rules = Get-Content $rulesPath -Raw | ConvertFrom-Json
$skillMatches = @()

foreach ($skill in $rules.skills.PSObject.Properties) {
    $name = $skill.Name
    $val = $skill.Value
    if (-not $val.promptTriggers) { continue }

    $keywords = $val.promptTriggers.keywords
    $patterns = $val.promptTriggers.intentPatterns
    $excludeKeywords = $val.promptTriggers.keywordExclusions
    $matched = $false

    foreach ($kw in $keywords) {
        $escaped = [regex]::Escape($kw.ToLower())
        $wordPattern = "(^|[^a-zA-Z0-9_])" + $escaped + "([^a-zA-Z0-9_]|$)"
        if ($promptLower -match $wordPattern) {
            $matched = $true
            break
        }
    }
    if (-not $matched -and $patterns) {
        foreach ($pat in $patterns) {
            try {
                if ($promptLower -match $pat) { $matched = $true; break }
            } catch {}
        }
    }

    if ($val.alwaysActive -eq $true) { $matched = $true }

    if ($matched -and $excludeKeywords) {
        foreach ($ek in $excludeKeywords) {
            $escapedEk = [regex]::Escape($ek.ToLower())
            $ekPattern = "(^|[^a-zA-Z0-9_])" + $escapedEk + "([^a-zA-Z0-9_]|$)"
            if ($promptLower -match $ekPattern) {
                $matched = $false
                break
            }
        }
    }

    if ($matched) {
        $priority = if ($val.priority) { $val.priority } else { "medium" }
        $skillMatches += [PSCustomObject]@{ Priority = $priority; Name = $name }
    }
}

if ($skillMatches.Count -eq 0) { exit 0 }

$critical = ($skillMatches | Where-Object { $_.Priority -eq "critical" } | ForEach-Object { "  -> $($_.Name)" }) -join "`n"
$high = ($skillMatches | Where-Object { $_.Priority -eq "high" } | ForEach-Object { "  -> $($_.Name)" }) -join "`n"
$medium = ($skillMatches | Where-Object { $_.Priority -eq "medium" } | ForEach-Object { "  -> $($_.Name)" }) -join "`n"
$low = ($skillMatches | Where-Object { $_.Priority -eq "low" } | ForEach-Object { "  -> $($_.Name)" }) -join "`n"

$output = @()
$output += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$output += "SKILL ACTIVATION CHECK"
$output += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$output += ""
if ($critical) { $output += "CRITICAL SKILLS (REQUIRED):"; $output += $critical; $output += "" }
if ($high) { $output += "RECOMMENDED SKILLS:"; $output += $high; $output += "" }
if ($medium) { $output += "SUGGESTED SKILLS:"; $output += $medium; $output += "" }
if ($low) { $output += "OPTIONAL SKILLS:"; $output += $low; $output += "" }
$output += "ACTION: Use Skill tool BEFORE responding"
$output += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$output -join "`n"
