# Story 001: Di chuyển bằng cảm ứng và làm ruộng

> **Epic**: Làng Sau Mưa
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

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

- `src/gameplay/farming/` (logic ruộng, dữ liệu cây)
- `src/gameplay/player/` (di chuyển cảm ứng)
- `tests/unit/farming/farming_test.gd`

---

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
