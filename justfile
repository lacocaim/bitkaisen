set shell := ["powershell", "-c"]

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

# ---------- UTIL ----------
alias alias path:
	zune run Zune/alias.lua {{alias}} {{path}}
