# Story 002: Chu kỳ ngày và 2 mùa

> **Epic**: Làng Sau Mưa
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 2 — Chu kỳ ngày và 2 mùa

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**:
N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop + MVP feature 2):*

- [ ] Một ngày trôi qua theo giai đoạn sáng, chiều, tối; giai đoạn hiện tại hiển thị cho người chơi.
- [ ] Hết tối thì sang ngày mới và gọi `advance_day` của hệ thống ruộng (story 001).
- [ ] Có 2 mùa; sau số ngày cấu hình thì chuyển mùa.
- [ ] Mỗi loại cây chỉ trồng được trong mùa phù hợp của nó (cấu hình trong dữ liệu).
- [ ] Độ dài một ngày và một mùa đọc từ file cấu hình, không hardcode.
- [ ] Người chơi có thể kết thúc ngày sớm (đi ngủ) mà không mất tiến độ.
- [ ] Không có thời tiết ngẫu nhiên hay lũ lần hai (ngoài phạm vi).

---

## Implementation Notes

- Dùng một bộ đếm thời gian có thể test bằng cách tiêm giá trị thời gian (không phụ thuộc đồng hồ thật), để unit test xác định.
- Phát signal khi đổi giai đoạn, đổi ngày, đổi mùa (đặt tên snake_case thì quá khứ, ví dụ `day_advanced`).

---

## Out of Scope

- Story 001: logic ruộng bên trong `advance_day`.
- Story 006: lưu ngày và mùa hiện tại.

---

## Files

- `src/gameplay/time/` (bộ đếm ngày và mùa)
- `tests/unit/time/day_cycle_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/time/day_cycle_test.gd` — advisory at `qa.level: minimal`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lang-sau-mua/story-001-touch-movement-farming.md`
- Unlocks: `production/epics/lang-sau-mua/story-003-village-market.md`
