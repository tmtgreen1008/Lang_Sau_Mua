# Test Evidence: Khởi động Main và màn hình lỗi khởi động

> **Scope**: refactor of `Main` (ADR-0002, ADR-0003, ADR-0004), giai đoạn B và D (commits `8eebd3b`, `7249618`) và bản sửa màn hình lỗi khởi động
> **Story Type**: UI (retained screenshots)
> **Date**: 2026-10-27
> **Tester**: Claude (windowed run of the real `Main`, frames recorded with `--write-movie`); lead sign-off by the developer is still to do
> **Build / Commit**: screenshots 01 on `7249618`; 02 and 04 on the commit that fixes the overflow (the one that adds this line); 03 is the "before" picture on `7249618`

Screenshots live in `production/qa/evidence/main-refactor-startup-and-error-screen/`; `stamp.txt` there
hashes the source files (and the error screen test) they prove.

---

## How the run was done

`godot --path . --windowed --resolution 1280x720 --write-movie <path>.png --quit-after 60 -s <capture script> -- <scenario>`

The capture script is a scratch file outside the repo. It creates the real `Main` and points its two
test seams (`_save_game`, `_data_dir`) at throwaway folders under `user://`, so the player's own save and
the shipped data files were never read or written by the run. The last of 60 frames is kept (1152x648,
the project's viewport size). Scenarios:

| Scenario | Data | Save |
|---|---|---|
| `main` | shipped data files, unchanged | the frozen `tests/fixtures/saves/v1.json` copy |
| `error` | copy of the data with `crops[0].growth_days = 0`, `crops[1].sell_price` removed, `player.speed = 0` and `time_config.json` cut off mid-file | none |
| `many` | copy of `crops.json` with 12 crops that each have `growth_days = 0` | none |

---

## Results

| # | Screenshot | What it must show | Result |
|---|---|---|---|
| 1 | `01-main-screen-fixture-v1.png` | The loaded save on every display: bag "Ngô: 3", money 25, "Ngày 2 - Sáng - Mùa hạ", a planted corn tile and a tilled tile on the field, the village at its ruined level, the stall, three neighbors, the tool and crop buttons | **PASS** |
| 2 | `02-startup-error-4-files.png` | Vietnamese title, the "kiểm chéo bị bỏ qua" note naming the three files that failed, then each error with its file and place, one per line; no game underneath | **PASS** (see notes) |
| 3 | `03-before-fix-12-errors-overflow.png` | *Before the fix.* With more than 10 errors: at most 10 listed, then "và N lỗi khác", all on screen | **FAIL** (kept as the record of the defect): the text ran off the bottom after 7 errors and "và N lỗi khác" was not visible |
| 4 | `04-startup-error-12-errors-fixed.png` | The same 12-error case after the fix | **PASS**: the note plus 9 errors (10 lines, the cap), then "và 3 lỗi khác", everything inside the 648 px screen with about 200 px to spare |

### The defect from screenshot 3, and its fix

A blank line followed every error, so one error took two text lines at 24 px, and the list needed 848 px
(measured: 23 lines of 34 px) on a 648 px screen. Neither the format tests (they check the text) nor the
integration tests could see it. The fix:

- one newline between errors instead of two (`format`);
- the list font 20 px instead of 24 px;
- the text sits in a vertical `ScrollContainer` (horizontal scrolling off), so one very long message is
  still reachable.

Tests added first and seen failing: no blank line between errors; ten errors plus the "more" line fit the
project's window height; the text is inside a vertical scroll area; the font is at most 20 px.

A trap found on the way: the first version of the fit test passed on the old code, because the headless
test viewport is 1152 x 1152 and not the game's 1152 x 648. The test now reads the window height from the
project setting `display/window/size/viewport_height`.

### Notes on screenshot 2

- The time_config.json parse error shows the full path (`user://capture_main/data/time_config.json`) while
  the other errors show only the file name, because `DataLoader` uses the path it was given as the source.
  In the shipped game that path is `res://assets/data/time_config.json`. Cosmetic.
- The error details are the developers' English messages under a Vietnamese title and note. This follows
  ADR-0002 rule 9 (Vietnamese text written in the code, no localization system yet); it is a known gap, not a regression.
- The note line and the first error are now on consecutive lines without a blank line between them;
  readable, but a visual separator could be added later.

### Not covered

- No Android device run (ADR-0004 and ADR-0005 verification items still open).
- The retry and new-game choices on the error screen do not exist yet (waiting for the UI ADR).
- The scroll area was verified by a test, not by a screenshot of a scrolled view.
- The message line (HUD) and the panels were not captured; they are unchanged by this work except for the
  message time now coming from `game_config.json`.
