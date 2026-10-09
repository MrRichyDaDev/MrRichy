# NIGHTSHIFT — ROBLOX HORROR GAME MASTER PROMPT
## Claude leads. Codex assists. ChatGPT supports design.

Working title: NIGHTSHIFT: THE FORGOTTEN FACILITY
Platform: Roblox Studio / Luau
Direction: An original, polished security-survival horror game inspired by the tension and strategic monitoring of Five Nights at Freddy's.
Prepared: October 9, 2026

## HOW TO USE THIS FILE

Give this entire prompt to Claude first. Claude is the project leader and owns the architecture, plan, integration, art direction approval, and final quality decisions within the user's instructions. Give Codex the same prompt plus one specific assignment written by Claude. Use ChatGPT for creative and experience-design support when needed.

Extract the accompanying ZIP to access the 30 downloaded reference photos. Open Reference_Gallery.html to browse them. REFERENCES.md contains the source links and practical design notes. For a Claude session that can access local files, provide the extracted folder path. In a chat-only session, upload this prompt and a small selection of relevant photos for the current task. Do not assume an assistant can inspect photos inside an unopened archive.

This is a development brief, not a claim that the game has already been built. The downloaded photos are references for composition, light, architecture, equipment, and materials. ForgeGUI is the requested asset-production tool. Claude must verify its actual connected capabilities before using it.

---

## 1. YOUR MISSION

Build a cohesive, high-quality, original Roblox horror experience. The player works a night shift inside a neglected entertainment-and-research facility whose machines reactivate after closing. The experience combines security cameras, understandable enemy behavior, limited power, and short maintenance excursions.

The game should feel designed and finished: clear rules, responsive interactions, an intentional office composition, recognizable sound cues, stable performance, and a consistent interface. Treat ambitious visual quality as a direction to earn through iteration. Do not promise engine features, frame rates, or a finished production game without evidence.

Start with one fully playable night. Expand only after the core loop works. Every feature must have an owner, a clear purpose, an integration contract, and an acceptance check.

Take inspiration from FNAF's anticipation, resource decisions, and observation-based tension. Create original characters, branding, geometry, narrative, audio, and UI. The working title can change if the user chooses another name.

## 2. LEADERSHIP AND AUTHORITY

The user has final authority over scope, style, budget, and release decisions. Their current instructions override this brief.

CLAUDE — PROJECT LEADER / LEAD DEVELOPER

Claude is responsible for:

- Inspecting the existing project and selecting the correct Studio place.
- Defining the technical architecture and public module contracts.
- Maintaining the development plan and shared implementation log.
- Owning night progression, enemy behavior, power, objectives, and server authority.
- Directing the environment and presentation work.
- Using ForgeGUI for the approved asset workflow.
- Assigning bounded coding, debugging, testing, or polish tasks to Codex.
- Reviewing Codex's changes, resolving integration issues, and accepting milestones.
- Deciding implementation priorities within the user's approved scope.

Claude must remain a working lead. Leadership means building and integrating systems, reviewing real evidence, and making decisions that move the project forward.

CODEX — HELPER / SUPPORT DEVELOPER

Codex assists Claude and works within Claude's current assignment. Codex may implement an assigned module, fix bugs, review security, improve a UI screen, create a test harness, optimize a measured bottleneck, or produce a clearly requested asset integration utility.

Codex must:

- Read Claude's task and the affected dependencies before editing.
- Preserve the agreed architecture and shared contracts.
- Keep edits within the assigned ownership boundary.
- Fix routine issues inside its assignment without repeatedly requesting permission.
- Report discoveries that affect other systems, with a suggested fix.
- Return a concise handoff with exact changed paths and test evidence.
- Leave final integration and milestone acceptance to Claude.

Codex may offer technical recommendations. It must not independently rewrite shared managers, expand the roadmap, create a rival architecture, or act as project leader. If Claude's assignment conflicts with an explicit user instruction, follow the user and flag the conflict in the handoff.

CHATGPT — DESIGN SUPPORT

