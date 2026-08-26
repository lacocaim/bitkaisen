set shell := ["powershell", "-Command"]

setup name="game":
	rokit install --no-trust-check
	pesde install
	rojo sourcemap {{name}}.project.json -o sourcemap.json

packages name="game":
	pesde install
	rojo sourcemap {{name}}.project.json -o sourcemap.json

map name="game":
	rojo sourcemap {{name}}.project.json -o sourcemap.json

[parallel]
dev name="game": (smart-sync name) (net)

smart-sync name="game":
	zune run Zune/smart-sync {{name}}

# ---------- SERVICES ----------
net:
	blink remotes/bitkaisen.blink --watch

# ---------- CHECK ----------
check name="game":
	selene game/ global/
	rojo build {{name}}.project.json -o .rojo-check.rbxm
	rm -f .rojo-check.rbxm

# ---------- UTIL ----------
alias alias path:
	zune run Zune/alias.lua {{alias}} {{path}}

# ---------- TEST ----------
test:
	$failed = 0; Get-ChildItem tests -Filter *.test.luau | ForEach-Object { Write-Host ""; Write-Host "=== $($_.Name) ===" -ForegroundColor Cyan; zune run "tests/$($_.Name)"; if (-not $?) { $failed = 1 } }; if ($failed -ne 0) { Write-Host ""; Write-Host "TESTS FAILED" -ForegroundColor Red; exit 1 } else { Write-Host ""; Write-Host "all test files passed" -ForegroundColor Green }
