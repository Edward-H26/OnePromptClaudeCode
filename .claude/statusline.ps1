$input = [Console]::In.ReadToEnd()
$data = $input | ConvertFrom-Json

$cwd = if ($data.workspace) { $data.workspace.current_dir } else { $null }
if (-not $cwd) { $cwd = $data.cwd }
$dir = if ($cwd) { Split-Path -Leaf $cwd } else { "" }
$model = if ($data.model) { if ($data.model.display_name) { $data.model.display_name } else { $data.model.id } } else { "" }
$used = if ($data.context_window) { $data.context_window.used_percentage } else { $null }
$style = if ($data.output_style) { $data.output_style.name } else { $null }
$rate5h = if ($data.rate_limits -and $data.rate_limits.five_hour) { $data.rate_limits.five_hour.used_percentage } else { $null }
$rate7d = if ($data.rate_limits -and $data.rate_limits.seven_day) { $data.rate_limits.seven_day.used_percentage } else { $null }

$branch = ""
try { $branch = git -C $cwd --no-optional-locks rev-parse --abbrev-ref HEAD 2>$null } catch {}

$parts = @()
if ($dir) { $parts += "`e[0;34m${dir}`e[0m" }
if ($branch) { $parts += "`e[0;33m(${branch})`e[0m" }
if ($model) { $parts += "`e[0;36m${model}`e[0m" }
if ($style) { $parts += "`e[0;32m${style}`e[0m" }
if ($used) { $usedInt = [math]::Round($used); $parts += "`e[0;35mctx:${usedInt}%`e[0m" }
if ($rate5h) { $r5 = [math]::Round($rate5h); $parts += "`e[0;33m5h:${r5}%`e[0m" }
if ($rate7d) { $r7 = [math]::Round($rate7d); $parts += "`e[0;31m7d:${r7}%`e[0m" }

$parts -join " "
