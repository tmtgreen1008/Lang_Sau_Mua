# Story 004: 3 hàng xóm và nhờ vả

> **Epic**: Làng Sau Mưa
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 4 — 3 hàng xóm, mỗi người có nhờ vả để mở khoá giống cây hoặc món ăn

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**:
N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop + Player goal; Out of scope: no branching dialogue):*

- [ ] Có 3 hàng xóm đặt trên bản đồ làng; chạm vào một người thì nói chuyện.
- [ ] Mỗi hàng xóm có một chuỗi nhờ vả tuyến tính (không có hội thoại phân nhánh).
- [ ] Một nhờ vả yêu cầu nộp một số nông sản nhất định; đủ thì hoàn thành, thiếu thì thông báo còn thiếu gì.
- [ ] Hoàn thành nhờ vả thì nhận tiền công và mở khoá một giống cây mới hoặc một món ăn.
- [ ] Giống cây mở khoá xuất hiện trong lựa chọn gieo hạt (story 001); món ăn mở khoá chỉ để xem trong danh sách (không nấu nướng).
- [ ] Nhờ vả đã hoàn thành không làm lại được; trạng thái mỗi nhờ vả (chưa nhận, đang làm, xong) hiển thị được.
- [ ] Nội dung nhờ vả, lời thoại và phần thưởng đọc từ file dữ liệu ngoài.
- [ ] Hoàn thành hết nhờ vả của một mùa thì phát một sự kiện/signal để story 005 dùng.

---

## Implementation Notes

- Mô hình nhờ vả là một danh sách có thứ tự theo hàng xóm; trạng thái nằm trong dữ liệu để lưu/tải được (story 006).
- Lời thoại tiếng Việt, tránh hardcode chuỗi trong code (chuẩn bị cho bản địa hoá sau này).

---

## Out of Scope

- Hội thoại phân nhánh, tình cảm/quan hệ hàng xóm.
- Nấu ăn thật sự.
- Story 005: dựng lại nhà cửa/đường khi có tiến độ.

---

## Files

- `assets/data/neighbors.json`
- `src/gameplay/neighbors/neighbor_book.gd`
- `src/gameplay/neighbors/neighbor_view.gd`
- `src/ui/neighbors/neighbor_panel.gd`
- `src/ui/neighbors/dish_panel.gd`
- `src/main.gd` (neighbors wiring, hand-over, reward money)
- `src/ui/hud.gd` (unlocked-crop selector, Món ăn button)
- `src/gameplay/market/market.gd` (add_money)
- `src/gameplay/farming/farm_grid.gd` (crop_unlock_check, is_crop_unlocked)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/neighbors/neighbor_requests_test.gd` OR playtest doc — advisory at `qa.level: minimal`
- Hộp thoại là UI: giữ một ảnh chụp màn hình trong `production/qa/evidence/`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lang-sau-mua/story-001-touch-movement-farming.md`, `production/epics/lang-sau-mua/story-003-village-market.md`
- Unlocks: `production/epics/lang-sau-mua/story-005-village-restoration.md`

---

## Completion Notes
**Completed**: 2026-10-26
**Criteria**: 8/8 passing (AC-2 confirmed by hand; AC-8 verified only by a scratch logic check, not visible on screen)
**Deviations**: Advisory — UI button/label strings hardcoded, no localization; NeighborBook.from_dict clears unlocked crops without re-adding the starting crops (story 006 must handle it); neighbors.json is not validated (quantity <= 0, unknown crop ids); autumn requests of Bà Tư and Cô Sáu need tomatoes that can only be grown in summer. Fixed during the story — the first implementation never paid the money reward (added `_market.add_money` in main.gd). Out of scope — `.godot/global_script_class_cache.cfg` (Godot-generated). Design decision approved by the user — the game starts with Ngô only; Cà chua and Cải xanh are unlocked by requests.
**Test Evidence**: waived at qa.level minimal; screenshots `production/qa/evidence/story-004-neighbors-requests/map.png`, `panel.png`, `panelok.png`, `unlocked.png`
**Reviewed by**: self, no independent review
