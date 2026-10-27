# Systems Index: Làng Sau Mưa

> **Status**: Draft
> **Created**: 2026-10-27
> **Last Updated**: 2026-10-27
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Làng Sau Mưa là game nông trại cozy trên điện thoại, cảm ứng, màn hình ngang. Vòng chơi là trồng trọt và bán ở chợ, giúp hàng xóm để mở khoá giống cây và món ăn, và nhìn làng được dựng lại từng mảnh. Game cần hai nhóm hệ thống. Nhóm đã xây (10 hệ thống MVP): dữ liệu cây, thời gian, ruộng, nhân vật và điều khiển chạm, chợ và tiền, hàng xóm và nhờ vả, làng hồi sinh, lưu và tải, HUD và các bảng, và cấu hình hiển thị cho điện thoại. Nhóm sắp mở rộng theo `design/narrative-outline.md` (7 hệ thống): cốt truyện và sự kiện, câu cá, nấu ăn và bảo quản, màn bắt đầu và chọn nhân vật, tuỳ chọn trợ năng, màn 3 (gà vịt, mương, chợ hồi sinh), và âm thanh.

Ba trụ cột chi phối thứ tự và phạm vi: ấm áp và không áp lực, hồi sinh nhìn thấy được, tình làng nghĩa xóm. Tiến độ đi qua hàng xóm: mỗi nhờ vả xong dựng lại một mảnh làng và mở một giống cây, món ăn hoặc tính năng mới, nên Hàng xóm và Ruộng (túi đồ) là hai hệ thống nhiều thứ phụ thuộc nhất.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Dữ liệu cây trồng (inferred) | Core | MVP | Not Started | — | — |
| 2 | Thời gian | Core | MVP | Designed | design/gdd/time-system.md | — |
| 3 | Ruộng | Gameplay | MVP | Designed | design/gdd/farming-system.md | Dữ liệu cây, Thời gian |
| 4 | Nhân vật và điều khiển chạm | Core | MVP | Designed | design/gdd/player-system.md | Hiển thị điện thoại |
| 5 | Chợ và tiền | Economy | MVP | Designed | design/gdd/market-system.md | Ruộng, Dữ liệu cây |
| 6 | Hàng xóm và nhờ vả | Progression | MVP | Designed | design/gdd/neighbors-system.md | Ruộng, Chợ và tiền, Dữ liệu cây |
| 7 | Làng hồi sinh | Narrative | MVP | Designed | design/gdd/village-restoration.md | Hàng xóm và nhờ vả |
| 8 | Lưu và tải | Persistence | MVP | Designed | docs/architecture/adr-0001-save-format-and-safe-write.md | — |
| 9 | HUD và các bảng giao diện (inferred) | UI | MVP | Not Started | — | Dữ liệu cây, Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả |
| 10 | Hiển thị cho điện thoại (inferred) | Core | MVP | Not Started | — | — |
| 11 | Cốt truyện và sự kiện | Narrative | Vertical Slice | Not Started | — | Thời gian, Hàng xóm và nhờ vả, Làng hồi sinh |
| 12 | Câu cá | Gameplay | Vertical Slice | Not Started | — | Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả |
| 13 | Nấu ăn và bảo quản | Gameplay | Vertical Slice | Not Started | — | Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả |
| 14 | Màn bắt đầu và chọn nhân vật | Meta | Vertical Slice | Not Started | — | Nhân vật và điều khiển chạm, Lưu và tải, HUD và các bảng giao diện |
| 15 | Tuỳ chọn trợ năng | Meta | Vertical Slice | Not Started | — | Làng hồi sinh, HUD và các bảng giao diện, Lưu và tải |
| 16 | Gà vịt, mương, chợ hồi sinh | Gameplay | Alpha | Not Started | — | Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả |
| 17 | Âm thanh | Audio | Full Vision | Not Started | — | HUD và các bảng giao diện |

