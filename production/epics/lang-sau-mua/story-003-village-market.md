# Story 003: Chợ quê — bán nông sản, có tiền

> **Epic**: Làng Sau Mưa
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

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

- `src/gameplay/market/` (logic bán hàng)
- `src/ui/market/` (màn hình chợ, HUD tiền)
- `tests/integration/market/market_test.gd`

---

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
