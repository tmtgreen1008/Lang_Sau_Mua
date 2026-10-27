# Làng Sau Mưa — Master Architecture

## Document Status
- Version: 1
- Last Updated: 2026-10-27
- Engine: Godot 4.7 (4.7.2 cài trên máy phát triển), GDScript, renderer Compatibility, Godot Physics 2D
- GDDs Covered: `time-system`, `farming-system`, `player-system`, `market-system`, `neighbors-system`, `village-restoration` (6 GDD hệ thống, đều reverse-documented từ mã); đầu vào bổ sung: `game-concept`, `systems-index`, `design/accessibility-requirements.md`, `design/ux/interaction-patterns.md`. Ba hệ thống MVP chưa có GDD (dữ liệu cây, HUD và bảng, hiển thị điện thoại) nên chỉ được kiến trúc hoá từ mã, chưa từ thiết kế.
- ADRs Referenced: ADR-0001 (định dạng lưu và ghi an toàn, Accepted)
- Technical Requirements: 28 đã đăng ký trong `docs/architecture/tr-registry.yaml`, 0 tạm thời
- TD-ARCHITECTURE: 2026-10-27 — skipped — lean mode
- LP-FEASIBILITY: 2026-10-27 — skipped — lean mode

> Tài liệu này **chưa qua duyệt của director nào** (cả hai cổng chỉ chạy ở `review_mode: full`). Mô tả trong các bảng khớp mã ngày 2026-10-27; phần đánh dấu **[mới]** là quyết định kiến trúc chưa có trong mã.

## Engine Knowledge Gap Summary

Engine: Godot 4.7. Kiến thức của mô hình phủ khoảng tới 4.3; 4.5, 4.6 và 4.7 đều rủi ro HIGH (`docs/engine-reference/godot/VERSION.md`).

**HIGH RISK, cần đối chiếu tài liệu trước khi quyết:**
- **Input:** ở 4.7 chuột và bàn phím báo `InputEvent.DEVICE_ID_MOUSE` và `DEVICE_ID_KEYBOARD`, không còn `0`. `main.gd` bỏ chạm đôi bằng cách so `device` với `DEVICE_ID_EMULATION`; tài liệu **không nói** giá trị của sự kiện chuột giả lập ở 4.7 (NOT SOURCEABLE), cần kiểm trên máy thật.
- **Rendering 2D:** ở 4.7 đường vẽ bằng `CanvasItem` không còn viền mờ nên mỏng hơn. `farm_view.gd` dùng `draw_rect` viền 3 px ("đã tưới") và `draw_arc` 4 px ("chín"): hai dấu hiệu trợ năng quan trọng.
- **Platform Android (4.5+):** hiển thị tràn viền và trang nhớ 16KB cho Google Play với Android 15 trở lên. Tài liệu không mô tả hệ quả cho vùng an toàn; dự án chưa có `export_presets.cfg`.
- **UI và trợ năng:** AccessKit chỉ áp cho `Control`; thế giới game là `Node2D` tự vẽ nên không được đọc màn hình. Mặc định kéo giãn ở 4.7 là `canvas_items` và `expand` cho dự án mới (dự án cũ giữ cài đặt).
- **GDScript 4.7:** ghi đè phương thức có kiểu trả về phải có `return` rõ ràng; lambda bắt biến cục bộ theo giá trị và không gán lại được biến ngoài.

**MEDIUM RISK:** Core, `FileAccess.store_*` trả `bool` từ 4.4 (ADR-0001 đã xử lý). Thông báo vòng đời ứng dụng trên Android và ngữ nghĩa ghi đè của `DirAccess.rename_absolute` không có trong tài liệu (NOT SOURCEABLE).