Ghi chú: sáu GDD ở trạng thái `Designed` là tài liệu **reverse-documented** (viết từ mã đã chạy, kèm ý định đã xác nhận); chưa qua `/design-review`. Mã #8 có ADR thay vì GDD. Số thứ tự trong "Depends On" dùng tên hệ thống.

---

## Categories

| Category | Description | Typical Systems |
|----------|-------------|-----------------|
| **Core** | Foundation systems everything depends on | Dữ liệu cây, thời gian, nhân vật và chạm, hiển thị cho điện thoại |
| **Gameplay** | The systems that make the game fun | Ruộng, câu cá, nấu ăn, gà vịt và mương |
| **Progression** | How the player grows over time | Hàng xóm và nhờ vả |
| **Economy** | Resource creation and consumption | Chợ và tiền |
| **Persistence** | Save state and continuity | Lưu và tải |
| **UI** | Player-facing information displays | HUD và các bảng giao diện |
| **Audio** | Sound and music systems | Âm thanh |
| **Narrative** | Story and dialogue delivery | Làng hồi sinh, cốt truyện và sự kiện |
| **Meta** | Systems outside the core game loop | Màn bắt đầu, tuỳ chọn trợ năng |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | First playable prototype (đã xây) | Design FIRST |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Vertical slice (màn 1 và 2 của cốt truyện) | Design SECOND |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha milestone (màn 3) | Design THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release | Design as needed |

> **Review notes**: TD-SYSTEM-BOUNDARY, PR-SCOPE và CD-SYSTEMS bỏ qua (chế độ Lean).

---

## Dependency Map

### Foundation Layer (no dependencies)

1. Dữ liệu cây trồng — danh sách cây, ngày lớn, giá, mùa; mọi hệ thống về cây dựa vào đây
2. Thời gian — ngày, giai đoạn, mùa; nền cho ruộng và mọi thứ theo ngày
3. Lưu và tải — lớp lưu không biết game, từng hệ thống tự xuất trạng thái
4. Hiển thị cho điện thoại — màn ngang, kéo giãn, khoá hướng

### Core Layer (depends on foundation)

1. Ruộng — depends on: Dữ liệu cây, Thời gian
2. Nhân vật và điều khiển chạm — depends on: Hiển thị cho điện thoại

### Feature Layer (depends on core)

1. Chợ và tiền — depends on: Ruộng (túi đồ), Dữ liệu cây (giá)
2. Hàng xóm và nhờ vả — depends on: Ruộng, Chợ và tiền, Dữ liệu cây
3. Làng hồi sinh — depends on: Hàng xóm và nhờ vả
4. Cốt truyện và sự kiện — depends on: Thời gian, Hàng xóm và nhờ vả, Làng hồi sinh
5. Câu cá — depends on: Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả
6. Nấu ăn và bảo quản — depends on: Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả
7. Gà vịt, mương, chợ hồi sinh — depends on: Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả

### Presentation Layer (depends on features)

1. HUD và các bảng giao diện — depends on: Dữ liệu cây, Thời gian, Ruộng, Chợ và tiền, Hàng xóm và nhờ vả
2. Màn bắt đầu và chọn nhân vật — depends on: Nhân vật và điều khiển chạm, Lưu và tải, HUD và các bảng giao diện

### Polish Layer (depends on everything)

1. Tuỳ chọn trợ năng — depends on: Làng hồi sinh, HUD và các bảng giao diện, Lưu và tải
2. Âm thanh — depends on: HUD và các bảng giao diện (và sự kiện chung)

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Dữ liệu cây trồng (lấp lỗ hổng tài liệu MVP) | MVP | Foundation | game-designer | S |
| 2 | Hiển thị cho điện thoại (lấp lỗ hổng tài liệu MVP) | MVP | Foundation | technical-director, ui-programmer | S |
| 3 | HUD và các bảng giao diện (lấp lỗ hổng tài liệu MVP) | MVP | Presentation | ux-designer | M |
| 4 | Cốt truyện và sự kiện | Vertical Slice | Feature | narrative-director, writer | M |
| 5 | Câu cá | Vertical Slice | Feature | game-designer, systems-designer | M |
| 6 | Nấu ăn và bảo quản | Vertical Slice | Feature | game-designer, economy-designer | M |
| 7 | Màn bắt đầu và chọn nhân vật | Vertical Slice | Presentation | ux-designer | M |
| 8 | Tuỳ chọn trợ năng | Vertical Slice | Polish | ux-designer, accessibility-specialist | S |
| 9 | Gà vịt, mương, chợ hồi sinh | Alpha | Feature | game-designer, systems-designer | L |
| 10 | Âm thanh | Full Vision | Polish | audio-director, sound-designer | M |

