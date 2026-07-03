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
    Write-Host "es.luau    — all keys covered" -ForegroundColor Green
} else {
    Write-Host "Missing in es.luau ($($missingEs.Count)):" -ForegroundColor Yellow
    foreach ($k in $missingEs) { Write-Host "  activities.$k" }
}

Write-Host ""

if ($missingPt.Count -eq 0) {
    Write-Host "pt_br.luau — all keys covered" -ForegroundColor Green
} else {
    Write-Host "Missing in pt_br.luau ($($missingPt.Count)):" -ForegroundColor Yellow
    foreach ($k in $missingPt) { Write-Host "  activities.$k" }
}

Write-Host ""
Read-Host "Press Enter to close"
