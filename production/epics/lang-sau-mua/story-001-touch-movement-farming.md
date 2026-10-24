# Story 001: Di chuyển bằng cảm ứng và làm ruộng

> **Epic**: Làng Sau Mưa
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 1 — Di chuyển và làm ruộng: cuốc, gieo, tưới, thu hoạch (3 loại cây)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Check `docs/engine-reference/godot/` before using any API; the pinned editor is not installed yet (see VERSION.md).

**Control Manifest Rules (this layer)**:
N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal & fail state + MVP feature 1):*

- [ ] Chạm màn hình thì nhân vật di chuyển tới vị trí đó trên bản đồ làng (chạm là đầu vào chính, không cần bàn phím hay tay cầm).
- [ ] Cuốc một ô đất trống biến nó thành ô ruộng đã cuốc.
- [ ] Gieo hạt lên ô ruộng đã cuốc, chọn được một trong 3 loại cây.
- [ ] Tưới nước cho ô đã gieo; ô chưa tưới thì cây không lớn.
- [ ] Cây lớn qua các giai đoạn khi ngày mới bắt đầu (qua hàm `advance_day` mà story 002 sẽ gọi tự động).
- [ ] Thu hoạch cây đã chín cho nông sản vào túi đồ; cây chưa chín không thu hoạch được.
- [ ] Không có trạng thái thua: cây không được tưới thì héo và mất vụ, game không kết thúc.
- [ ] Tuỳ chọn 3 loại cây đọc từ file dữ liệu ngoài (không hardcode trong code).
- [ ] Vùng chạm đủ lớn để dùng bằng ngón tay trên điện thoại.

---

## Implementation Notes

- Dữ liệu cây (tên, số ngày lớn, giá bán) để trong resource/JSON riêng, theo quy tắc gameplay data-driven của dự án.
- Giữ logic ruộng tách khỏi node hiển thị để unit test được.
- Dùng GDScript có kiểu tĩnh. Kiểm tra `docs/engine-reference/godot/` trước khi dùng API (Godot 4.7 sau mốc dữ liệu huấn luyện).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: chu kỳ ngày tự động và mùa.
- Story 003: bán nông sản.
- Story 006: lưu và tải.

---

## Files

- `src/main.gd`
- `src/main.tscn`
- `src/gameplay/farming/crop_database.gd`
- `src/gameplay/farming/farm_grid.gd`
- `src/gameplay/farming/farm_view.gd`
- `src/gameplay/player/player.gd`
- `src/ui/hud.gd`
- `assets/data/crops.json`
- `project.godot` (run/main_scene)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/farming/farming_test.gd` — advisory at `qa.level: minimal`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/lang-sau-mua/story-002-day-cycle-seasons.md`, `production/epics/lang-sau-mua/story-003-village-market.md`

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 9/9 passing (AC-1 confirmed by hand, no still image possible for movement; AC-4's freshly-watered state is not in the retained screenshot)
**Deviations**: Advisory — gameplay constants and Vietnamese UI strings hardcoded; no phone display config yet (viewport/stretch/orientation, deferred by user); some untyped Dictionaries and unguarded getters. Out of scope — `.godot/global_script_class_cache.cfg`, `src/main.gd.uid` (Godot-generated).
**Test Evidence**: waived at qa.level minimal; screenshots `production/qa/evidence/story-001-touch-movement-farming/start.png` and `scenario-states.png`
**Reviewed by**: self, no independent review
