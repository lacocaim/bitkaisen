# check_translations.ps1
# Run this before a translation session to see what activity keys are missing
# from es.luau and pt_br.luau compared to what BK_ActivityService uses.

$activityFile = "$PSScriptRoot\game\server\BitKaisenServer\BK_ActivityService.luau"
$esFile       = "$PSScriptRoot\game\shared\locale\es.luau"
$ptFile       = "$PSScriptRoot\game\shared\locale\pt_br.luau"

function Get-UsedKeys($filePath) {
    $content = Get-Content $filePath -Raw
    $matches = [regex]::Matches($content, 'tAct\s*\(\s*\w+\s*,\s*"([^"]+)"')
    $keys = @{}
    foreach ($m in $matches) {
        $keys[$m.Groups[1].Value] = $true
    }
    return $keys.Keys | Sort-Object
}

function Get-DefinedKeys($filePath) {
    $content = Get-Content $filePath -Raw
    # Find the activities block
    $block = [regex]::Match($content, 'activities\s*=\s*\{([\s\S]*?)\n\t\}')
    if (-not $block.Success) {
        Write-Host "  Could not find activities block in $filePath" -ForegroundColor Red
        return @()
    }
    $matches = [regex]::Matches($block.Groups[1].Value, '^\s+(\w+)\s*=', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    return ($matches | ForEach-Object { $_.Groups[1].Value }) | Sort-Object
}

$used   = Get-UsedKeys $activityFile
$esDef  = Get-DefinedKeys $esFile
$ptDef  = Get-DefinedKeys $ptFile

function Get-Missing($usedKeys, $definedKeys) {
    $defSet = @{}
    foreach ($k in $definedKeys) { $defSet[$k] = $true }
    return $usedKeys | Where-Object { -not $defSet.ContainsKey($_) }
}

$missingEs = Get-Missing $used $esDef
$missingPt = Get-Missing $used $ptDef

Write-Host ""
Write-Host "====  TRANSLATION COVERAGE CHECK  ====" -ForegroundColor Cyan
Write-Host "  Activity keys in code:  $($used.Count)"
Write-Host "  Defined in es.luau:     $($esDef.Count)"
Write-Host "  Defined in pt_br.luau:  $($ptDef.Count)"
Write-Host ""

if ($missingEs.Count -eq 0) {
    Write-Host "es.luau    -- all keys covered" -ForegroundColor Green
} else {
    Write-Host "Missing in es.luau ($($missingEs.Count)):" -ForegroundColor Yellow
    foreach ($k in $missingEs) { Write-Host "  activities.$k" }
}

Write-Host ""

if ($missingPt.Count -eq 0) {
    Write-Host "pt_br.luau -- all keys covered" -ForegroundColor Green
} else {
    Write-Host "Missing in pt_br.luau ($($missingPt.Count)):" -ForegroundColor Yellow
    foreach ($k in $missingPt) { Write-Host "  activities.$k" }
}

Write-Host ""

# ---------------------------------------------------------------
#  HARDCODED SPANISH / PORTUGUESE CHECK
#  The game itself must read in English. Spanish and Portuguese
#  belong in game/shared/locale/es.luau and pt_br.luau only.
#  This flags player-facing string literals written in Spanish or
#  Portuguese anywhere else in game/.
# ---------------------------------------------------------------

$gameRoot   = "$PSScriptRoot\game"
$localePath = "$PSScriptRoot\game\shared\locale"

# Accented letters and inverted punctuation, as \uXXXX so this file stays ASCII.
$accents = '[\u00E1\u00E9\u00ED\u00F3\u00FA\u00F1\u00C1\u00C9\u00CD\u00D3\u00DA\u00D1\u00BF\u00A1\u00E3\u00F5\u00E7\u00EA\u00E2\u00C3\u00D5\u00C7]'

# Words that only show up in Spanish/Portuguese copy, never in English copy.
$words = '\b(Este|Esta|Estas|Estos|Tus|Ninguna|Ningun|Todas|Todos|para|con|del|que|sin|pero|cuando|ahora|desde|hasta|entre|sobre|Vidas|Mundo|Celulas|Sello|Selo|Soberano|Hechicero|Feiticeiro|Juramento|Revancha|Revanche|Reunion|Reuniao|leyenda|lenda|anos)\b'

# Legitimate exceptions: real place names, and the legacy save values the UI
# still has to recognise (see LEGEND_GRADE_KEY in the WorldHistory panels).
$allow = @(
    'S\u00E3o Paulo',
    'legend_sovereign', 'legend_outstanding', 'legend_notable', 'legend_forgotten'
)

$offenders = @()
$files = Get-ChildItem -Path $gameRoot -Filter *.luau -Recurse |
         Where-Object { -not $_.FullName.StartsWith($localePath) }

foreach ($file in $files) {
    $lineNo = 0
    foreach ($line in (Get-Content $file.FullName -Encoding UTF8)) {
        $lineNo++
        if ($line.TrimStart().StartsWith('--')) { continue }

        foreach ($m in [regex]::Matches($line, '"([^"]*)"')) {
            $text = $m.Groups[1].Value
            if ($text.Length -lt 4) { continue }

            $skip = $false
            foreach ($a in $allow) {
                if ([regex]::IsMatch($text, $a)) { $skip = $true; break }
            }
            if ($skip) { continue }

            if ([regex]::IsMatch($text, $accents) -or
                [regex]::IsMatch($text, $words, 'IgnoreCase')) {
                $rel = $file.FullName.Substring($PSScriptRoot.Length + 1)
                $offenders += [PSCustomObject]@{
                    File = $rel
                    Line = $lineNo
                    Text = $text
                }
            }
        }
    }
}

Write-Host ""
Write-Host "====  HARDCODED SPANISH / PORTUGUESE CHECK  ====" -ForegroundColor Cyan
Write-Host "  Files scanned outside locale/: $($files.Count)"
Write-Host ""

if ($offenders.Count -eq 0) {
    Write-Host "No Spanish or Portuguese found outside the locale module." -ForegroundColor Green
} else {
    Write-Host "Hardcoded non-English strings ($($offenders.Count)):" -ForegroundColor Yellow
    Write-Host "  Move these to es.luau / pt_br.luau and leave English in the code." -ForegroundColor DarkGray
    foreach ($o in $offenders) {
        $preview = $o.Text
        if ($preview.Length -gt 90) { $preview = $preview.Substring(0, 90) + "..." }
        Write-Host ("  {0}:{1}" -f $o.File, $o.Line) -ForegroundColor Yellow
        Write-Host ("      {0}" -f $preview)
    }
}

Write-Host ""
Read-Host "Press Enter to close"