ChatGPT supports Claude with enemy design, level composition, UI hierarchy, atmosphere, narrative, balancing proposals, accessibility, and review. Suggestions enter the project through Claude's plan. ChatGPT does not become another competing system owner by receiving this prompt.

These roles do not establish a live connection between applications. If no shared messaging mechanism exists, exchange written handoffs through the user or the shared project files. Never claim that another assistant received a message unless delivery is confirmed.

## 3. PROJECT COORDINATION

Maintain PROJECT_STATUS.md and TASKS.md in the source repository or the agreed project workspace. Record the active milestone, accepted contracts, system ownership, completed work, blockers, next steps, and what has actually been tested.

One person or assistant owns edits to a script at a time. Before editing a shared script, read the latest source and the active task record. Treat an ownership record as a coordination boundary, not a reason to repeatedly ask the user for routine implementation choices. Work on independent tasks while a handoff is pending.

Use one manager per responsibility. Adapt the existing hierarchy instead of inserting duplicate NightService, CameraController, or HUD managers. Preserve existing developer content. Make a checkpoint before substantial structural edits and use small reversible changes when possible.

Claude's task format for Codex:

```text
TASK ID:
FEATURE / PROBLEM:
ASSIGNED OWNER: Codex
ALLOWED SCRIPT / INSTANCE PATHS:
CURRENT SOURCE / REVISION:
DEPENDENCIES AND PUBLIC CONTRACTS:
EXPECTED BEHAVIOR:
ACCEPTANCE CHECKS:
INTEGRATION NOTES:
```

Codex's return format:

```text
TASK ID:
RESULT:
EXACT PATHS CHANGED:
BEHAVIOR IMPLEMENTED:
CONTRACT CHANGES, IF ANY:
CHECKS ACTUALLY RUN:
OBSERVED RESULTS:
REMAINING LIMITATIONS:
NEXT STEP FOR CLAUDE:
```

Keep these records practical. Prefer an implemented and verified small task to a long status report with no progress.

## 4. CLAUDE MUST USE FORGEGUI

ForgeGUI is the preferred production tool for original UI artwork, icons, branding concepts, and supported environment or character assets. Claude owns this workflow and keeps the visual style consistent. Use the real service at https://forgegui.com/ and its current documentation at https://forgegui.com/docs.

At the beginning of asset work:

1. Discover the connected ForgeGUI tools and inspect their current schemas.
2. Verify authentication using a free discovery or library-search operation when available.
3. Verify the separate Roblox Studio connection and target place.
4. Identify an existing usable asset or the exact asset to generate.
5. Confirm the applicable account, requested output format, and supported import route.
6. If generation spends credits, use an already approved budget. If no budget exists, prepare the asset request, proposed count, and cost information available from the service, then obtain a bounded approval before spending.

ForgeGUI and Studio are separate connections. A working ForgeGUI connection does not prove that Claude can insert content into Studio. A subscription to Claude or ChatGPT does not establish a ForgeGUI credit balance.

If ForgeGUI is not connected, clearly mark the asset step blocked. Continue independently useful gameplay, hierarchy, and native UI implementation. Provide the exact prepared ForgeGUI prompts and a setup reference; do not pretend that generation or import occurred.

Never request or paste account keys into chat, source files, archives, or command arguments. Use the client's designated secure configuration or authenticated service settings. Follow current tool capabilities rather than inventing function names, asset IDs, or endpoints.

Use this asset lifecycle:

REQUESTED → GENERATED OR REUSED → OUTPUT CHECKED → IMPORTED → IN-ENGINE CHECKED → ACCEPTED

Keep an asset record containing its purpose, source/reference IDs, generation prompt, returned job or artifact identity, dimensions or model properties, actual Roblox asset ID or instance path, and verification status. A URL is not a Roblox asset ID. An imported image is not evidence that the HUD works.

Do not automatically repeat a paid request after an ambiguous timeout. First inspect the original job status. Avoid generating large batches before validating one representative asset and its Studio import route.

## 5. HOW TO USE THE 30 REFERENCE PHOTOS

Read REFERENCES.md and inspect the relevant images visually. Select two to four references for each room, UI asset, or prop. Avoid attaching all 30 to every asset request.

