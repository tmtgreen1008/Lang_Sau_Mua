## Architecture Review Report
Date: 2026-10-27
Mode: full
Workflow: standard
Engine: Godot 4.7 (pinned; 4.7.2 installed)
GDDs Reviewed: 6 system GDDs (plus game-concept.md and systems-index.md as context)
ADRs Reviewed: 1

Reviewed-Content-Hash: docs/architecture/adr-0001-save-format-and-safe-write.md 49746c3af827d59d94493f88c8225947cfb948b1
Reviewed-Content-Hash: design/gdd/farming-system.md e3822e52e7e58cbab0f7df928b89e3f777c3e268
Reviewed-Content-Hash: design/gdd/game-concept.md 0ddf7f08a4570b946fbd425d00981c6ba610dc60
Reviewed-Content-Hash: design/gdd/market-system.md 4a525b4329674cb46d509771e8529bc8cfa56ef7
Reviewed-Content-Hash: design/gdd/neighbors-system.md e41d007d4b6841cdc5aabe17bc0562c51c063c71
Reviewed-Content-Hash: design/gdd/player-system.md a835a83295a28fb7d9f9f0b5b1956a6fa446f358
Reviewed-Content-Hash: design/gdd/systems-index.md 77c45b2927801e892da3ebb7cfdf4e4b91dbaac9
Reviewed-Content-Hash: design/gdd/time-system.md 3cf58a9eccf56335d9868a8564b8716cd833c299
Reviewed-Content-Hash: design/gdd/village-restoration.md 90dd4aa07c0dc6ceacdeba8920cce6cfdc5ffa7c
Reviewed-Content-Hash: docs/architecture/tr-registry.yaml d355a205769e094f064fe2050962cff04744999b
Reviewed-Content-Hash: docs/engine-reference/godot/VERSION.md 9fcd73640cb1b805649d60e7119d9db5d40d62c9
Reviewed-Content-Hash: docs/engine-reference/godot/breaking-changes.md 4bc55e16796664ff88c7582c9f08e3530f7c94d4
Reviewed-Content-Hash: docs/engine-reference/godot/current-best-practices.md a45cd2c39a8ec53eaa3e924f39f93594e62085fd
Reviewed-Content-Hash: docs/engine-reference/godot/deprecated-apis.md 6a1353983e1db0d7bc0cc41a568b039495b5413c
Reviewed-Content-Hash: docs/engine-reference/godot/modules/animation.md ee51f50a46f8c63b771f62fe438947d4d84c59e3
Reviewed-Content-Hash: docs/engine-reference/godot/modules/audio.md c72af247505908a04f84a1dd3e765939efe700bd
Reviewed-Content-Hash: docs/engine-reference/godot/modules/input.md 3406b1b813858898696e510ea0accfcc7df98af8
Reviewed-Content-Hash: docs/engine-reference/godot/modules/navigation.md 7ae18ffbd2c3230cb19d610373225bfba187a472
Reviewed-Content-Hash: docs/engine-reference/godot/modules/networking.md 6606880462a2241014f77feb9610c5611e659ec6
Reviewed-Content-Hash: docs/engine-reference/godot/modules/physics.md 3b6ac8947f3f3e8c9ac9e6e0ff6cac06fdb8d805
Reviewed-Content-Hash: docs/engine-reference/godot/modules/rendering.md 2a303185bb57eed31dd1151a036784820747b211
Reviewed-Content-Hash: docs/engine-reference/godot/modules/ui.md 30ad166ab8c4e92c15aa37ed3464483b92b7845b
Reviewed-Content-Hash: project.yaml ea40dc3babbef57702cd4d4992799325527ab6bb
Reviewed-Content-Hash: .claude/docs/technical-preferences.md fe66ec65654604fd1968e023b4c52e4917645c87
Reviewed-Content-Hash: .claude/skills/architecture-review/SKILL.md 1a9d28aadbcbd26b5fc6b8ed1c64d73ae82b7b73
Reviewed-Content-Hash: .claude/skills/architecture-review/references/1-load.md 9a65759ebdbb2cb1f9744775bfed18cb25e76347
Reviewed-Content-Hash: .claude/skills/architecture-review/references/2-extract-requirements.md d08ea0b0e9ab9760b0d8bfe0cd9115f0bc40f8e2
Reviewed-Content-Hash: .claude/skills/architecture-review/references/3-traceability.md bb7b6b65c5e5e5b8869fa692413aa831615dede7
Reviewed-Content-Hash: .claude/skills/architecture-review/references/4-conflicts.md 0d30f8173b23248a32523a365b606dd1ce9642ab
Reviewed-Content-Hash: .claude/skills/architecture-review/references/5-engine.md 318ecbc1361d430badaf5dd8ce4cfc6ab0dff0ca
Reviewed-Content-Hash: .claude/skills/architecture-review/references/6-document-coverage.md dcce78482ec2ce60048989b6f9d1f797dd0a9a0e
Reviewed-Content-Hash: .claude/skills/architecture-review/references/7-report.md a007fd66bdac87812dc272e4b14cd231174e979d
Reviewed-Content-Hash: .claude/skills/architecture-review/references/8-write.md bf6d8946fc7b9e19eda7f65503a5c8f593a0d2b1
Reviewed-Content-Hash: .claude/skills/architecture-review/references/9-handoff.md fd5f681f4c3517c6a2e388c6d78075d82dded22e

