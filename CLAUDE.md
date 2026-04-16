# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**DivineDominion** is a real-time strategy game prototype inspired by Mega-Lo-Mania (1991), built with **Godot 4.3+ (GDScript)**. It's a grid-based RTS/management sim, single-player vs AI. The MVP focuses on core gameplay loop with placeholder graphics (colored rectangles).

The design spec lives in `mega_lo_mania_claude_code_prompt.md` — always consult it for game mechanics details.

## Running the Project

- **Godot path**: `C:/Tools/Godot/Godot_v4.6.2-stable_win64.exe` (console version: `Godot_v4.6.2-stable_win64_console.exe`)
- Open project: `"C:/Tools/Godot/Godot_v4.6.2-stable_win64.exe" --path .`
- Run game: `"C:/Tools/Godot/Godot_v4.6.2-stable_win64_console.exe" --path . --headless` (for testing without GUI)
- Main scene: `scenes/main/Main.tscn`
- Resolution: 1280x720, 2D renderer
- Tests (if using GUT framework): `"C:/Tools/Godot/Godot_v4.6.2-stable_win64_console.exe" --path . -s addons/gut/gut_cmdln.gd`

## Architecture

The project follows strict **separation of concerns** — game logic is completely independent from UI.

```
GameState (autoload singleton)
├── WorldModel      — sectors, ownership, tower states
├── PlayerModel[]   — men, resources, tech level, designs
└── TickEngine      — drives per-tick updates for all systems
```

UI layer observes models via **Godot signals** — never put game logic in UI nodes.

### Key Signals
- `sector_captured`, `tech_level_advanced`, `weapon_designed`, `combat_resolved`, `men_allocation_changed`

### Folder Structure
```
/scripts
  /models       — GameState, WorldModel, PlayerModel
  /systems      — TickEngine, CombatSystem, AISystem
  /data         — Epoch, Weapon, Shield resource classes
/scenes
  /ui           — Control scenes
  /main         — Main.tscn (root scene)
/resources
  /epochs       — .tres files
  /weapons      — .tres files
/tests          — GUT tests
```

## Data-Driven Design

All game data (epochs, weapons, shields, costs) must be in **Godot Resource files (.tres)** or JSON — never hardcoded. Resource classes:
- `EpochData` — tech level, available weapons, required design points
- `WeaponData` — damage, element cost, manufacture time
- `ShieldData` — defense, cost, manufacture time
- `IslandData` — sector count, startup conditions

## Coding Conventions

- **Language**: GDScript only (no C#)
- **Strict typing** everywhere: `var x: int = 0`, typed function signatures
- **No magic numbers** — use constants or Resources
- **Methods max ~20 lines** — extract when longer
- **Composition over inheritance**
- **No third-party addons** for MVP (except optionally GUT for testing)
- Docstrings above every class and public method
- **Use `SectorModel.Task` enum keys** when accessing `sector.men` dictionary — never plain `int` (Godot treats enum and int as different dictionary keys)
- **`preload` as const** at top of file: `const SCENE: PackedScene = preload("res://...")`, not inline in functions
- **Max line length**: 120 characters (enforced by gdlint)
- **Class definition order** (enforced by gdlint): classnames → extends → docstrings → signals → enums → consts → exports → pubvars → prvvars → onready vars

## Linting & Formatting

Before committing, ensure code passes both checks:

```bash
gdlint scripts/ scenes/
gdformat --check scripts/ scenes/
```

Or use `gdformat scripts/ scenes/` to auto-fix formatting. Pre-commit hooks run these automatically if installed (`pre-commit install`).

## Game Mechanics Summary

- **Fixed tick rate**: 4 ticks/second for all game logic (reproduction, mining, design progress)
- **Men allocation**: 5 tasks per sector — Idle (reproduction), Mining, Design, Manufacture, Army
- **Combat**: `strength = men_count * tech_weapon_multiplier`, both sides take casualties
- **AI**: Simple state machine (EXPAND/RESEARCH/DEFEND/ATTACK), decides every 8-15 seconds, 20s startup delay
- **MVP scope**: 1 island, 4 sectors (2x2), 2 players, 3 tech levels (of 10)

## Out of Scope (MVP)

Do not implement: sprites/animations, audio, multiplayer, alliances, shields, save/load UI, settings menu, localization. These are planned for future iterations.

## Code Review Workflow

This project uses a multi-layered code quality pipeline:

1. **Local pre-commit hooks** (`gdlint`, `gdformat`) — run before every commit
2. **GitHub Actions CI** — validates syntax, style, and Godot project integrity on every PR
3. **CodeRabbit** — AI-based review focused on architecture, logic, and guidelines

When opening a PR, let CodeRabbit complete its review before merging.
Path-specific review rules are defined in `.coderabbit.yaml`.

## Workflow

Work iteratively in this order:
1. Project structure + `project.godot`
2. Data models and resources (no graphics)
3. TickEngine and game loop (console logging, no UI)
4. UI layer (rectangles and panels)
5. AI opponent
6. Win/lose conditions and polish

Show progress after each phase and wait for feedback before continuing.
