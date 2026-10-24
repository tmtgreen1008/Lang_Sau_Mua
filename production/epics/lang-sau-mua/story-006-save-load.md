# Story 006: Lưu và tải game

> **Epic**: Làng Sau Mưa
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

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

- `src/core/save/` (hệ thống lưu/tải)
- `tests/integration/save/save_load_test.gd`

---

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