Translate a reference into concrete traits: focal point, camera height, silhouette, negative space, light direction, warm/cool balance, surface wear, equipment scale, and navigation readability. The reference notes are design interpretations, not claims about the real locations.

Use the photos to guide original Roblox content. Do not insert a photograph as a substitute for a playable room. Do not reproduce visible brands or turn a real identifiable location into the fictional story by accident. Keep the sources alongside the design work.

Start with these visual groups:

- Office and monitors: CRT equipment, security-camera hardware, and restrained pools of warm light.
- Corridors and threat approach: strong vanishing points, dark doorways, isolated warning lights.
- Service areas: industrial machinery, worn surfaces, concrete tunnels, and stairs.
- Showroom and facility identity: the arcade reference and large industrial rooms.
- Signal and repair systems: circuit-board patterns, switches, small diagnostic labels, and readable component groupings.

Use realistic hardware references to invent original machines. The pack does not provide a finished enemy character, rig, animation, or UI screenshot. Those need dedicated design and production.

## 6. CORE GAME EXPERIENCE

The player enters a facility called the Aster Entertainment Research Annex, takes a security shift, and learns why its automated performers were retired. This name is a working narrative choice.

During a shift the player:

1. Checks the current objective and equipment status.
2. Monitors connected cameras and learns where an enemy is approaching.
3. Responds using door, light, observation, or sound-management tools.
4. Decides when to spend power and when to conserve it.
5. Completes occasional clearly signaled repair objectives.
6. Survives until the shift ends and unlocks the next night or a lore entry.

Observation must change decisions. Audio must carry usable information. Losing should reveal an understandable mistake. Threats should have counterplay and consistent rules, even when their routes vary.

Design for solo play first. The later cooperative mode may support one to four players after shared resource use and failure rules are proven fair. Do not delay the first solo slice with unfinished multiplayer systems.

## 7. FIRST PLAYABLE MILESTONE

Build one complete security office, a compact connected facility, six working surveillance viewpoints, one enemy, one functional security door, one inspection light, a power meter, an eight-minute night, and victory/failure transitions.

Night 1 acceptance requires:

- A player can start the shift, understand the controls, and finish or lose.
- All six camera selections show the intended areas.
- The Watcher follows its documented rules.
- Watching a valid feed affects the Watcher in a demonstrable way.
- Door state affects traversal and consumes the configured amount of power.
- Zero power produces a defined fallback, without a stuck UI or softlock.
- A retry creates a clean new run and restores the camera and input state.
- HUD text remains readable on the selected desktop, touch, and controller test layouts.
- No known uncaught errors occur in the scenarios actually tested.

Create a polished vertical slice before expanding the map. Simple prototype enemy geometry is acceptable while the behavior is being validated; label that art status clearly and replace it before declaring presentation complete.

## 8. NIGHT PROGRESSION

Night 1 — Orientation: Teach the monitor, one door, one light, and the Watcher's approach cues. Use predictable pacing and a short contextual tutorial.

Night 2 — Unusual Activity: Introduce the Hollow, noisy equipment choices, and one supervised maintenance route. Add a brief, readable signal interruption.

Night 3 — System Failure: Introduce the Signal's interference and circuit diagnosis. Give the player a safe opportunity to learn the new rule before combining pressures.

Night 4 — Lockdown: Combine established mechanics with alternate routes and a consequential repair choice. Avoid introducing several unknown failure rules at once.

Night 5 — Final Shift: Test knowledge of all threats, complete a final repair sequence, and deliver an interactive escape or shutdown ending.

Night 6 — Custom Nightmare: Unlock configurable enemy difficulty and optional modifiers after the story. Display modifier effects plainly and validate score/achievement eligibility on the server.

Each night adds a meaningful rule, location, or narrative development. Use configurable difficulty values rather than duplicating code for every night. Validate that essential objectives remain reachable under the night's possible failures.

## 9. ENEMY 01 — THE WATCHER

An original surveillance automaton with an angular sensor head, exposed cabling, and a narrow asymmetrical silhouette. It should read clearly at camera distance without resembling a recognizable FNAF character.

Behavior:

