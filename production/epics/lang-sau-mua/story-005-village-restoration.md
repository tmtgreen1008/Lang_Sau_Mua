# Story 005: Làng hồi sinh hiển thị

> **Epic**: Làng Sau Mưa
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 5 — Làng hồi sinh hiển thị: nhà cửa và đường được dựng lại theo tiến độ

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**:
N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal: "nhìn thấy làng thay đổi"; Art direction: màu đất, ấm):*

- [ ] Làng bắt đầu ở trạng thái hoang tàn sau lũ: nhà hỏng, đường đứt, bùn đất.
- [ ] Mỗi mốc tiến độ (số nhờ vả đã hoàn thành, theo story 004) thay đổi diện mạo làng: dựng lại một ngôi nhà hoặc một đoạn đường.
- [ ] Thay đổi hiển thị rõ ràng ngay khi đạt mốc, người chơi nhận ra sự khác biệt.
- [ ] Có ít nhất 3 mức diện mạo của làng từ hoang tàn đến sung túc.
- [ ] Mốc và tài nguyên hình ảnh tương ứng đọc từ dữ liệu, không hardcode trong code.
- [ ] Màu sắc và không khí đúng định hướng: màu đất, lúa, nắng chiều, ấm áp.
- [ ] Chạy mượt trên điện thoại tầm trung (không giật khi chuyển diện mạo).

---

## Implementation Notes

- Dùng placeholder (hình khối/màu phẳng) được vì chưa có asset; thay bằng nghệ thuật thật sau.
- Tách "mức tiến độ" (logic) khỏi "cách vẽ" để đổi nghệ thuật không đụng logic.

---

## Out of Scope

- Nhạc và âm thanh.
- Hiệu ứng thời tiết, ngày đêm phức tạp.
- Lưu trạng thái (story 006).

---

## Files

- `assets/data/village_restoration.json`
- `src/gameplay/village/village_progress.gd`
- `src/gameplay/village/village_view.gd`
- `src/main.gd` (village wiring)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived, but a Visual/Feel story's retained screenshot is not.*

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: ảnh chụp màn hình giữ lại trong `production/qa/evidence/` (ít nhất làng ở mức hoang tàn và mức sung túc) + sign-off trong `production/qa/evidence/village-restoration-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lang-sau-mua/story-004-neighbors-requests.md`
- Unlocks: `production/epics/lang-sau-mua/story-006-save-load.md`

---

## Completion Notes
**Completed**: 2026-10-26
**Criteria**: 6/7 passing; AC-7 (smooth on a mid-range phone) DEFERRED — needs a real device, not measured
**Deviations**: Advisory — restoration effect waits until the neighbor panel closes; level name stored but not shown; `reduce_motion` not hooked to any option; `bind_book` called twice would double-connect, a failed `load_from_file` leaves stale state; placeholder flat-colour art. Out of scope — `.godot/global_script_class_cache.cfg` (Godot-generated).
**Test Evidence**: waived at qa.level minimal; screenshots in `production/qa/evidence/story-005-village-restoration/`, sign-off in `production/qa/evidence/story-005-village-restoration-evidence.md` (ticked by Claude at the developer's request)
**Reviewed by**: self, no independent review
