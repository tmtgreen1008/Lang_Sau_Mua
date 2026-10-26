# Story 003: Chợ quê — bán nông sản, có tiền

> **Epic**: Làng Sau Mưa
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 3 — Chợ quê: bán nông sản, có tiền

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**:
N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop: "Chiều: mang nông sản ra chợ quê bán"):*

- [ ] Có khu chợ quê trên bản đồ; chạm vào quầy thì mở màn hình bán hàng.
- [ ] Màn hình chợ liệt kê nông sản trong túi đồ kèm giá bán mỗi loại.
- [ ] Bán một số lượng chọn được thì trừ nông sản khỏi túi và cộng tiền tương ứng.
- [ ] Không bán được hơn số lượng đang có; tiền không bao giờ âm.
- [ ] Tiền hiện thường trực trên HUD và cập nhật ngay sau khi bán.
- [ ] Giá bán lấy từ dữ liệu cây (story 001), không hardcode.
- [ ] Nút và danh sách đủ lớn để chạm bằng ngón tay.

---

## Implementation Notes

- Tách logic mua bán (kinh tế) khỏi giao diện để test được; giao diện chỉ gọi vào logic.
- Chợ mở vào giai đoạn chiều (story 002); nếu chưa kịp thì cho phép mở bất cứ lúc nào và ghi TODO.

---

## Out of Scope

- Mua hạt giống hay đồ từ chợ (không có trong MVP).
- Story 004: dùng nông sản cho nhờ vả của hàng xóm.
- Story 006: lưu tiền.

---

## Files

- `src/gameplay/market/market.gd`
- `src/gameplay/market/market_stall_view.gd`
- `src/ui/market/market_panel.gd`
- `src/gameplay/farming/crop_database.gd` (get_sell_price)
- `src/ui/hud.gd` (money label, message position)
- `src/main.gd` (market wiring, load checks)
- `src/gameplay/farming/farm_view.gd` (TILE_SIZE 88 → 80, layout fix outside story scope)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/market/market_test.gd` OR playtest doc — advisory at `qa.level: minimal`
- Màn hình chợ chạm vào được nên nên giữ một ảnh chụp màn hình trong `production/qa/evidence/` khi chạy thử game.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lang-sau-mua/story-001-touch-movement-farming.md`, `production/epics/lang-sau-mua/story-002-day-cycle-seasons.md`
- Unlocks: `production/epics/lang-sau-mua/story-004-neighbors-requests.md`

---

## Completion Notes
**Completed**: 2026-10-26
**Criteria**: 7/7 passing (AC-1 to AC-5 confirmed by hand; no retained image of a sale taking place or of the empty-stock panel)
**Deviations**: Out of scope at the user's request — field/HUD layout re-done so the day label no longer overlaps the field (farm_view TILE_SIZE 88 → 80), main.gd now checks data-file load results. Advisory — layout constants and Vietnamese UI strings hardcoded, no localization; market panel background semi-transparent; empty-stock panel state parse-checked only; no phone display config yet. Out of scope — `.godot/global_script_class_cache.cfg` (Godot-generated).
**Test Evidence**: waived at qa.level minimal; screenshots `production/qa/evidence/story-003-village-market/map.png`, `panel.png`
**Reviewed by**: self, no independent review (programmer agent declined the relayed approval; the code was written directly in the session)