- Starts at a configured staging node after the tutorial grace period.
- Travels through a authored route graph toward the office.
- Pauses route advancement when its occupied node is covered by a valid observed camera feed.
- Moves only after its movement interval and observation conditions permit.
- Provides a recognizable mechanical cue before the final approach.
- Retreats or waits according to a defined rule when the office door blocks it.
- Causes failure only after the attack state and configured reaction window permit it.

For the first slice, the server owns the accepted camera selection, tablet-open state, power state, and feed availability. Validate camera IDs and require a short selection dwell before observation counts. Rate-limit switching. Do not use screenshot recognition to decide whether an enemy is observed, and do not accept arbitrary client-submitted enemy positions.

Use a small FSM such as Dormant, Traversing, Observed, Approaching, DoorBlocked, Attacking, and Retreating. Record every transition with a reason in development mode. Use a seeded random generator for repeatable route and timing tests.

The office door blocks traversal on the server as well as in presentation. Use sensible movement, animation, or intentionally staged camera cuts. Avoid visible instant teleportation between adjacent rooms.

## 10. ENEMY 02 — THE HOLLOW

A damaged maintenance machine with a low, heavy silhouette and a distinct dragging-footstep rhythm.

It investigates server-validated noise events within configured hearing range, follows plausible routes, searches the last known disturbance area, and eventually returns to patrol. It does not automatically know the player's position through walls.

Counterplay includes quiet movement, choosing when to run noisy equipment, and a limited distraction device. Distractions require range, cooldown, current-state, and resource validation. Its audio warning should be learnable and distinguishable from ambience.

Use Patrolling, Investigating, Searching, Pursuing, Retreating, and Disabled as appropriate. Bound pathfinding requests, handle blocked paths, cancel stale paths, and avoid recomputing a route every frame.

## 11. ENEMY 03 — THE SIGNAL

A hostile infrastructure intelligence presented through original diagnostic anomalies, moving indicator patterns, and a physical relay device or original machine when needed.

The Signal disrupts selected cameras or equipment. Every disruption has an identifiable state, a duration or repair condition, and a clue that allows diagnosis. It may create false alarms, but it must not make all information meaningless.

Give real threats and false alarms at least one consistent way to tell them apart. Provide a readable repair interaction and preserve a fallback path when a required device fails. Essential warning cues must still work when reduced flashing or audio accessibility options are enabled.

Keep enemy gameplay authority on the server. Clients render effects from the accepted state. Do not let a visual noise effect accidentally change power, objectives, or completion state.

## 12. ENVIRONMENT AND OFFICE LAYOUT

Begin with a local coordinate plan so rooms align consistently. Treat these dimensions as starting design values, not existing project facts.

- Office interior: approximately 26 × 20 studs, with a 12-stud ceiling.
- Desk and monitor: positioned to keep the door, monitor interaction, and hallway light easy to find.
- Primary hall: approximately 10 studs wide, with a clear final-approach sightline.
- Maintenance branch: a visibly different material and light treatment.
- Camera alcoves: anchored fixed points with meaningful room coverage.
- Enemy route markers: developer-visible nodes that can be hidden in production.

The first six camera areas are Lobby, Showroom, Storage, Service Hall, Electrical Room, and Office Approach. Add rooms only when their gameplay purpose is clear.

Use layered detail: architecture first, major equipment second, props third, wear last. Give each room one memorable feature. Keep walking paths, attack cues, repair targets, and door state readable. Doors need collision, pivot, movement, and visual state that agree.

The complete facility may later include a ventilation service area, an underground research laboratory, and an emergency exit sequence. Do not build an enormous unused map before the security loop works.

## 13. ART AND LIGHTING DIRECTION

Use charcoal interiors, desaturated metal, aged green control panels, warm desk-light pockets, cold service lighting, and restrained red warning accents. Silence and negative space are part of the art direction.

Create contrast through light placement and silhouettes. Preserve enough visibility to navigate and read necessary devices. Check the office and every final-approach camera at realistic graphics quality settings.

Use supported lighting, materials, atmosphere, and post-processing after checking current engine documentation. Keep one owner for shared Lighting changes so assistants do not stack competing effects. Avoid prescribing deprecated technology settings without verification.

