# bitkaisen

Roblox Anime Tower Defense game using ECS architecture and Fusion UI hydration.

## Prerequisites

- [rokit](https://github.com/rojo-rbx/rokit) - Toolchain manager

## Setup

1. Install toolchain:
   ```bash
   rokit install
   ```

2. Install packages:
   ```bash
   just packages bitkaisen
   ```

3. Start developing:
   Install rojo plugin if not already:
   ```bash
   rojo plugin
   ```
   and restart studio.

   ```bash
   just dev bitkaisen
   ```

   This does a few things:
   - watches and creates sourcemap
   - runs rojo serve
   - watches `bitkaisen.blink` and compiles networking code via blink
   - outputs to `build/` (darklua)

   Now connect to the server via the Rojo plugin.

4. Zune setup:
   ```bash
   zune setup <nvim | zed | vscode | emacs>
   ```

## Development

### Aliases

```bash
just alias (alias) (path)
```

### Building

```bash
lune run Lune/test.lua
```

## Project Structure

```
game/
├── server/          # Server code & systems
├── shared/          # Replicated code (ECS, components, types)
│   ├── ecs/         # World, scheduler, replicator, startup
│   ├── components/  # ECS component definitions
│   ├── systems/     # ECS systems
│   ├── hooks/       # Fusion hooks & utilities
│   └── controllers/ # UI hydration controllers
└── starterplayer/   # Client startup scripts

global/
├── server/          # Datastore, ProfileStore, accountService
├── shared/          # Data types, store sync, constants
│   ├── constants/   # Game data definitions
│   ├── utils/       # Shared utilities
│   └── types/       # Type definitions
└── client/          # Global client-side code

remotes/             # Blink networking definitions
├── bitkaisen.blink  # Main blink entry (imports global/)
└── global/          # Shared networking events

Packages/            # Wally/pesde dependencies
Zune/                # Automation scripts
```

## Tech Stack

- **ECS**: Jecs + Planck scheduler + Jabby debugger + Replecs replication
- **Networking**: Blink (codegen) + ByteNet
- **UI**: Fusion (Hydrate pattern against Studio templates)
- **Data**: ProfileStore + Charm (state) + Delta-Compress (replication)
- **Build**: Rojo + Darklua + Selene (lint)
- **Toolchain**: Rokit + Pesde + Just + Zune

## Guidelines

- Use `.luau` file extension
- Follow existing ECS patterns for new systems
- Use transaction API for data changes, never modify atoms directly
- UI logic via Fusion `Hydrate` against Studio templates; no full-code UI construction
- Never edit generated files in `remotes/out/`
