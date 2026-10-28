<#
bootstrap.ps1 — make this project self-sufficient on Windows.
Idempotent, prints every action, never needs admin rights, logs what it could not do.

  powershell -ExecutionPolicy Bypass -File scripts\bootstrap.ps1
  powershell -ExecutionPolicy Bypass -File scripts\bootstrap.ps1 -Yes
  powershell -ExecutionPolicy Bypass -File scripts\bootstrap.ps1 -TexOnly
  powershell -ExecutionPolicy Bypass -File scripts\bootstrap.ps1 -NoSkills -NoPython
#>
param(
  [switch]$Yes,
  [switch]$TexOnly,
  [switch]$NoSkills,
  [switch]$NoPython
)

$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$TexMf = Join-Path $Root 'texmf\tex\latex\local'
$BstDir = Join-Path $Root 'texmf\bibtex\bst\local'
$Log = Join-Path $Root 'research\.state\bootstrap.log'
New-Item -ItemType Directory -Force -Path $TexMf, $BstDir, (Split-Path $Log) | Out-Null

function Log([string]$msg) {
  $line = "{0} | {1}" -f (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'), $msg
  Add-Content -Path $Log -Value $line
  Write-Host $msg
}
function Have([string]$cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Fetch([string]$url, [string]$dest) {
  try {
    # Invoke-WebRequest is always present on Windows; no curl dependency.
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 60
    return $true
  } catch {
    Log "FAIL download $url — $($_.Exception.Message)"
    return $false
  }
}

$ctan = 'https://mirrors.ctan.org/macros/latex/contrib/IEEEtran'

$needTex = -not (Test-Path (Join-Path $TexMf 'IEEEtran.cls'))

$plan = @()
if ($needTex) { $plan += 'fetch IEEEtran.cls + IEEEtran.bst from CTAN into texmf/' }
if (-not $TexOnly) {
  if (-not $NoSkills) {
    $plan += "install humanizer skill: npx skills add blader/humanizer --agent '*'"
    $plan += 'clone diagram-design into vendor/diagram-design (gitignored)'
  }
  if (-not $NoPython) { $plan += 'pip install --user cairosvg (SVG→PDF for figures)' }
}

if ($plan.Count -eq 0) { Write-Host 'nothing to do — toolchain already complete'; Log 'noop'; exit 0 }

Write-Host "bootstrap plan for $Root"
$plan | ForEach-Object { Write-Host "  - $_" }

if (-not $Yes) {
  $ans = Read-Host 'Proceed? [y/N]'
  if ($ans -notmatch '^(y|yes)$') { Log 'aborted by user'; exit 0 }
}

$failures = 0

# 1. IEEEtran from CTAN (no admin rights, goes into ./texmf)
if ($needTex) {
  if (Fetch "$ctan/IEEEtran.cls" (Join-Path $TexMf 'IEEEtran.cls')) { Log 'OK IEEEtran.cls' } else { $failures++; Log 'FAIL IEEEtran.cls' }
  if (Fetch "$ctan/bibtex/IEEEtran.bst" (Join-Path $BstDir 'IEEEtran.bst')) { Log 'OK IEEEtran.bst' } else { $failures++; Log 'FAIL IEEEtran.bst' }
  Log 'note: build with scripts\build-pdf.ps1 (it sets TEXMFHOME to this texmf)'
} else {
  Log 'OK IEEEtran.cls already present in texmf'
}

if (-not $TexOnly) {
  # 2. humanizer — installed as a skill, never vendored (upstream has no license file)
  if (-not $NoSkills) {
    $humanizer = Get-ChildItem -Path (Join-Path $Root '.github\skills') -Recurse -Filter 'SKILL.md' -ErrorAction SilentlyContinue |
      Where-Object { $_.DirectoryName -match 'humanizer' } | Select-Object -First 1
    if ($humanizer) { Log 'OK humanizer skill present' }
    elseif (-not (Have 'npx')) { Log 'FAIL npx not found — install Node.js, then re-run'; $failures++ }
    else {
      Push-Location $Root
      npx --yes skills add blader/humanizer --agent '*'
      if ($LASTEXITCODE -eq 0) { Log 'OK humanizer installed' } else { Log 'FAIL humanizer install'; $failures++ }
      Pop-Location
    }

    # 3. diagram-design — MIT, cloned on demand, gitignored
    $dd = Join-Path $Root 'vendor\diagram-design\skills\diagram-design\SKILL.md'
    if (Test-Path $dd) { Log 'OK diagram-design present' }
    elseif (-not (Have 'git')) { Log 'FAIL git not found — install Git for Windows, then re-run'; $failures++ }
    else {
      git clone --depth 1 https://github.com/cathrynlavery/diagram-design (Join-Path $Root 'vendor\diagram-design')
      if ($LASTEXITCODE -eq 0) { Log 'OK diagram-design cloned' } else { Log 'FAIL diagram-design clone'; $failures++ }
    }
  }

  # 4. cairosvg
  if (-not $NoPython) {
    $py = if (Have 'python3') { 'python3' } elseif (Have 'python') { 'python' } else { $null }
    if (-not $py) { Log 'FAIL Python not found — install Python 3 and enable the python3 alias'; $failures++ }
    else {
      & $py -c 'import cairosvg' 2>$null
      if ($LASTEXITCODE -eq 0) { Log 'OK cairosvg present' }
      else {
        & $py -m pip install --user cairosvg
        if ($LASTEXITCODE -eq 0) { Log 'OK cairosvg installed' } else { Log 'FAIL cairosvg (non-fatal: SVG→PDF fallback available)'; }
      }
    }
  }
}

# 5. refresh the report
if (Have 'node') { node (Join-Path $Root 'scripts\preflight.mjs') | Out-Null } else { Log 'note: Node.js missing — run preflight.sh in Git Bash for a full report' }

if ($failures -gt 0) { Log "$failures step(s) failed — see above"; exit 1 }
Log 'bootstrap complete'
exit 0