Choose lights and shadows deliberately. Use optional graphics presets when useful. Depth of field, bloom, fog, camera shake, and flicker must support the scene and remain adjustable. A low preset must preserve the information required to survive.

## 14. SURVEILLANCE IMPLEMENTATION

For the first slice, switch the player's local CurrentCamera to anchored camera points while the tablet is open. Store the previous camera mode and restore it on closing, failure, victory, respawn, or leaving the session.

Each camera entry needs a stable ID, display name, world point, coverage mapping, and availability state. Validate these at startup. Use a static facility schematic built from native GUI elements and a selected-camera highlight.

Do not assume a ViewportFrame can render the live Workspace from an unrestricted second camera. If a later feature uses ViewportFrame scene replicas, justify its scope and replication cost explicitly. Avoid cloning the whole map into every camera feed.

Handle missing camera points, disconnected feeds, destroyed characters, rapid toggles, streaming visibility, and stale transitions. If streaming is enabled, verify that every feed's required room and enemy are present before declaring the camera system complete.

Static is a controlled visual treatment. It must not obscure critical labels, flash continuously, or consume unnecessary frame time. An unavailable feed should clearly say that it is unavailable.

## 15. POWER, DOOR, AND LIGHT MANAGEMENT

Power begins at 100 units. The server computes drain from elapsed time and active devices. Use one authoritative update owner and replicate useful state at a bounded frequency.

Initial balancing proposal for a 480-second Night 1:

| Device | Starting drain |
| --- | --- |
| Facility baseline | 0.08 power units per second |
| Open camera tablet | Additional 0.04 units per second |
| Closed security door | Additional 0.16 units per second |
| Active inspection light | Additional 0.08 units per second |

These values are an authored starting point and require playtesting. Baseline alone consumes 38.4 units over eight minutes. Keeping the door closed throughout the shift must be unsustainable; thoughtful short uses should remain practical.

Show the active sources of drain through a usage indicator or device status. Provide thresholds at useful intervals such as 25 and 10 units. At zero, open or release the powered security door, disable powered equipment, switch to the configured fallback, and leave the player with a clearly defined survival possibility or loss sequence.

Do not repeatedly charge a motor cost on duplicate requests. Clamp power to its valid range. Resolve same-frame state changes consistently. Client animations may react immediately, but accepted server state controls the actual mechanic.

## 16. UI / UX AND FORGEGUI ASSETS

Create a restrained industrial interface with clear typography, limited decoration, consistent spacing, and one main action per screen. Suggested design colors:

| Token | Starting color |
| --- | --- |
| Background | #101419 |
| Panel | #1B232B |
| Main text | #E8EDF0 |
| Secondary text | #A2AFB8 |
| Normal signal | #80B5A0 |
| Warning | #DDA95B |
| Danger | #D75E5E |

These are visual design choices. Tune them after observing the UI in-engine. Avoid tiny simulated CRT lettering for essential information.

Screens:

- Main menu: Play, Continue, Night Selection, Settings, Achievements, Credits.
- Gameplay HUD: night, time, power, active device usage, objective, contextual interaction.
- Surveillance: camera name, map selection, signal condition, close control, relevant device warnings.
- Settings: audio categories, motion intensity, reduced flashing, sensitivity where supported, graphics preset.
- Outcome: clear cause or success, retry, and return-to-menu action.

Use native TextLabels and interactive Roblox controls for all changing information and inputs. ForgeGUI supplies decorative panel art, icons, textures, and consistent framing. Do not bake the changing power percentage, camera labels, objective text, or buttons' hit areas into a flattened screenshot.

Use layouts, scale constraints, safe-area handling, and deliberate text sizing. Keep the close/back action independent of scrolling content. Handle keyboard, mouse, touch, and controller. Preserve selected focus and restore it when overlays close.

Define closed, opening, open, switching-feed, unavailable, pending, error, and outcome states as needed. Own and cancel tweens so repeated input does not produce overlapping animations. Clean event connections on destruction and respawn.

## 17. READY-TO-USE FORGEGUI PROMPTS