Cốt truyện đứng đầu Vertical Slice vì nó ràng buộc câu cá và nấu ăn (mỗi hàng xóm dẫn vào một hệ thống). Mỗi hệ thống mới phải thêm phần vào bản lưu và nâng `FORMAT_VERSION` (ADR-0001).

---

## Circular Dependencies

- **Chợ và tiền ↔ Hàng xóm và nhờ vả:** hàng xóm trả tiền qua chợ, và ý định "cảnh báo khi bán phần đang cần cho nhờ vả" khiến chợ phải biết nhờ vả đang cần gì. *Cách xử lý:* hàng xóm cung cấp hàm đọc `cần_giữ(cây)` (chỉ đọc); chợ chỉ gọi hàm đó; tiền thưởng do `Main` chuyển, hàng xóm không gọi chợ.
- **Hàng xóm và nhờ vả ↔ Làng hồi sinh:** làng đếm nhờ vả đã xong, và ý định "nhờ vả mở theo mức làng" khiến hàng xóm phải biết mức làng. *Cách xử lý:* mức làng là hàm thuần của số nhờ vả đã xong; hàng xóm nhận một "nhà cung cấp mức" được tiêm vào (`Callable`); hai GDD thiết kế chung, kiểm không khoá chết (công thức trong GDD hàng xóm).

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Ruộng | Design | Nhiều ý định đã xác nhận mà mã chưa làm (héo cuối mùa, nhổ cây); luật héo cuối mùa không dùng được với mùa 4 ngày | Đổi mùa thành 12 ngày cùng lúc cài luật; kiểm cân bằng |
| Hàng xóm ↔ Làng | Design | Mở nhờ vả theo mức làng có thể khoá chết nếu mốc không khớp số nhờ vả | Công thức kiểm trong GDD hàng xóm, kiểm dữ liệu lúc nạp |
| Hiển thị cho điện thoại | Technical | Chưa thử trên máy Android thật; có báo cáo lỗi kéo giãn ở Godot 4.5.2 đến 4.6.2 | Xuất thử Android sớm, kiểm trên máy thật |
| Lưu và tải | Technical | Chưa có nâng cấp phiên bản; tự lưu khi xuống nền chưa thử trên máy thật | Làm chính sách phiên bản trước khi thêm hệ thống mới; thử vòng đời trên điện thoại |
| Câu cá | Design | Cảm giác cửa sổ cá cắn trên cảm ứng chưa từng thử | Làm prototype nhỏ (`/prototype`) trước khi viết GDD đầy đủ |
| Vertical Slice (tổng thể) | Scope | Năm hệ thống mới cùng một đợt, một người làm | Cắt từ cuối danh sách (tuỳ chọn trợ năng, rồi nấu ăn) nếu trễ |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 17 |
| Design docs started | 7 (6 GDD reverse-documented + ADR-0001) |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 7/10 |
| Vertical Slice systems designed | 0/5 |

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] Viết GDD cho ba hệ thống MVP còn thiếu tài liệu (dữ liệu cây, hiển thị cho điện thoại, HUD và bảng)
- [ ] Design Vertical Slice systems (use `/design-system [system-name]`), bắt đầu bằng Cốt truyện và sự kiện
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check technical-setup` when MVP systems are designed
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production
