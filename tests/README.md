# Test Infrastructure

**Engine**: Godot 4.7 (4.7.2 installed)
**Test Framework**: GdUnit4
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-10-27

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Installing GdUnit4

GdUnit4 is **not installed yet**. CI and the test command fail until it is.

1. Open Godot → Asset Store (AssetLib before Godot 4.7) → search "GdUnit4" → install it
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: `res://addons/gdUnit4/bin/GdUnitCmdTool.gd` exists (capital U)
5. Commit `addons/gdUnit4/` — CI runs the committed copy (`version: installed`)

## Running Tests

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Run the import first: a fresh clone has no `.godot/` class cache, and a run
without one exits 1 because `GdUnitCmdTool.gd` fails to load, so no test ran.

Exit codes: **0** all pass, **100** a test failed, **101** all passed but a test
leaked nodes (a warning, not a failure), **103/104** gdUnit4 could not run,
**105** a test script does not parse. A run that prints `No test cases found`
exits 0 — that is not a pass. The two `ERROR:` lines about the remote port
`127.0.0.1:0` are expected.

`godot` is not on `PATH` on this machine; use the editor's full path (see
`commands` in `project.yaml`).

## Test Naming

- File: `[system]_[feature]_test.gd`
- Function: `test_[scenario]_[expected]`
- Example: `farm_watering_test.gd` → `test_unwatered_crop_withers_on_new_day()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.
