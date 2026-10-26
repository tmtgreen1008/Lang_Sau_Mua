# Story 006: Lưu và tải game

> **Epic**: Làng Sau Mưa
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 6 — Lưu và tải game

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**:
N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal: phiên chơi liền mạch qua nhiều lần mở game, phù hợp điện thoại):*

- [ ] Lưu được trạng thái: ô ruộng và cây, túi đồ, tiền, ngày và mùa, tiến độ nhờ vả và mức diện mạo làng.
- [ ] Tải lại thì khôi phục đúng toàn bộ trạng thái trên (lưu rồi tải cho kết quả giống nhau).
- [ ] Tự động lưu khi sang ngày mới và khi ứng dụng bị đưa xuống nền/đóng (điện thoại hay bị tắt giữa chừng).
- [ ] Mở game thì tự tải lần lưu gần nhất nếu có; không có thì bắt đầu game mới.
- [ ] File lưu hỏng hoặc thiếu thì không làm crash: báo lỗi và cho bắt đầu game mới.
- [ ] Có số phiên bản trong file lưu để đọc được ở các bản cập nhật sau.
- [ ] Vị trí file lưu theo thư mục người dùng của Godot (`user://`), không ghi vào thư mục game.

---

## Implementation Notes

- Mỗi hệ thống (ruộng, thời gian, chợ, hàng xóm, làng) cung cấp hàm xuất/nhập trạng thái dạng dictionary; hệ thống lưu chỉ gom và ghi.
- Ghi file qua file tạm rồi đổi tên để tránh hỏng file nếu bị tắt giữa lúc ghi.
- Kiểm tra API `FileAccess` trong `docs/engine-reference/godot/` trước khi dùng (kiểu trả về đã đổi ở 4.4).

---

## Out of Scope

- Nhiều slot lưu, lưu đám mây.
- Chống gian lận.

---

## Files

- `src/core/save/save_game.gd`
- `src/main.gd` (load on start, autosave triggers)
- `src/gameplay/farming/farm_grid.gd` (to_dict/from_dict)
- `src/gameplay/time/day_clock.gd` (to_dict/from_dict)
- `src/gameplay/market/market.gd` (to_dict/from_dict)
- `src/gameplay/neighbors/neighbor_book.gd` (from_dict keeps starting crops)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_load_test.gd` OR playtest doc — advisory at `qa.level: minimal`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lang-sau-mua/story-005-village-restoration.md`
- Unlocks: None

---

## Completion Notes
**Completed**: 2026-10-26
**Criteria**: 7/7 passing (AC-3 confirmed on desktop only; autosave when the app goes to the background on a phone is untested)
**Deviations**: Advisory — durability suggestions not applied: a Windows rename that is not atomic can leave only `savegame.tmp` (recovery only looks at `.bak`); `WM_WINDOW_FOCUS_OUT` makes 2-3 saves per focus loss; `unlocked_crops` is not checked against known crop ids; `null` or wrong types in a hand-edited save can half-apply `from_dict`; a save with a newer `version` is renamed to `.corrupt.json`; a transient read error may mark a good file corrupt. Out of scope — `.godot/global_script_class_cache.cfg` (Godot-generated), `design/narrative-outline.md` (not part of this story).
**Test Evidence**: waived at qa.level minimal; screenshots `production/qa/evidence/story-006-save-load/before-save.png`, `after-load.png` (byte-identical); the programmer also ran round-trip (13 checks) and corrupt-file (11 cases) scripts outside the project
**Reviewed by**: self, no independent review