**LOW RISK:** Physics 2D (không đổi), Navigation (4.7 không đổi; có server 2D riêng từ 4.5), Animation (chỉ `Tween`; 4.7 thêm `tween_await()`), Audio (chỉ khi làm #17: `area_mask` mặc định 0 ở 4.7).

## System Layer Map

Giữ nguyên phân lớp của `systems-index.md` cho 10 hệ thống MVP; thêm **`Main`** (gốc ghép nối) như mô-đun nền tảng tường minh và **`Inventory`** **[mới]** ở lớp Core.

```
┌──────────────────────────────────────────────────────────┐
│ PRESENTATION  HUD và bảng (#9) · Màn bắt đầu (#14)       │
│               Tuỳ chọn trợ năng (#15) · Âm thanh (#17)   │
├──────────────────────────────────────────────────────────┤
│ FEATURE       Chợ và tiền (#5) · Hàng xóm và nhờ vả (#6) │
│               Làng hồi sinh (#7) · Cốt truyện (#11)      │
│               Câu cá (#12) · Nấu ăn (#13) · Gà vịt (#16) │
├──────────────────────────────────────────────────────────┤
│ CORE          Ruộng (#3) · Nhân vật và chạm (#4)         │
│               Inventory [mới]                            │
├──────────────────────────────────────────────────────────┤
│ FOUNDATION    Gốc ghép nối Main (không có GDD)           │
│               Thời gian (#2) · Lưu và tải (#8)           │
│               Dữ liệu cây và nạp JSON (#1)               │
│               Hiển thị điện thoại (#10)                  │
├──────────────────────────────────────────────────────────┤
│ PLATFORM      Godot 4.7 · Android và iOS (không viết mã) │
└──────────────────────────────────────────────────────────┘
```

## Module Ownership

### Foundation

| Mô-đun | Sở hữu | Cung cấp ra | Dùng của mô-đun khác | API engine (rủi ro) |
|---|---|---|---|---|
| `Main` (`src/main.gd`) | Việc chờ sau chạm (`_pending_*`), nối tín hiệu, điều phối lưu, thông báo vòng đời | `season_requests_completed`, `save_game()` | Tất cả mô-đun | `_unhandled_input`, `InputEventScreenTouch`, `InputEventMouseButton`; `InputEvent.DEVICE_ID_EMULATION`: **NEEDS VERIFICATION** (4.7); `_notification` với `NOTIFICATION_APPLICATION_PAUSED`, `…FOCUS_OUT`, `NOTIFICATION_WM_WINDOW_FOCUS_OUT`, `…CLOSE_REQUEST`: **NOT SOURCEABLE** |
| `SaveGame` (`core/save`) | File lưu, định dạng, ghi an toàn | `save`, `load_state`, `has_save`, `last_load_failed` | Chỉ nhận `Dictionary` | `FileAccess.store_string` trả `bool` (verified, 4.4); `DirAccess.rename_absolute`, `JSON`: ngữ nghĩa ghi đè NOT SOURCEABLE |
| `CropDatabase` | Dữ liệu cây từ `crops.json` | Tên, ngày lớn, giá, mùa, màu | `FileAccess`, `JSON` | LOW |
| `DayClock` | Ngày, giai đoạn, mùa, giây đã trôi | `phase_changed`, `season_changed`, `day_advanced`, `tick`, `sleep`, `to_dict`, `from_dict` | `time_config.json` | MEDIUM; bước thời gian không bị kẹp (TR-time-004) |
| Hiển thị điện thoại | Kéo giãn, hướng, vùng an toàn (hiện chỉ ở `project.godot`) | Khung nhìn 1152×648 | Không | HIGH (tràn viền Android, mặc định kéo giãn 4.7) |

### Core

| Mô-đun | Sở hữu | Cung cấp ra | Dùng | API engine (rủi ro) |
|---|---|---|---|---|
| `Inventory` **[mới]** | Số lượng mọi loại vật phẩm (cây, sau này cá và món) | `count`, `add`, `remove`, `remove_all`, `changed`, `to_dict`, `from_dict` | Không | Thuần GDScript |
| `FarmGrid` | Ô ruộng (không còn sở hữu túi đồ) | `plot_changed`, `crop_harvested`, `apply_tool`, `advance_day` | `CropDatabase`, `Inventory` (chỉ `add`), `crop_unlock_check` (`Callable` tiêm vào) | Thuần `RefCounted` |
| `FarmView` | Cách vẽ ô | `cell_at`, `cell_center` | `FarmGrid` (chỉ đọc) | `Node2D._draw`, `draw_rect`, `draw_arc`: nét mỏng hơn ở 4.7 (verified trong tài liệu; độ mỏng thực cần xem bằng mắt) |
| `Player` | Vị trí, di chuyển | `arrived`, `move_to` | Không | `Node2D` (LOW) |

### Feature

| Mô-đun | Sở hữu | Cung cấp ra | Dùng | API engine |
|---|---|---|---|---|
| `Market` | Tiền | `money_changed`, `inventory_changed`, `sell`, `add_money`, `get_owned` | `Inventory` (chỉ `remove`), `CropDatabase` | Thuần GDScript |
| `NeighborBook` | Trạng thái nhờ vả, cây và món đã mở | `request_completed`, `crop_unlocked`, `dish_unlocked`, `season_requests_completed`, `can_complete`, `complete_request` | `Inventory` (`remove_all`), `level_provider` **[mới]** | Thuần GDScript |
| `VillageProgress` | Số nhờ vả đã xong | `piece_restored`, `level_changed` | `NeighborBook` (`bind_book`) | Thuần GDScript |
| `VillageView` | Hiệu ứng dựng | | `VillageProgress` | `_draw` (nét mỏng hơn 4.7), `create_tween` (không đổi) |

### Presentation

`Hud`, `MarketPanel`, `NeighborPanel`, `DishPanel`: không sở hữu trạng thái, chỉ phát yêu cầu (`sleep_requested`, `sell_requested`, `hand_over_requested`, `dishes_requested`). API: `CanvasLayer`, `Control`, `Button`, `ButtonGroup`, `ColorRect`. Với `focus_mode = FOCUS_NONE`, thay đổi dual-focus của 4.6 không ảnh hưởng.

### Sơ đồ phụ thuộc

```
                    Main (gốc ghép nối: nối tín hiệu và tiêm phụ thuộc)
   ┌───────────┬───────────┬──────────────┬─────────────┬──────────────┐
 DayClock    CropDB     SaveGame        Player     Hud + 3 bảng (chỉ hiển thị)
   │ day_advanced
   ▼
 FarmGrid ──add──▶ Inventory ◀──remove── Market
                       ▲
                       │ remove_all
 NeighborBook ─────────┘
   │ request_completed
   ▼
 VillageProgress ──▶ VillageView          crop_unlock_check (Callable) ──▶ FarmGrid
```

Quyết định đã chốt: **túi đồ tách thành mô-đun `Inventory`** vì `FarmGrid` cộng, `Market` và `NeighborBook` trừ, và GDD hàng xóm đã xác nhận ý định "nhờ vả nhận mọi loại vật phẩm" (TR-neighbors-005). Hiện túi đồ là một Dictionary công khai có ba bên ghi.

## Data Flow

Tất cả chạy trên **luồng chính**; không có luồng dữ liệu nào qua ranh giới luồng.

### 1. Đường cập nhật theo khung hình

```
Chạm ──▶ Main._unhandled_input ──▶ _on_tap (chọn đích)
                                      ▼
                              Player.move_to
                                      │ (Player._process, tốc độ cố định)
                                      ▼
                              Player.arrived
                                      │
                    ┌─────────────────┼───────────────────┐
                    ▼                 ▼                   ▼
          mở bảng hàng xóm     mở bảng chợ         FarmGrid.apply_tool
                                                          │ plot_changed
                                                          ▼
                                                   FarmView.queue_redraw

Mỗi khung:  Main._process(delta) ──▶ DayClock.tick(delta)   ⚠ delta thô, không kẹp
```

### 2. Đường tín hiệu

Hầu hết tín hiệu đi qua `Main`; ngoại lệ có chủ ý là `VillageProgress.bind_book` nối thẳng với `NeighborBook`.

| Nguồn | Tín hiệu | Người nhận | Việc làm |
|---|---|---|---|
| `DayClock` | `day_advanced` | `Main._on_day_advanced` | `grid.advance_day()`, làm mới HUD thời gian, thông báo, lưu |
| `DayClock` | `season_changed` | `Main._on_season_changed` | Đặt mùa cho ruộng, thông báo |
| `DayClock` | `phase_changed` | `Main._on_phase_changed` | Làm mới HUD thời gian |
| `FarmGrid` | `crop_harvested` | `Main._on_crop_harvested` | HUD túi đồ, thông báo |
| `FarmGrid` | `plot_changed` | `FarmView` (nối trực tiếp) | Vẽ lại |
| `Market` | `money_changed` | `Hud.set_money` (nối thẳng) | Hiện tiền |
| `Market` | `inventory_changed` | `Main._on_market_inventory_changed` | HUD túi đồ, làm mới bảng chợ |
| `NeighborBook` | `request_completed` | `VillageProgress` (nối trực tiếp), rồi `Main` | Mảnh làng; `Main` chuyển tiền, thông báo, lưu |
| `NeighborBook` | `crop_unlocked` | `Main._on_crop_unlocked` | HUD cập nhật hạt đã mở |
| `VillageProgress` | `piece_restored` | `Main._on_village_piece_restored` | Thông báo làng (hoãn khi bảng mở) |
| Bảng, HUD | `sell_requested`, `hand_over_requested`, `sleep_requested`, `dishes_requested` | Hàm xử lý trong `Main` | Gọi vào miền, rồi lưu khi cần |

Quan sát từ mã: `_on_season_changed` rồi `_on_day_advanced` đều gọi `show_message` trong cùng một `tick`, nên thông báo sang mùa bị thông báo ngày ghi đè (theo đọc mã, chưa chạy game). Sau khi có `Inventory`, luồng túi đồ đổi từ trạng thái dùng chung sang "gọi `add` hoặc `remove` rồi tín hiệu `changed`".

### 3. Đường lưu và tải

```
LƯU  (đồng bộ, luồng chính):
  Main.save_game ── gom 5 phần ──▶ SaveGame.save({farm, clock, market, neighbors, village})
       ▲  kích hoạt bởi: sang ngày · bán · nộp nhờ vả ·
       │  NOTIFICATION_APPLICATION_PAUSED / APPLICATION_FOCUS_OUT /
       │  WM_WINDOW_FOCUS_OUT / WM_CLOSE_REQUEST        (lifecycle: NOT SOURCEABLE)

TẢI  (một lần, cuối _ready):
  has_save ▶ load_state ▶ from_dict ×5 ▶ Main làm mới HUD, FarmView, VillageView bằng tay
  (các hàm tải KHÔNG phát tín hiệu; Main phải nhớ làm mới từng chỗ)
```

Mỗi mô-đun tự chịu `to_dict` và `from_dict`; `SaveGame` chỉ giữ file và định dạng (ADR-0001). Thêm `Inventory` là thêm một phần vào bản lưu, nên phải nâng `FORMAT_VERSION` và cần chính sách nâng cấp bản lưu trước.

### 4. Thứ tự khởi tạo (theo `_ready`)

```
1. Nạp dữ liệu: crops.json ▶ time_config.json ▶ neighbors.json   (lỗi thì dừng)
2. FarmGrid(db, 5, 4)  ·  crop_unlock_check = book.is_crop_unlocked
3. VillageProgress: nạp village_restoration.json (lỗi thì dừng) ▶ bind_book ▶ VillageView
4. FarmView ▶ Player ▶ Market ▶ quầy ▶ hình hàng xóm
5. Hud ▶ MarketPanel ▶ NeighborPanel ▶ DishPanel
6. Nối tín hiệu · đặt mùa · làm mới HUD thời gian
7. _load_saved_game()  ▶  _initialised = true
```

`_initialised` chặn `_process`, nhập liệu và `save_game` tới khi xong, nên một lần khởi động hỏng không ghi đè bản lưu. Điểm yếu: khi một file dữ liệu nạp lỗi, `_ready` chỉ `push_error` rồi `return`, người chơi thấy màn hình trống không có thông báo.

### Khoảng trống phát hiện
1. `tick(delta)` không kẹp (HIGH).
2. Thông báo sang mùa bị ghi đè.
3. Lỗi nạp dữ liệu im lặng.
4. Danh sách "làm mới sau khi tải" nằm tay trong `Main`; mỗi hệ thống mới dễ quên thêm một dòng.
5. Bản lưu cần chính sách phiên bản trước khi thêm `Inventory`.

## API Boundaries

### 1. `Inventory` [mới, Core]

```gdscript
class_name Inventory extends RefCounted

signal changed(item_id: String)               # phát sau mỗi lần số lượng đổi

func count(item_id: String) -> int            # 0 nếu chưa có
func add(item_id: String, amount: int) -> void              # amount > 0
func remove(item_id: String, amount: int) -> bool           # false và KHÔNG đổi gì nếu không đủ
func can_remove_all(needs: Dictionary[String, int]) -> bool
func remove_all(needs: Dictionary[String, int]) -> bool     # nguyên tử: đủ hết hoặc không trừ gì
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
```
- Bất biến: số lượng luôn là số nguyên ≥ 0.
- `remove` và `remove_all` thất bại thì trạng thái không đổi; `changed` chỉ phát khi thật sự đổi.
- `FarmGrid` chỉ `add`; `Market` và `NeighborBook` chỉ `remove` hoặc `remove_all`; HUD và bảng chỉ `count`.
- Chưa quyết (ADR): `from_dict` gặp mã vật phẩm lạ thì giữ hay bỏ.

### 2. `DayClock`

```gdscript
func tick(delta: float) -> void      # bỏ qua delta <= 0                     [hiện tại]
                                     # kẹp delta tối đa max_step_seconds     [mới, TR-time-004]
                                     # không làm gì khi đang tạm dừng        [mới]
func set_paused(source: StringName, paused: bool) -> void   # [mới] nhiều nguồn: bảng mở, nền, nút Tạm dừng
func set_day_speed(mode: StringName) -> void                # [mới] "normal" | "slow" | "stop", hệ số từ time_config.json
func sleep() -> void                                        # [hiện tại]
signal season_changed(season_id) ; signal phase_changed(phase_id) ; signal day_advanced(day_number)
```
- Bảo đảm [hiện tại]: thứ tự phát tín hiệu là đổi mùa, đổi giai đoạn, sang ngày.
- Bảo đảm [mới]: `max_step_seconds` và hệ số tốc độ đều lấy từ dữ liệu, không hardcode. Dùng nhiều nguồn tạm dừng để bảng mở và ứng dụng xuống nền không ghi đè nhau.

### 3. `SaveGame` và hợp đồng tuần tự hoá [hiện tại]

```gdscript
func save(state: Dictionary) -> bool
func load_state() -> Dictionary      # {} khi không có hoặc không dùng được; last_load_failed cho biết
```
Mọi mô-đun có trạng thái:
```gdscript
func to_dict() -> Dictionary         # chỉ giá trị JSON: String, số, bool, Array, Dictionary
func from_dict(data: Dictionary) -> void
```
- Bất biến của `from_dict`: không crash khi thiếu khoá hoặc sai kiểu (kẹp hoặc bỏ giá trị xấu); không phát tín hiệu, nên `Main` phải làm mới màn hình.
- Thêm `Inventory` hay mô-đun mới: thêm một phần vào `REQUIRED_SECTIONS` và nâng `FORMAT_VERSION`; cần chính sách nâng cấp trước (ADR-0001 follow-up).

### 4. Tiêm phụ thuộc bằng `Callable`

```gdscript
FarmGrid.crop_unlock_check : Callable   # func(crop_id: String) -> bool          [hiện tại]
NeighborBook.level_provider : Callable  # func() -> int  (mức làng)              [mới, TR-neighbors-003]
```
- Gọi `is_valid()` trước khi dùng (`Callable()` mặc định không hợp lệ).
- Hàm phải thuần và nhanh, không tác dụng phụ.
- Engine (`current-best-practices.md`): lambda bắt biến cục bộ theo giá trị và không gán lại được biến ngoài; tiêm bằng hàm thành viên (như `book.is_crop_unlocked`), không dùng lambda đóng trên biến cục bộ.

### 5. Ranh giới trình bày [hiện tại]

```gdscript
# Hud và các bảng: chỉ hiển thị và phát yêu cầu
signal sell_requested(crop_id, quantity) ; signal hand_over_requested(neighbor_id)
signal sleep_requested ; signal dishes_requested
func open(...) ; func close() ; func refresh(...) ; func is_open() -> bool
```
- Không bao giờ sửa trạng thái miền; chỉ đọc (sau thay đổi này, nhận `Inventory` chỉ qua `count()`).
- Thông báo [mới]: `show_message(text, importance)`, tin quan trọng ≥5 giây và xếp hàng (từ tài liệu trợ năng).

### 6. Quy tắc cho `Main`
- Mọi hiệu ứng chéo giữa các mô-đun miền chỉ diễn ra trong các hàm xử lý của `Main`. Mô-đun miền không gọi nhau, trừ qua `Callable` được tiêm hoặc tín hiệu.
- Ngoại lệ hiện có: `VillageProgress.bind_book` (giữ làm ngoại lệ có tài liệu hoặc chuyển qua `Main`: việc của ADR 1).
- `Main` có một API công khai duy nhất: `save_game() -> bool`.

Kiểm tra engine cho các kiểu dùng ở ranh giới: `Dictionary[String, int]`, `Callable`, `Signal`, `RefCounted`, `CanvasLayer`, `Control` không có thay đổi chữ ký ở 4.5 đến 4.7 trong `breaking-changes.md`.

## ADR Audit

| ADR | Engine Compat | Phiên bản | Liên kết GDD | Xung đột | Hợp lệ |
|---|---|---|---|---|---|
| ADR-0001: định dạng lưu và ghi an toàn (Accepted) | ✅ | ✅ 4.7 | ⚠️ trích tiêu chí GDD, chưa dùng TR-ID | Không xung đột trực tiếp; thêm `Inventory` cần nâng `FORMAT_VERSION`, mà chính sách nâng cấp mới chỉ là việc dự kiến | ⚠️ |

Ba lý do cho ⚠️: (1) không có trường "Post-Cutoff APIs Used", dù đã gắn rủi ro HIGH và đánh dấu tên thông báo vòng đời là NOT SOURCEABLE; (2) chuyên gia engine nêu độ bền ghi (không `fsync`, thiếu phục hồi `.tmp`) và nút Back của Android mà ADR chưa nhắc; (3) chưa dùng TR-ID.

**Độ phủ truy vết:** 28 yêu cầu, **5 được phủ** (TR-time-005, farm-004, market-001, neighbors-002, village-002, đều bởi ADR-0001), **23 khoảng trống**; cả 23 đều được gán cho một ADR bên dưới.

## Required ADRs

Ở `workflow: standard`, chỉ ADR **nền tảng** là bắt buộc để qua cổng; các nhóm sau là khuyến nghị.

### Phải có trước khi viết mã (Foundation)

| # | ADR đề xuất | Phủ | Rủi ro engine |
|---|---|---|---|
| 1 | **Gốc ghép nối và kiến trúc sự kiện** (một ADR phủ cả quản lý scene): dựng cảnh trong `Main`, tín hiệu qua `Main`, tiêm `Callable`, ngoại lệ `bind_book`, danh sách làm mới sau tải, hiển thị lỗi khi nạp dữ liệu thất bại | TR-time-003, farm-003, farm-005, market-004, neighbors-003, neighbors-004, village-004 | MEDIUM (lambda bắt giá trị) |
| 2 | **Nạp và kiểm tra dữ liệu JSON** trong `assets/data/`, chính sách khi lỗi, trường hình dạng hoặc nhãn cho cây | TR-time-002, farm-002, market-002, market-005, neighbors-001, village-001, player-002 | LOW |
| 3 | **Đồng hồ và vòng đời ứng dụng**: kẹp `delta`, nhiều nguồn tạm dừng, tốc độ ngày, xuống nền, nút Back; sửa độ bền ghi của ADR-0001 | TR-time-001, time-004 | **HIGH**; lifecycle NOT SOURCEABLE |
| 4 | **Chính sách phiên bản và nâng cấp bản lưu** (nối tiếp ADR-0001); chặn mục 5 | (điều kiện cho mục 5) | MEDIUM |

### Nên có trước khi hệ thống liên quan được xây

| # | ADR đề xuất | Phủ |
|---|---|---|
| 5 | **Mô-đun `Inventory` và mô hình vật phẩm**: mọi loại vật phẩm, API, tín hiệu | TR-neighbors-005 |
| 6 | **Nhập liệu chạm và định tuyến chạm**: chuột giả lập ở 4.7, bảng chặn nền, HUD chặn chạm | TR-player-001, player-003 (**Input HIGH**) |
| 7 | **Bảng giao diện, chỉnh cỡ chữ, giảm chuyển động** (từ tài liệu trợ năng) | TR-market-003, village-003 |
| 8 | **Nơi lưu thiết lập trợ năng** (trong bản lưu hay file riêng) | trước khi làm #15 |
| 9 | **Hiển thị điện thoại**: kéo giãn, hướng, vùng an toàn, tràn viền Android | trước khi xuất Android; sau chuyến thử máy thật |

### Có thể hoãn
- Đi vòng vật cản (TR-player-004): hướng dùng `NavigationAgent2D`, chưa cần khi chưa có ao và nhà mới.
- Lược đồ ô ruộng (TR-farm-001): đã có trong mã và GDD; ADR tuỳ chọn.
- Bố trí bus âm thanh (đến khi làm #17) và hình dạng cây (đến khi có art bible).

### Thứ tự viết đề xuất
**1 → 2 → 3 → 4 → 5**, rồi 6 và 7, 8, 9. Mục 1 không phụ thuộc gì; 2 và 3 dựa vào 1; 5 cần 4 xong vì nó thêm phần mới vào bản lưu.

## Architecture Principles

1. **Trụ cột "không áp lực" đi trước.** Kiến trúc không được tạo ra trạng thái thua hay áp lực thời gian mà người chơi không tắt được: đồng hồ phải tạm dừng và chỉnh tốc độ được, bản lưu tốt cuối cùng không bao giờ bị mất.
2. **Logic miền thuần, hiển thị mỏng.** Mô-đun miền là `RefCounted` không phụ thuộc scene, kiểm thử trực tiếp được; giao diện chỉ hiển thị và phát yêu cầu; mọi hiệu ứng chéo giữa các mô-đun đi qua `Main`.
3. **Nội dung theo dữ liệu, thất bại thì phải thấy.** Giá trị và lời thoại nằm trong `assets/data/*.json`, được kiểm khi nạp; nạp lỗi thì người chơi nhận một thông báo, không phải màn hình trống.
4. **Cảm ứng và trợ năng từ đầu.** Một lần chạm, vùng chạm ≥72 px, không thông tin nào chỉ nằm ở màu hay âm thanh.
5. **Xác minh hành vi engine trước khi dựa vào.** Hành vi sau mốc hoặc không có trong tài liệu (vòng đời ứng dụng, ID thiết bị đầu vào, tràn viền Android) bị đánh dấu NOT SOURCEABLE và phải kiểm trên máy thật trước khi một ADR được chuyển sang Accepted.

## Open Questions

- Thiết lập trợ năng lưu trong bản lưu hay file riêng (ADR 8, trước #15).
- `from_dict` của `Inventory` gặp mã vật phẩm lạ thì giữ hay bỏ (ADR 5).
- `VillageProgress.bind_book` giữ làm ngoại lệ hay chuyển qua `Main`; và `Main` (384 dòng) cần tách khi nào (ADR 1).
- Hành vi vòng đời Android: thông báo xuống nền, nút Back, độ bền ghi (ADR 3; NOT SOURCEABLE).
- Sự kiện chuột giả lập ở 4.7 còn mang `DEVICE_ID_EMULATION` không (ADR 6; NOT SOURCEABLE).
- Vùng an toàn và tràn viền Android (ADR 9; NOT SOURCEABLE).
- `project.godot` mất ba dòng kích thước khung nhìn và hướng màn hình: giữ tường minh hay để mặc định (ADR 9).
- Ngân sách hiệu năng chưa đặt trong `project.yaml` (cần cho cổng; đo trên máy thật).
- Chạy `/create-control-manifest` khi các ADR nền tảng ở trạng thái Accepted.