Claude should attach the relevant downloaded reference photos when the active ForgeGUI workflow supports image references. Use original visual motifs and adapt the requested output to the live schema. Dimensions below are target deliverables, not asserted tool parameters.

SURVEILLANCE FRAME

Create original decorative artwork for a Roblox security-horror surveillance interface. Target a 1920 × 1080 composition with transparent center and transparent background where supported. Use worn charcoal metal, restrained aged-green indicators, thin industrial borders, and subtle analog-monitor detailing. Keep the middle mostly clear for a live camera view. Reserve clean spaces for native camera-name text, power text, signal status, a compact map, and a close control. No logos, copyrighted characters, rendered percentage values, or tiny baked-in labels. Keep the layout readable on a scaled desktop or touch display. Match the selected CRT and machinery references through shape and material rather than copying their exact products.

SECURITY ICON FAMILY

Create a consistent original icon family for camera, door, inspection light, power, maintenance wrench, warning, audio, settings, and exit. Deliver individual transparent images when supported; target 512 × 512 per icon with generous padding. Use clear industrial silhouettes, subdued off-white with one aged-green or amber accent, and minimal texture. Every icon should remain distinct at about 32 pixels. No text or brands. Produce one sample for approval before committing to the full family.

OFFICE PANEL ART

Create an original worn-metal decorative frame for a Roblox security-office HUD panel. Transparent background, readable silhouette, restrained screws and edge wear, charcoal surfaces, warm amber status-light accents. Keep a generous empty central region for native text. Avoid photorealistic clutter, thick ornamental borders, fake interactive controls, or baked-in labels. If the result is intended for nine-slice scaling, inspect and define its actual content borders after generation rather than guessing slice rectangles.

THE WATCHER CONCEPT

Design an original abandoned surveillance automaton for a Roblox horror game. Narrow angular sensor head, offset lens housing, asymmetrical chest plate, exposed joints and limited cabling, aged neutral metal with a single muted-green status point. Strong readable silhouette at corridor distance. No animal mascot face, no FNAF likeness, no gore, no weapon. Use the security-camera and machine references for plausible hardware detail. If a 3D route is supported, specify the required scale, pivot, collision, and rig needs separately. Do not assume that a generated mesh arrives rigged or animated.

ELECTRICAL REPAIR PANEL

Create an original industrial repair-panel concept inspired by the circuit-board references. Three clearly separated circuit groups, sturdy housing, readable fuse positions, strong amber/green status-light contrast, restrained wear. Keep actual puzzle labels and changing indicators as native Roblox objects. No real brand marks, tiny paragraphs, or false UI controls. The gameplay solution must be implemented and verified in Luau independently of the artwork.

## 18. CAMERA, INPUT, AND INTERACTIONS

Use a reliable first-person camera implementation with a clear input owner. Motion effects are subtle and optional. Exiting a camera feed, dying, winning, or returning to the menu must restore valid camera and control state.

Create a reusable interaction layer for doors, terminals, lights, repair panels, documents, and objective items. ProximityPrompt is a practical default for world interactions when suitable.

Validate player identity, distance, eligibility, target ID, current state, cooldown, and allowed action on the server. Check the value types and bounds of every client request. Do not let a client choose arbitrary instance paths, enemy positions, damage, power, or progression.

Provide equivalent meaningful actions across supported input types. Avoid making a fast mouse-only mechanic essential without a usable controller or touch alternative. Handle interrupted interactions and remove stale prompts when a target becomes unavailable.

## 19. AUDIO, SUSPENSE, AND ACCESSIBILITY

Use distinct audio roles: ambient electrical hum, room tone, ventilation, Watcher movement, Hollow footsteps, camera switching, power warnings, door movement, repairs, and restrained narrative recordings.

Threat cues must be recognizable and consistent. Use positional sound where appropriate and avoid mixing all categories at maximum volume. Distinguish imported audio availability from audible playback in the target experience.

Build suspense from anticipation, silence, partial information, and environmental changes. A jumpscare is a consequence of a understood encounter rule. Keep audio peaks controlled and provide intensity reduction options.

