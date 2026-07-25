set shell := ["powershell", "-c"]

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
	Remove-Item -Force .rojo-check.rbxm

# ---------- UTIL ----------
alias alias path:
	zune run Zune/alias.lua {{alias}} {{path}}
