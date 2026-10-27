# Adoption Plan

> **Generated**: 2026-10-27
> **Project phase**: Production (inferred: more than 10 source files; `project.stage` not yet set)
> **Engine**: Godot 4.7 (GDScript)
> **Template version**: v1.2.0
> **Workflow tier**: standard (`modes.rigor: standard`, raised from minimal on 2026-10-26)

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

The project was built at the `minimal` tier (one-page brief, six coarse stories, no GDDs or
ADRs). Raising it to `standard` leaves five HIGH gaps, mostly missing documents for systems
that already exist in code.

Totals: BLOCKING 0, HIGH 5, MEDIUM 5, LOW 1.

---

## Step 1: Fix Blocking Gaps

None. No v1.0 config migration is needed (`project.yaml` exists and mirrors the legacy files).

---

## Step 2: Fix High-Priority Gaps

### 2a. Game concept document is missing
`design/gdd/game-concept.md` does not exist (only `design/game-brief.md` and
`design/narrative-outline.md`). The standard tier reads the concept document.
Fix: `/reverse-document concept src/` (feed it the brief and the narrative outline).
**Time**: 30 min
- [x] `design/gdd/game-concept.md` created (2026-10-27, reverse-documented; pillars confirmed by the developer)

### 2b. No GDDs for the seven systems already built
`design/gdd/` does not exist. Systems in code: farming (`src/gameplay/farming`), time
(`src/gameplay/time`), market (`src/gameplay/market`), neighbors (`src/gameplay/neighbors`),
village restoration (`src/gameplay/village`), player (`src/gameplay/player`), save/load
(`src/core/save`). Standard needs 5 sections per system (Overview, Detailed Rules, Edge
Cases, Dependencies, Acceptance Criteria; plus Formulas where there are numeric rules).
Fix, one at a time:
`/reverse-document design src/gameplay/farming`, then `time`, `market`, `neighbors`,
`village`, `player`, and `src/core/save`. Then `/map-systems` to build the systems index.
**Time**: 1 session
- [x] farming GDD (`design/gdd/farming-system.md`, 2026-10-27; two confirmed intents not yet implemented)
- [x] time GDD (`design/gdd/time-system.md`, 2026-10-27; three confirmed intents not yet implemented)
- [x] market GDD (`design/gdd/market-system.md`, 2026-10-27; four confirmed intents not yet implemented)
- [x] neighbors GDD (`design/gdd/neighbors-system.md`, 2026-10-27; four confirmed intents not yet implemented)
- [x] village GDD (`design/gdd/village-restoration.md`, 2026-10-27; four confirmed intents not yet implemented)
- [x] player GDD (`design/gdd/player-system.md`, 2026-10-27; two confirmed intents not yet implemented)
- [x] save/load: written as ADR-0001 instead of a GDD (`docs/architecture/adr-0001-save-format-and-safe-write.md`, Proposed, 2026-10-27); a technical decision rather than a rule of play
- [x] `design/gdd/systems-index.md` created (2026-10-27, 17 systems)

### 2c. No architecture decision records
Critical decisions are undocumented (save file format and safe write, data-driven JSON config
files, display/stretch setup for phones, signal-based wiring through `Main`).
Fix: `/reverse-document architecture src/core/save`, then the others, one ADR each; or
`/architecture-decision` for new ones.
**Time**: 1 session
- [x] save format ADR (`adr-0001-save-format-and-safe-write.md`, Proposed)
- [ ] data-driven config ADR
- [ ] display/stretch ADR

### 2d. TR registry is the empty template
`docs/architecture/tr-registry.yaml` has only the explanatory header, no entries.
Fix: `/architecture-review` (after the GDDs and ADRs exist) bootstraps it.
**Time**: 1 session
- [ ] `tr-registry.yaml` has entries

### 2e. Control manifest is missing
`docs/architecture/control-manifest.md` does not exist, so stories get no layer rules.
Fix: `/create-control-manifest` (after `/architecture-review`).
**Time**: 30 min
- [ ] `docs/architecture/control-manifest.md` created, with a `Manifest Version`

---

## Step 3: Bootstrap Infrastructure

Do in this order, after Step 2:

### 3a. Register existing requirements (creates TR entries)
Run `/architecture-review`.
**Time**: 1 session
- [ ] tr-registry.yaml populated

### 3b. Create control manifest
Run `/create-control-manifest`.
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file
Run `/sprint-plan` (no plan exists yet) for the first expansion sprint.
**Time**: 30 min
- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage
Run `/gate-check` for the phase the project is in.
**Time**: 5 min
- [ ] `project.stage` in `project.yaml` written (legacy `production/stage.txt` also updated)

---

## Step 4: Medium-Priority Gaps

- [ ] **Performance budgets unset.** `performance.*` is empty in `project.yaml`. Set target
  framerate, frame budget, draw-call and memory limits once the target phone is known
  (`/settings`).
- [ ] **Requirements traceability matrix missing.** `docs/architecture/requirements-traceability.md`
  is created by `/architecture-review`.
- [ ] **Stories carry no TR-IDs.** The six finished stories cite "Brief MVP feature N". Do not
  rewrite them; new stories created after Step 3 will carry TR-IDs.
- [ ] **No sprint plan.** Covered by 3c.
- [ ] **Project stage unset.** Covered by 3d.

---

## Step 5: Optional Improvements

- [ ] The six finished stories say `Manifest Version: N/A (minimal — no control manifest)`.
  Leave as is; they are done.

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent, so nothing breaks. They won't benefit from staleness tracking until
regenerated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.

Review mode resolves to `lean` from `modes.rigor: standard`; it is not pinned. To pin a
different depth, use `/settings --local modes.review_mode=<full|lean|solo>`.
