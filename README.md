# bitkaisen

BitLife-style Jujutsu Kaisen life simulator on Roblox. Live your life as a sorcerer -- age through eras, unlock cursed techniques, master domains, build relationships, complete missions, and rise through clan ranks.

## Prerequisites

- [Rokit](https://github.com/rojo-rbx/rokit) - Toolchain manager (provides `just`, `pesde`, `rojo`, `blink`, `darklua`, `zune`, `selene`; do **not** install these separately)

On Windows, download `rokit.exe` from the [latest release](https://github.com/rojo-rbx/rokit/releases/latest) and double-click it, or run from a terminal:

```powershell
rokit self-install
```

**Restart your terminal** after installing so `~/.rokit/bin` is on your PATH.

## Setup

### 1. Authenticate with GitHub (required on flaky networks)

This prevents download failures caused by GitHub API rate limits. Without this step, `rokit install` will frequently fail with `error decoding response body` or silently drop connections. Create a [Personal Access Token](https://github.com/settings/tokens) (classic, no scopes needed) and run:

```powershell
rokit authenticate github --token YOUR_TOKEN_HERE
```

### 2. Install toolchain

```powershell
rokit install --no-trust-check
```

This downloads every tool pinned in `rokit.toml` (rojo, blink, darklua, zune, pesde, selene, just, etc.). The `--no-trust-check` flag skips the interactive trust prompt that can silently prevent tools from installing.

### 3. Install packages and generate sourcemap

```powershell
just setup
```

This runs `pesde install` (downloads all Luau dependencies) and generates `sourcemap.json`. You can also run `just packages` which does the same thing without re-running `rokit install`.

### 4. Install Rojo Studio plugin

```powershell
rojo plugin install
```

Restart Roblox Studio after installing.

### 5. Start developing

```powershell
just dev
```

This runs in parallel:
- Darklua smart-sync (watches source files, outputs to `build/`)
- Blink watch (compiles `.blink` networking definitions)
- Rojo serve (syncs `build/` to Studio)

Connect to the Rojo server via the plugin in Studio.

### 6. Zune editor setup (optional)

```powershell
zune setup <nvim | zed | vscode | emacs>
```

## Troubleshooting

- **"command not found" or "tool is missing" right after install** -- Restart your terminal so `~/.rokit/bin` is on PATH. Run `rokit list` to verify tools are installed. If any are missing, run `rokit install --force`.

- **Downloads fail intermittently / connection drops / "works some days"** -- This is GitHub API rate limiting. Run `rokit authenticate github --token <PAT>` then re-run `just setup`.

- **`Failed to download contents for <tool>` / `error decoding response body`** -- GitHub throttled or dropped the download mid-stream. Fix: (1) `git pull` to get the latest setup steps; (2) `rokit authenticate github --token <PAT>` if you haven't already; (3) `rokit install --force` to re-download the failed tool; (4) retry on a stable connection if it still fails.

- **"Won't let me reinstall" / tool is half-installed** -- Run `rokit install --force` to re-download all tools regardless of cache state.

- **`just setup` or `just packages` fails on `pesde install`** -- Make sure all rokit tools installed successfully first (run `rokit list`). Check your network connection and VPN settings.

## Development

### Commands

| Command | Description |
|---------|-------------|
| `just setup` | Full bootstrap: install rokit tools + pesde packages + sourcemap |
| `just packages` | Install pesde packages + regenerate sourcemap |
| `just dev` | Start dev server (darklua watch + blink watch + rojo serve) |
| `just net` | Compile blink networking only |
| `just map` | Regenerate sourcemap only |
| `just check` | Lint with selene + verify rojo build |
| `just alias <alias> <path>` | Create a path alias |

### Aliases

```powershell
just alias (alias) (path)
```

## Project Structure

```
game/
├── server/              # Server code (GameManager, BK_* services)
│   └── BitKaisenServer/ # Service modules (Remotes, Combat, Missions, etc.)
├── shared/              # Replicated code
│   ├── hooks/           # Utility hooks
│   ├── ui/              # UI tree: shell components (Vide), panels, state, theme
│   │   ├── components/  # Vide reactive shell components (ProfileCard, LifeLog, NavPanel, etc.)
│   │   ├── panels/      # Imperative panel modules (30+), each with own ScreenGui
│   │   └── state/       # Shared state: playerState, uiState, navRegistry, remotes
│   └── controllers/     # Cross-cutting controllers
└── starterplayer/       # Client scripts (BitKaisenClient bootstrap, orientation lock, etc.)

global/
├── server/              # Datastore, ProfileStore, accountService
├── shared/              # Data types, store sync, constants
│   ├── constants/       # Game data definitions
│   ├── utils/           # Shared utilities (px scaling, objects, observers)
│   └── types/           # Type definitions
└── client/              # Global client-side code

remotes/                 # Blink networking definitions
├── bitkaisen.blink      # Main blink entry (imports global/)
└── global/              # Shared networking events

Packages/                # Wally/pesde dependencies
Zune/                    # Automation scripts (smart-sync, aliases)
```

## Tech Stack

- **Networking**: Blink (codegen) + BK_Remotes (classic RemoteEvent/Function)
- **UI**: Vide (reactive component tree via `vide.mount()` for shell; imperative `Instance.new()` panels)
- **Scaling**: px.luau (design at 1920x1080) + responsiveScale.luau (UIScale-driven uniform scaling)
- **Data**: ProfileStore + Charm (state) + Delta-Compress (replication)
- **Validation**: GreenTea schemas
- **Build**: Rojo + Darklua (smart-sync) + Selene (lint)
- **Toolchain**: Rokit + Pesde + Just + Zune

## Guidelines

- Use `.luau` file extension (never `.lua`)
- Use transaction API for data changes, never modify atoms directly
- Use `px()` for all pixel measurements to ensure device-universal scaling
- Never edit generated files in `remotes/out/`