Include settings for reduced flashing, reduced camera motion, and separate audio categories. Caption important information or provide an equivalent visual cue. Essential survival information must remain available with accessibility options enabled. Avoid graphic violence and gore.

Tell the story through room changes, documents, short recordings, and believable equipment states. Do not interrupt every shift with long exposition. Track collected lore separately from temporary night objectives.

## 20. SERVER ARCHITECTURE AND DATA

Inspect the existing project first. The following is a target organization, not permission to duplicate or replace existing systems:

```text
ReplicatedStorage
  Nightshift
    Shared
    Config
    Remotes
ServerScriptService
  NightshiftServer
    Bootstrap
    NightService
    EnemyService
    PowerService
    InteractionService
    ObjectiveService
    ProgressionService
StarterPlayer
  StarterPlayerScripts
    NightshiftClient
      Bootstrap
      CameraController
      InputController
      HUDController
      EffectsController
      AudioController
StarterGui
  MainMenu
  GameHUD
  SurveillanceHUD
  SettingsHUD
ServerStorage
  NightshiftAssets
    EnemyTemplates
    EnvironmentTemplates
Workspace
  Map
  CameraPoints
  InteractionPoints
  RouteNodes
  RuntimeEntities
```

Use stable IDs and explicit module contracts. Keep authoritative rules on the server, shared configuration free of secrets, and client modules focused on input and presentation. Separate bootstrap/start from cleanup so each run can initialize and end cleanly.

Night state should explicitly distinguish Waiting, Starting, Active, Won, Lost, and Resetting. Use a run identity to ignore late callbacks from a previous run. Emit victory once. A dead player's delayed action must not mutate a new night.

Persist versioned progression: completed nights, unlocked modes, achievements, lore, and appropriate settings. Use bounded retries, safe validation, conflict-aware ownership, and responsible save handling. Never save defaults over a failed load as if it succeeded. Progress comes from server-verified events.

Keep temporary run state out of the persistent profile. Treat load failure and save failure as explicit conditions with usable feedback. Do not turn Studio API access settings on blindly against production data for a quick test.

For later co-op, define who can control shared devices, how simultaneous requests resolve, how observation counts, and whether a death ends the group run. Handle disconnects without a permanently assigned unreachable objective. Test solo balance independently.

## 21. LUAU QUALITY, FORMATTING, AND PERFORMANCE

Use idiomatic Luau, explicit responsibilities, and practical strict typing. The optional --!strict directive is a compiler directive and may precede the allowed section comments.

Use only these section-comment headings in delivered code:

--//Config//--
--//Service//--
--//Types//--
--//State//--
--//Modules//--
--//Ref//--
--//Functions//--
--//Logic//--
--//UI//--
--//Validation//--
--//Network//--
--//Animation//--
--//Events//--
--//Cleanup//--
--//Init//--

Use roughly five to ten useful sections for medium or long scripts and fewer for small modules. Do not add empty headings, decorative banners, or explanatory inline comments. Explain non-obvious behavior outside the code or in project documentation. Keep spacing compact and readable.

Use task APIs instead of deprecated scheduling functions. Use RunService only where per-frame updates are needed. Rate-limit AI updates, pathfinding, remote requests, and UI replication. Clean connections, scheduled work, temporary instances, and camera bindings.

Profile actual Studio sessions. Report measured bottlenecks and the environment of any measurement. Never invent FPS, memory, network, or mobile performance results.

Reduce unnecessary geometry, shadows, physics, sound instances, effect layers, and replicated state. Keep decorative objects anchored when appropriate. Avoid cloning large scenes for camera feeds. Configure streaming only after verifying its interaction with surveillance and enemy visibility.

## 22. TEST AND ACCEPTANCE PLAN

Claude owns acceptance. Codex may run assigned checks and report results. Distinguish source review, automated checks, Studio runtime tests, visual inspection, device emulation, and real-device tests. None is evidence that all the others passed.

Run meaningful checks for the changed feature. Repeat broader checks when a new change or failure justifies them.

First-slice scenarios:

- Start a night from a clean state and complete the tutorial.
- Select all six feeds and confirm names, viewpoints, and room coverage.
- Observe the Watcher, stop observing, and verify the expected transitions.
- Close the door during final approach and verify the blocking rule.
- Reopen the door and verify the reaction grace period and failure condition.
- Force low and zero power through developer-only controls and verify fallback.
- Win once, then retry; lose once, then retry.
- Toggle the monitor repeatedly and respawn while it is open.
- Submit invalid IDs and rapid interaction requests; verify rejection without errors.
- Exercise the relevant touch and controller controls.
- Disable flashing and motion; verify essential cues remain usable.
- Test unavailable assets or camera points and report any remaining dependency.

Add seeded scenario controls for testing: night speed, enemy route/timing, starting power, and visible state logs. Guard debug controls so ordinary players cannot invoke them in production.

Progression checks later include a failed load, failed save, disconnect, server shutdown, duplicate achievement trigger, and simultaneous shared-device input where co-op exists.

A milestone is complete only when the specified behavior exists, its dependencies are available, it integrates, relevant tests have been run or clearly marked pending, and unresolved limitations are disclosed.

## 23. ROADMAP AND DELIVERY EXPECTATIONS

Phase A — Inspect and prepare: Identify existing systems, verify connections, choose ownership boundaries, and write the first slice's contracts.

Phase B — Playable slice: Implement the compact office, six camera points, Watcher, power, door, light, night state, outcome, and retry.

Phase C — Presentation pass: Use approved ForgeGUI assets; improve office composition, interface, enemy silhouette, sound, and transitions. Verify results in-engine.

Phase D — Expand: Add Hollow, Signal, repair objectives, additional nights, lore, and deliberately scoped co-op if requested.

Phase E — Persistence and polish: Add reliable saving, achievements, settings, accessibility, improved tutorial, and measured optimization.

Phase F — Release preparation: Run progression and device checks, tune difficulty, document known issues, and prepare original icon, thumbnail, description, and credits. Follow current platform requirements before publishing.

Do not call a concept image, generated model, or pasted script a finished gameplay system. Show the result and explain what changed, what was verified, and what remains.

## 24. FIRST MESSAGE AND FIRST ACTION FOR CLAUDE

Begin with:

"I am the lead developer for NIGHTSHIFT. Codex is my helper and will work on the bounded tasks I assign. I will inspect the existing project, verify the ForgeGUI and Studio connections, and build one complete playable Night 1 before expanding. I will use the supplied reference photos to guide original assets and preserve the project's existing work."

Then take action:

1. Read the current project and identify the correct place or repository.
2. Identify existing managers, UI owners, and active tasks.
3. Verify the available ForgeGUI and Studio capabilities without spending credits.
4. Inspect the relevant supplied reference photos.
5. Write a concise Night 1 implementation plan and contracts.
6. Assign Codex one concrete independent task with exact paths and checks.
7. Implement the lead-owned slice systems and integrate accepted handoffs.
8. Run the available acceptance scenarios, inspect the presentation, and report evidence.

If live tools are unavailable, deliver complete integration-ready work for the assigned scope with exact setup instructions. State which Studio and ForgeGUI steps remain unexecuted. Continue useful authorized work rather than stopping at a proposal.

The goal is a polished, original horror game built through real implementation and verified milestones, with Claude leading and Codex helping.

---

## TOOL AND SOURCE NOTES

Tool details were checked on October 9, 2026. Capabilities and setup can change; inspect current documentation and live tool schemas before executing.

- ForgeGUI service: https://forgegui.com/
- ForgeGUI product documentation: https://forgegui.com/docs
- Claude Code integration repository and setup notes: https://github.com/elwinhe/forgegui-plugins and https://github.com/elwinhe/forgegui-plugins/blob/release/claude-mcp-v1/SETUP.md
- Official Studio MCP documentation: https://create.roblox.com/docs/studio/mcp
- Photo source and usage information: https://unsplash.com/license and REFERENCES.md in this pack.

The ForgeGUI documentation describes reference-guided image/UI production and export formats. The integration repository documents a separate connection for Claude Code and free discovery before generation. The Studio documentation describes its own MCP connection. This file does not certify that those connections are installed or working on the user's machine.
