# NIGHTSHIFT — Project Status

Last updated: 2026-10-09. Milestone: **Phase A (inspect/prepare) done, Phase B (playable Night 1 slice) in progress.**

## Environment (verified, not assumed)

| Item | State |
| --- | --- |
| Roblox Studio connection | **Not connected to the cloud session that wrote this code.** Checked repeatedly: no Studio tools exist in that session, its connector list shows only ForgeGUI. Nothing has been inserted into any Roblox place. The user believes the Studio MCP is connected; if so it is attached to a different session (e.g. a local Claude Code session). |
| Studio MCP on the user's PC | User-supplied command (not verifiable from the cloud): `claude mcp add --transport stdio Roblox_Studio -- "cmd.exe" "/c" "cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat"`. Run it in a terminal on the PC, then start `claude` in the cloned repo with Studio open. |
| ForgeGUI | Connected; free reads work. Account is empty. **No Roblox publishing connection** (assets come back as files, no asset IDs until a Personal connection is added at ForgeGUI `/forge-mcp`). **Cloud network policy blocks the upload/storage host `azyjlkhpdgafuobyxoax.supabase.co`**, so reference photos cannot be uploaded and generated files probably cannot be inspected. **0 credits spent.** |
| ForgeGUI budget (user's words) | "around 150k tokens" available; use about 25k, 35–50k only if needed, **never more**. Interpreted as ForgeGUI credits. Prices and balance are not visible to the assistant, so spend one asset at a time and read the reported cost. |
| Codex | Not reachable from the cloud session. Handoffs go through files in `docs/handoffs/` (none written yet). |
| Luau tooling | Lune 0.10.5, StyLua 2.5.2, Selene 0.31.0 built from source (not committed). **No Luau type analyzer available**, so `--!strict` annotations are not type-checked. |

## Delivery route

Source is laid out for Rojo (`src/shared`, `src/config`, `src/server`, `src/client`) but `default.project.json` is not written yet. Alternatives: the Studio MCP from a local session, or manual paste.

## What exists

- `design/` — master prompt, reference notes, 30 reference photos, manifest.
- `src/shared/SeededRandom.luau`, `RateLimiter.luau`.
- `src/server/Core/` — `PowerModel`, `RouteGraph`, `SurveillanceModel`, `WatcherBrain` (7-state FSM), `NightStateMachine`, `NightCore` (orchestrator, validator, settings composer). Dependency-injected, no Roblox APIs, so they run in Lune and in Studio.
- `src/server/Config/`, `src/config/CameraConfig.luau` — Night 1 numbers: 480 s night, power drains from the brief, six cameras, seven-node route, Watcher timings.
- `tests/` — harness, fixtures and 8 suites.

## What has actually been checked

`lune run tests/run` → **80 passed, 0 failed** (headless Luau runtime, no Studio):

- Seeded RNG determinism/distribution; rate limiter; state machine transition table.
- Power: baseline 38.4 units per 480 s, per-device drains, door held shut all night runs out at ~416.7 s, thresholds at 25/10 fire once, clamping, zero-power behaviour.
- Route graph validation (dead ends, unreachable nodes, door rules) and walking speeds of every edge.
- Surveillance: selection dwell, invalid ids, switch rate limit, feed jam after sustained watching, recovery.
- Watcher: grace period, legal moves only, no teleporting, freezes when watched, guaranteed cue lead time (>= 3.5 s + 2.6 s travel before arrival), closed door blocks then retreats and returns, open door is lethal only after the 1.75 s window, closing in time saves, power-out rush from every node, deterministic replay.
- NightCore: config validation, all six feeds, door/tablet/light power costs, duplicate requests free, cooldown, hands-busy rule, invalid input refused, zero-power fallback (with a survivable case near dawn), win emitted once, clean retry after win and after loss, abort to menu, light overheat, door sensor, hints fire once, hitch and debug speed.
- A bug found by the tests and fixed: consecutive small seeds produced near-identical sequences; seeds are now hash-mixed.
- StyLua parses and formats every file; no comments other than the approved section headings.

## Not done / not verified

- Seeded multi-policy night simulations (balance evidence) are not written yet.
- No Roblox-bound code: no `default.project.json`, `FacilityBuilder`, services, remotes, client, UI, audio.
- No Studio runtime test, no visual inspection, no device test of any kind.
- Strict type-checking not run. No ForgeGUI asset generated or imported.
- Persistence, Hollow, Signal and Nights 2–6 are out of scope for the slice (Phases D–E).

## Next steps

1. Simulation suite; then Rojo project, remotes, `FacilityBuilder`, server services, client camera/input/HUD.
2. Unblock ForgeGUI: allow the storage host in the cloud environment's network settings (or run asset work from a local session), add a Personal publishing connection.
3. Plan/contracts doc, asset records, first Codex handoff.
