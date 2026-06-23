set shell := ["powershell", "-c"]

packages name="bitkaisen":
	pesde install
	rojo sourcemap {{name}}.project.json -o sourcemap.json

map name="bitkaisen":
	rojo sourcemap {{name}}.project.json -o sourcemap.json

[parallel]
dev name="bitkaisen": (smart-sync name) (net name)

smart-sync name="bitkaisen":
	zune run Zune/smart-sync {{name}}

# ---------- SERVICES ----------
net name="bitkaisen":
	blink remotes/{{name}}.blink --watch

# ---------- UTIL ----------
alias alias path:
	zune run Zune/alias.lua {{alias}} {{path}}
