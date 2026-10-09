# NIGHTSHIFT — Project Status

Last updated: 2026-10-09. Milestone: **Phase A (inspect/prepare) done, Phase B (playable Night 1 slice) in progress.**

## Environment (verified this session)

| Item | State |
| --- | --- |
| Roblox Studio connection | **Not connected.** This session runs in a cloud container; nothing has been inserted into any Roblox place. |
| ForgeGUI connection | Connected. Free reads worked (`asset_capabilities`, `style_list`, `project_list`, `run_list`). Account is empty (no styles, projects or runs). **No Roblox publishing connection**, so generated assets come back as files, not Roblox asset IDs. No credits spent. |
| Codex | Not reachable from this session. Handoffs go through files in `docs/handoffs/`. |
| Luau tooling | Lune 0.10.5, StyLua 2.5.2 and Selene 0.31.0 built from source. **No Luau type analyzer available** (GitHub is blocked), so `--!strict` annotations are not type-checked yet. |

## Delivery route (decision pending with the user)

Source is laid out for Rojo (`src/shared`, `src/config`, `src/server`, `src/client`). The facility map is meant to be generated at runtime by the server so no manual building is needed. The alternatives are the official Studio MCP from a local session, or manual paste. The Rojo project file (`default.project.json`) is not written yet.

## What exists

- `design/` — master prompt, reference notes, 30 reference photos, manifest.
- `src/shared/SeededRandom.luau`, `RateLimiter.luau`.
- `src/server/Core/` — `PowerModel`, `RouteGraph`, `SurveillanceModel`, `WatcherBrain`, `NightStateMachine`, `NightCore`. All dependency-injected, no Roblox APIs, so they run in Lune and in Studio.
- `src/server/Config/`, `src/config/CameraConfig.luau` — Night 1 numbers: 480 s night, power drains from the brief, six cameras, seven-node route, Watcher timings.
- `tests/Harness.luau`, `tests/Fixture.luau`, `tests/run.luau`.

## What has actually been checked

- Modules load and run in Lune. `NightCore.validate` reports 0 errors on the shipped config, and a started night reaches `Active`.
- Baseline drain over 480 s leaves 61.6 power (38.4 used), matching the brief.
- Seeded RNG is deterministic for equal seeds.
- StyLua parses and formats every file; no comments other than the approved section headings.

## Not done / not verified

- **`tests/run.luau` requires suites that do not exist yet** (`tests/suites/*`), so `lune run tests/run` fails until they are written.
- No Roblox-bound code yet: no `default.project.json`, `FacilityBuilder`, services, remotes, client, UI, audio.
- No Studio runtime test, no visual inspection, no device test of any kind.
- Strict type-checking not run. No ForgeGUI asset generated or imported.
- Persistence, Hollow, Signal and Nights 2–6 are out of scope for the slice (Phases D–E).

## Next steps

1. Write the test suites and run the Night 1 acceptance scenarios that do not need Studio, plus seeded policy simulations for balance evidence.
2. Rojo project, remotes, `FacilityBuilder`, server services, then the client camera/input/HUD.
3. Plan/contracts doc, asset records and the first Codex handoff.