Not stamped (no such file): docs/architecture/architecture.md, docs/consistency-failures.md.

---

### Loading notes
- The Phase 1b section scan matched 0 of 6 GDDs (numbered headings, e.g. `## 3. Detailed Design`). All six were read in full (about 6 KB each).
- NOT ASSESSED: three MVP systems have no GDD (crop data, HUD and panels, phone display), so no requirements could be extracted for them.
- Phase 3b (story and test linkage) not run in full: the 6 stories carry no TR-IDs (registry was empty), and `tests/` does not exist.

### Traceability Summary
Total requirements: 28
✅ Covered: 5
⚠️ Partial: 0
❌ Gaps: 23

Full matrix: `docs/architecture/requirements-traceability.md`. IDs registered in `docs/architecture/tr-registry.yaml` (28 new entries; `registry.sh validate` clean).

### Coverage Gaps (no ADR exists)
1. Cross-system wiring: signals and injection through `Main`. Covers time-003, farm-003, farm-005, market-004, neighbors-003, neighbors-004, village-004, player-003. Engine risk LOW. `/architecture-decision cross-system-wiring`
2. Data-driven content under `assets/data/`: loading and validation. Covers time-002, farm-002, market-002, neighbors-001, village-001, player-002. Engine risk LOW. `/architecture-decision data-driven-content`
3. Clock and app lifecycle: delta clamp, pause on panels and in background. Covers time-001, time-004. Engine risk HIGH. `/architecture-decision clock-and-app-lifecycle`
4. Phone display and input: stretch, landscape lock, touch, 72 px targets. Covers player-001, market-003. Needs a display GDD first. Engine risk HIGH.
5. Later: player-004 (obstacle pathing), farm-001 (cell schema), village-003 (reveal effect), market-005 and neighbors-005 (intent only).

### Cross-ADR Conflicts
None: only one ADR exists.

### ADR Dependency Order
`adr-dep-graph.sh`: 1 ADR, no edges, `NO_DEPS_SECTION: adr-0001` (the ADR has no parseable `ADR Dependencies` heading; its body says none). Order: ADR-0001 (Foundation).

### GDD Revision Flags
| GDD | Assumption | Reality | Action |
|---|---|---|---|
| time-system.md | Intent "clock stops while the app is away" assumes no large delta on resume | `day_clock.gd:87-97` loops every day crossed and `main.gd:281` passes raw delta. Whether 4.7 caps the first delta is NOT SOURCEABLE in the engine reference (specialist expects no cap; training data, unverified) | Revise: require a delta clamp or resume reset |
| neighbors-system.md | §6 says neighbors call the market's `add_money` | Systems index says `Main` routes the reward and neighbors never call the market; `main.gd:343` agrees | Revise wording |

The systems-index update for these flags was not requested in this run and was not made.

### Engine Compatibility Issues
Engine: Godot 4.7. ADRs with an Engine Compatibility section: 1 / 1. Deprecated API references: none. Stale version references: none. Post-cutoff API conflicts: none (ADR declares no module references, so no module docs were read).

NOT SOURCEABLE: `NOTIFICATION_*` lifecycle names, rename-over-existing semantics, `flush()` vs `fsync`, Android Back-button notification and first-delta-after-resume behaviour are not covered by `docs/engine-reference/godot/`.

Engine specialist (godot-specialist) findings. Items 4 to 8 rest on training data (unverified):
- Confirmed: `store_*` returns bool (`breaking-changes.md:91`) and the code checks it; no deprecated-API matches; notification names absent from the reference.
- HIGH: no clamp on the delta passed to the clock (`day_clock.gd:87-97`, `main.gd:281`).
- MEDIUM: rename-over-existing atomicity unsourced and `.tmp` recovery missing (`save_game.gd:116-118`).
- MEDIUM: `flush()` is not `fsync`; a power cut could leave an empty file that is then renamed to the corrupt file. Keep `.bak` as last good save and fall back to it.
- MEDIUM: a transient read error (`""`) is treated as corruption (`save_game.gd:69`).
- MEDIUM: Android Back sends `NOTIFICATION_WM_GO_BACK_REQUEST`, not `WM_CLOSE_REQUEST`; add it and test on a device.
- LOW: ADR relies on the `auto_accept_quit` default (record it).
- LOW: `PAUSED` plus `FOCUS_OUT` double-save on Android.

### Architecture Document Coverage
**NOT ASSESSED**: `docs/architecture/architecture.md` does not exist.

---

### Verdict: FAIL

Foundation-layer requirements are uncovered (cross-system wiring, data-driven loading, clock and lifecycle). At `standard`, Foundation ADRs are critical. Separately, Phase 6 and three GDD-less systems are NOT ASSESSED, so PASS was unreachable regardless. The verdict is advisory.

### Blocking Issues (must resolve before PASS)
- No ADR for cross-system wiring.
- No ADR for data-driven content loading.
- No ADR for clock and app lifecycle.
- No `docs/architecture/architecture.md` (`/create-architecture`).

### Required ADRs
1. Cross-system wiring (Foundation)
2. Data-driven content (Foundation)
3. Clock and app lifecycle (Foundation, engine risk HIGH)
4. Phone display and input (needs a display GDD first)
