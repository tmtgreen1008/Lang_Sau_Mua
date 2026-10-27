# Architecture Traceability Index
Last Updated: 2026-10-27
Engine: Godot 4.7

IDs use the registry slugs (`TR-neighbors-001`, `TR-village-001`), shown here as `neighbors-001`, `village-001`.
Only ADR-0001 (Accepted) exists. Systems with no GDD (crop data, HUD and panels, phone display) are NOT ASSESSED: no requirements could be extracted.

## Coverage Summary
- Total requirements: 28
- Covered: 5 (18%)
- Partial: 0
- Gaps: 23

## Full Matrix

| TR-ID | GDD | Requirement | ADR | Status |
|---|---|---|---|---|
| TR-time-001 | time-system.md | tick(delta) driven from outside, no system clock | — | ❌ GAP |
| TR-time-002 | time-system.md | Config from time_config.json, invalid config fails safely | — | ❌ GAP |
| TR-time-003 | time-system.md | Signal order season, phase, day; Main wires day signal | — | ❌ GAP |
| TR-time-004 | time-system.md | Large delta / panel open / background must not skip days | — | ❌ GAP |
| TR-time-005 | time-system.md | Day, phase, elapsed persist | ADR-0001 | ✅ |
| TR-farm-001 | farming-system.md | 5x4 cell state schema | — | ❌ GAP |
| TR-farm-002 | farming-system.md | Crop data from crops.json via CropDatabase | — | ❌ GAP |
| TR-farm-003 | farming-system.md | advance_day and season pushed by clock via Main | — | ❌ GAP |
| TR-farm-004 | farming-system.md | Cells and inventory persist | ADR-0001 | ✅ |
| TR-farm-005 | farming-system.md | Crop-unlock check is an injected Callable | — | ❌ GAP |
| TR-player-001 | player-system.md | Touch and mouse input; emulated mouse ignored | — | ❌ GAP |
| TR-player-002 | player-system.md | Constant speed, frame-rate independent, speed from data | — | ❌ GAP |
| TR-player-003 | player-system.md | Map taps blocked by open panel or HUD | — | ❌ GAP |
| TR-player-004 | player-system.md | Path around obstacles (intent) | — | ❌ GAP |
| TR-market-001 | market-system.md | Money persists | ADR-0001 | ✅ |
| TR-market-002 | market-system.md | Prices from crops.json | — | ❌ GAP |
| TR-market-003 | market-system.md | Touch targets ≥72 px; dim layer blocks input | — | ❌ GAP |
| TR-market-004 | market-system.md | Inventory and money signals refresh HUD | — | ❌ GAP |
| TR-market-005 | market-system.md | Seed purchase, seasonal price from data (intent) | — | ❌ GAP |
| TR-neighbors-001 | neighbors-system.md | neighbors.json loads with validation | — | ❌ GAP |
| TR-neighbors-002 | neighbors-system.md | Request state, unlocks persist | ADR-0001 | ✅ |
| TR-neighbors-003 | neighbors-system.md | Village level via injected provider | — | ❌ GAP |
| TR-neighbors-004 | neighbors-system.md | request_completed signal; Main routes reward money | — | ❌ GAP |
| TR-neighbors-005 | neighbors-system.md | Requests accept any item type (intent) | — | ❌ GAP |
| TR-village-001 | village-restoration.md | Pieces and levels from JSON with validation | — | ❌ GAP |
| TR-village-002 | village-restoration.md | Progress persists; load renders without effect | ADR-0001 | ✅ |
| TR-village-003 | village-restoration.md | Reveal deferred while panel open; reduce-motion | — | ❌ GAP |
| TR-village-004 | village-restoration.md | Driven by request_completed | — | ❌ GAP |

## Known Gaps (suggested ADRs, most foundational first)
1. Cross-system wiring: signals and injection through `Main` — time-003, farm-003, farm-005, market-004, neighbors-003, neighbors-004, village-004, player-003. `/architecture-decision cross-system-wiring`
2. Data-driven content under `assets/data/`: loading and validation — time-002, farm-002, market-002, neighbors-001, village-001, player-002. `/architecture-decision data-driven-content`
3. Clock and app lifecycle: delta clamp, pause on panels and in background — time-001, time-004. Engine risk HIGH (lifecycle behaviour is NOT SOURCEABLE in `docs/engine-reference/godot/`). `/architecture-decision clock-and-app-lifecycle`
4. Phone display and input — player-001, market-003. Needs a display GDD first. Engine risk HIGH.
5. Later: obstacle pathing (player-004), cell schema (farm-001), reveal effect (village-003), intent-only items (market-005, neighbors-005).

## Superseded Requirements
None. First registration of all 28 IDs.
