# ADR-0002: Gốc ghép nối và kiến trúc sự kiện

## Status
Proposed

## Date
2026-10-27

## Last Verified
2026-10-27

## Decision Makers
To Truong (người làm game), cùng phiên `/create-architecture` và `/architecture-decision`.

## Summary
Dự án sắp thêm bảy hệ thống (cốt truyện, câu cá, nấu ăn, màn bắt đầu, tuỳ chọn trợ năng, gà vịt, âm thanh) mà `Main` đang ghép nối ngầm định bằng 384 dòng mã, chưa có quy tắc ghi lại. Quyết định: `Main` là gốc ghép nối duy nhất trên một scene gốc, mô-đun miền nói chuyện bằng tín hiệu và `Callable` được tiêm (không autoload, không bus toàn cục), mọi hiệu ứng chéo đi qua `Main`, và tách composer theo tính năng khi `Main` vượt ngưỡng.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH (4.5, 4.6, 4.7 sau mốc kiến thức; `docs/engine-reference/godot/VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/ui.md`, `modules/input.md` |
| **Post-Cutoff APIs Used** | Không có API mới. Dựa vào một quy tắc GDScript đã xác minh trong `current-best-practices.md`: lambda bắt biến cục bộ theo giá trị. `Main` hiện dùng `InputEvent.DEVICE_ID_EMULATION` (4.7 đổi ID thiết bị của chuột và bàn phím) |
| **Verification Required** | (1) Hành vi của sự kiện chuột giả lập từ cảm ứng ở 4.7 trên máy Android thật: tài liệu engine không nêu (NOT SOURCEABLE); thuộc ADR nhập liệu chạm nhưng `Main._unhandled_input` bị ảnh hưởng. (2) Thứ tự nhận sự kiện giữa `Control` trong `CanvasLayer` và `_unhandled_input` của `Main` |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR về nạp dữ liệu JSON, ADR về đồng hồ và vòng đời, ADR `Inventory`, ADR nhập liệu chạm, ADR giao diện (tất cả dùng quy tắc ghép nối ở đây) |
| **Blocks** | Epic cho câu cá, nấu ăn, cốt truyện, màn bắt đầu, và story tách `Inventory` |
| **Ordering Note** | Viết trước ADR về nạp dữ liệu và ADR về đồng hồ và vòng đời, vì cả hai thêm việc vào `Main`. Liên quan tới ADR-0001 (đã Accepted) nhưng không phụ thuộc cứng: `Main` chỉ gọi `SaveGame` qua API đã có |

## Context

### Problem Statement
`Main` (`src/main.gd`, 384 dòng) dựng 17 đối tượng, nối khoảng 20 tín hiệu và viết toàn bộ hàm xử lý chéo giữa ruộng, chợ, hàng xóm, làng, HUD, bảng và lưu. Nó chạy được, nhưng:
- chưa có quy tắc nào cấm mô-đun gọi nhau trực tiếp: `VillageProgress.bind_book` đã nối thẳng với `NeighborBook`;
- sau khi tải bản lưu, `Main` phải làm mới từng chỗ bằng tay (các `from_dict` không phát tín hiệu), và danh sách đó dễ thiếu khi thêm hệ thống;
- khi một file dữ liệu nạp lỗi, `_ready` chỉ `push_error` rồi `return`, người chơi thấy màn hình trống;
- sang mùa và sang ngày cùng gọi `show_message` trong một lần `tick`, tin sau ghi đè tin trước (đọc từ mã, chưa chạy game).
Bảy hệ thống sắp thêm và `Inventory` sắp tách ra sẽ làm các điểm này tệ hơn nếu không chốt quy tắc.

### Constraints
- Một người làm; `Main` phải còn đọc và sửa được.
- Quy tắc dự án (`coding-standards.md`): tiêm phụ thuộc thay vì singleton; mọi phương thức công khai kiểm thử được.
- Mô-đun miền là `RefCounted` thuần, không phụ thuộc scene; giao diện dựng bằng mã, không có file `.tscn` nào ngoài `main.tscn`.
- Chỉ có một scene (`main.tscn`: một nút `Node2D` gắn `main.gd`); không có autoload.
- Chỉ cảm ứng; tất cả chạy trên luồng chính.

### Requirements
- TR-time-003: thứ tự tín hiệu mùa, giai đoạn, ngày; `Main` nối ruộng, HUD, lưu.
- TR-farm-003, TR-farm-005: `advance_day` và mùa được đẩy vào; kiểm khoá cây bằng `Callable` tiêm vào.
- TR-market-004: thay đổi túi và tiền phát tín hiệu cho HUD.
- TR-neighbors-003, TR-neighbors-004: nhà cung cấp mức làng tiêm vào; `request_completed` và tiền thưởng do `Main` chuyển.
- TR-village-004: làng chạy theo `request_completed`.

## Decision

1. **`Main` là gốc ghép nối duy nhất.** Chỉ `Main` (hoặc composer, xem mục 8) dựng mô-đun, nối tín hiệu giữa các mô-đun, tiêm phụ thuộc, điều phối lưu và tải. Mô-đun miền không giữ tham chiếu tới nhau, ngoại trừ phụ thuộc cứng được truyền qua hàm khởi tạo hoặc `Callable` được tiêm; chúng nói chuyện bằng **tín hiệu phát ra cho `Main`**.
2. **Không dùng autoload, không dùng bus sự kiện toàn cục.** Tín hiệu là tín hiệu của chính mô-đun phát ra.
3. **Một scene gốc.** `main.tscn` là scene duy nhất. Màn bắt đầu, bảng Tạm dừng, Tuỳ chọn là lớp phủ `CanvasLayer` do `Main` sở hữu, không phải scene riêng. "Game mới" đặt lại mọi mô-đun qua một hàm duy nhất của `Main`; cơ chế cụ thể quyết cùng GDD màn bắt đầu (#14).
4. **Hàm xử lý chéo nằm trong `Main`**, đặt tên `_on_<mô-đun>_<tín-hiệu>`. Giao diện chỉ phát yêu cầu (`sell_requested`, `hand_over_requested`...), không bao giờ sửa trạng thái miền.
5. **Tiêm phụ thuộc:** phụ thuộc cứng qua hàm khởi tạo; truy vấn tuỳ chọn hoặc muộn qua thuộc tính `Callable` (`FarmGrid.crop_unlock_check`, `NeighborBook.level_provider`). Gọi `is_valid()` trước khi dùng và **nêu rõ nghĩa của `Callable` thiếu cho từng thuộc tính**: `crop_unlock_check` thiếu thì mọi cây gieo được (hành vi hiện tại, dành cho kiểm thử); `level_provider` thiếu thì `push_error` và coi mức làng là 0, vì một nhà cung cấp mức bị quên sẽ che một lỗi ghép nối. Ưu tiên tiêm bằng **hàm thành viên**; không dùng lambda gán lại biến cục bộ bên ngoài (lambda bắt giá trị). Lambda chỉ phát tín hiệu hay đặt một trường là chấp nhận được.
6. **`VillageProgress` không biết `NeighborBook`.** Bỏ `bind_book`; `Main` nối `request_completed` vào một hàm công khai thuần của `VillageProgress`. Không còn ngoại lệ nào cho quy tắc 1.
7. **Làm mới sau khi tải bằng một chỗ:** `Main._refresh_all()` gọi `sync()` của từng view và mô-đun trình bày. Mọi view mới phải có `sync()` và được thêm vào hàm này; một bài kiểm tự động xác nhận danh sách đầy đủ.
8. **Quy tắc tách composer:** khi `main.gd` vượt **500 dòng**, hoặc việc ghép nối của một tính năng vượt **10 kết nối tín hiệu** trong `Main`, tách phần ghép nối của tính năng đó thành một lớp composer riêng (`<Tính năng>Composer`) sở hữu việc dựng và nối của tính năng; `Main` chỉ giữ nối cấp cao nhất. Hai ngưỡng này là giá trị khởi điểm do ADR đặt ra (hiện 384 dòng, bảy hệ thống sắp thêm), xem lại sau Vertical Slice.
9. **Lỗi khởi động phải thấy:** nếu nạp dữ liệu hay dựng mô-đun thất bại, `Main` hiện toàn màn hình, trên một `CanvasLayer` nằm trên nền, một thông báo lỗi (tên file hoặc mô-đun và lý do) thay vì màn hình trống; `_initialised` giữ `false` nên không tick, không nhập liệu, không lưu. Chữ lỗi hiện là tiếng Việt viết thẳng trong mã (khoảng trống bản địa hoá đã ghi ở thư viện mẫu tương tác).
10. **`Main` có đúng một API công khai: `save_game() -> bool`.**
11. **Mỗi lớp phủ phải chặn chạm xuống bản đồ.** Mọi `CanvasLayer` mới (màn bắt đầu, Tạm dừng, Tuỳ chọn, lỗi khởi động) phải có nền toàn màn hình với `MOUSE_FILTER_STOP`, hoặc đăng ký với `Hud.blocks_point`. `blocks_point` được giữ làm lớp bảo vệ thứ hai cho `_on_tap`, không dựa riêng vào việc `Button` tiêu thụ sự kiện.
12. **Ghép nối chỉ chạy một lần.** `_build()` và `_wire()` chạy đúng một lần khi khởi động. "Game mới" và tải lại dùng phương thức đặt lại hoặc `from_dict` trên các mô-đun đã có, không dựng lại; nếu không, tín hiệu bị nối hai lần. Thứ tự mùa, giai đoạn, ngày của `DayClock` được giữ bằng thứ tự `connect` trong `_wire()`.

### Architecture Diagram
```
                    Main  (gốc ghép nối duy nhất: dựng, nối, tiêm, lưu, làm mới)
   ┌───────────┬───────────┬──────────────┬─────────────┬──────────────┐
 DayClock    CropDB     SaveGame        Player     Hud + bảng (chỉ phát yêu cầu)
   │ tín hiệu ra                              │ yêu cầu
   └───────────────────▶ Main handlers ◀──────┘
                          │  gọi miền · gọi sync() · lưu
                          ▼
   FarmGrid · Market · NeighborBook · VillageProgress · (Inventory, sau)
   (không tham chiếu nhau; phụ thuộc đến từ hàm khởi tạo hoặc Callable)
```

### Key Interfaces
```gdscript
# Main: ghép nối
func _ready() -> void:
    if not _build():            # dựng mô-đun, đọc dữ liệu; false khi lỗi
        _show_startup_error(_last_error)
        return
    _wire()                     # mọi connect() giữa các mô-đun nằm ở đây
    _load_saved_game()          # rồi _refresh_all()
    _initialised = true

func _refresh_all() -> void:    # danh sách làm mới sau khi tải, một chỗ duy nhất
    _hud.sync(...) ; _farm_view.sync() ; _village_view.sync() ; ...

func save_game() -> bool        # API công khai duy nhất của Main

# Mô-đun miền: tín hiệu ra, tiêm vào, không biết nhau
signal request_completed(neighbor_id: String, request_id: String, money: int)
var crop_unlock_check: Callable = Callable()      # func(crop_id: String) -> bool
var level_provider: Callable = Callable()         # func() -> int
func on_request_completed(count: int) -> void      # VillageProgress: hàm thuần, Main gọi

# Mẫu hợp đồng của view
func sync() -> void             # đọc lại trạng thái hiện tại, không hiệu ứng
```

### Implementation Guidelines
- Code **must** nối tín hiệu giữa hai mô-đun miền chỉ trong `Main` hoặc composer; code **must never** gọi `connect` giữa hai mô-đun miền trong chính các mô-đun đó.
- Code **must never** thêm autoload hay singleton toàn cục cho trạng thái hoặc sự kiện của game.
- Hàm xử lý chéo **must** đặt tên `_on_<mô-đun>_<tín-hiệu>`; giao diện **must never** gọi hàm sửa trạng thái miền.
- Tiêm `Callable` **must** ưu tiên hàm thành viên; **must** gọi `is_valid()` trước khi gọi và **must** nêu nghĩa của `Callable` thiếu cho thuộc tính đó. **Must never** dùng lambda gán lại biến cục bộ bên ngoài (lambda bắt giá trị).
- Mọi view mới **must** có `sync()` (đọc lại trạng thái, không hiệu ứng) và **must** được thêm vào `_refresh_all()`.
- Mọi lớp phủ mới **must** có nền toàn màn hình `MOUSE_FILTER_STOP` hoặc đăng ký với `Hud.blocks_point`.
- `_build()` và `_wire()` **must** chạy một lần; "game mới" **must** dùng đặt lại, **must never** dựng lại mô-đun rồi nối lần hai.
- Hàm xử lý tín hiệu **must never** gọi `free()`; dùng `queue_free()`.
- Khi `main.gd` vượt 500 dòng hoặc một tính năng vượt 10 kết nối, **must** tách composer trước khi thêm tính năng mới.
- Khi nạp hay dựng thất bại, **must** hiện lỗi cho người chơi trên một `CanvasLayer`; **must never** `return` im lặng khỏi `_ready()`.

## Alternatives Considered

### Alternative 1: Bus sự kiện toàn cục (autoload `Events`)
- **Description**: Một singleton có mọi tín hiệu; hệ thống nào cũng phát và nghe qua nó.
- **Pros**: Ít dòng nối; thêm hệ thống không phải sửa `Main`.
- **Cons**: Phụ thuộc ẩn qua tên singleton; khó kiểm thử riêng từng mô-đun; trái nguyên tắc tiêm phụ thuộc của dự án; khó biết ai phản ứng với sự kiện nào.
- **Rejection Reason**: Đánh đổi khả năng kiểm thử và truy vết để lấy ít dòng nối, trong khi quy mô (17 hệ thống, một người làm) chưa cần.

### Alternative 2: Composer theo tính năng ngay từ đầu
- **Description**: Tách ngay composer cho ruộng, chợ, hàng xóm, làng; `Main` chỉ nối cấp cao.
- **Pros**: `Main` luôn nhỏ; mỗi tính năng tự chứa.
- **Cons**: Nhiều file và một lớp gián tiếp thêm khi mới có sáu hệ thống; ranh giới giữa các composer chưa rõ vì nhiều hiệu ứng chéo (nộp hàng cộng tiền, mở khoá hạt, dựng làng).
- **Rejection Reason**: Cấu trúc sớm hơn nhu cầu; chọn quy tắc tách bằng ngưỡng (mục 8) để tách khi thật sự cần.

### Alternative 3: Chuyển scene giữa màn bắt đầu và game
- **Description**: Màn bắt đầu là scene riêng; vào game thì chuyển sang scene gameplay, nên "game mới" tự sạch.
- **Pros**: Đặt lại trạng thái tự nhiên; tách rõ màn.
- **Cons**: Thêm một lớp quản lý scene; API chuyển scene không nằm trong tài liệu engine của dự án (rủi ro LOW, cần xác minh); `Main` hiện dựng mọi thứ trong mã nên phải tách phần dựng.
- **Rejection Reason**: Chưa có màn bắt đầu để biện minh; lớp phủ trong một scene đủ cho tới khi GDD #14 yêu cầu khác. Xem lại cùng #14.

### Alternative 4: `Main` phát tín hiệu `state_loaded`, view tự đăng ký
- **Description**: Sau khi tải, `Main` phát một tín hiệu; mọi view lắng nghe và tự làm mới.
- **Pros**: Thêm view không phải sửa `Main`.
- **Cons**: Ngầm định; khó truy vết thứ tự làm mới; dễ quên đăng ký mà không có lỗi nào báo.
- **Rejection Reason**: Một danh sách tường minh trong `_refresh_all()`, có kiểm thử, dễ đảm bảo hơn.

## Consequences

### Positive
- Một quy tắc rõ cho mọi hệ thống mới: ai nối, ai gọi ai, ghi ở đâu.
- Mô-đun miền không biết nhau nên kiểm thử riêng được; dễ thay `Inventory` vào.
- Lỗi khởi động và lỗi làm mới sau tải không còn im lặng.
- Không singleton nào để gỡ khi tái cấu trúc.

### Negative
- `Main` tiếp tục lớn lên tới khi tách composer; mọi hệ thống mới sửa ít nhất một chỗ trong `Main`.
- Hàm xử lý chéo tập trung ở một chỗ: người đọc phải đọc `Main` mới hiểu tương tác giữa các hệ thống.
- Hai ngưỡng tách (500 dòng, 10 kết nối) là giá trị khởi điểm, không có dữ liệu lịch sử.
- `Main` khó kiểm thử đơn vị; cần test tích hợp (`tests/integration/` hiện trống).

## Risks
- **`Main` thành god-object.** Giảm nhẹ: ngưỡng tách ở mục 8; kiểm khi rà soát mã.
- **Thứ tự tín hiệu ngầm.** Thứ tự mùa, giai đoạn, ngày đã được GDD thời gian chốt, nhưng `Main` phụ thuộc vào nó (sang mùa bị tin ngày ghi đè). Giảm nhẹ: ADR thông báo xếp hàng (từ tài liệu trợ năng) và test tích hợp.
- **Quên thêm view vào `_refresh_all()`.** Giảm nhẹ: bài kiểm tự động đối chiếu danh sách view.
- **Hành vi chuột giả lập ở 4.7 chưa xác minh** (NOT SOURCEABLE). Giảm nhẹ: kiểm trên máy thật trước khi chấp nhận ADR nhập liệu chạm.
- **Việc `Button` đã bật tiêu thụ sự kiện chạm trước `_unhandled_input` chưa xác minh trong tài liệu engine** (từ trí nhớ). Giảm nhẹ: mã không dựa vào đó, `Hud.blocks_point` là lớp bảo vệ thứ hai (quy tắc 11).
- **Nối tín hiệu hai lần** khi dựng lại mô-đun. Giảm nhẹ: quy tắc 12 và test tích hợp.
- **Kiểm bởi chuyên gia Godot (2026-10-27):** không có vấn đề chặn; tám ghi chú nhỏ đã được đưa vào các quy tắc 5, 9, 11, 12, phần Migration Plan và phần này.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| time-system.md | TR-time-003: thứ tự tín hiệu mùa, giai đoạn, ngày; `Main` nối với ruộng, HUD, lưu | Quy tắc 1 và 4: `Main` nối và xử lý `day_advanced`, `season_changed`, `phase_changed` |
| farming-system.md | TR-farm-003: `advance_day` và mùa được đẩy vào qua `Main` | Quy tắc 1 và 4 |
| farming-system.md | TR-farm-005: kiểm khoá cây bằng `Callable` tiêm vào | Quy tắc 5 |
| market-system.md | TR-market-004: thay đổi túi và tiền phát tín hiệu cho HUD | Quy tắc 1, 4 và 7 |
| neighbors-system.md | TR-neighbors-003: mức làng qua nhà cung cấp tiêm vào | Quy tắc 5 (`level_provider`) |
| neighbors-system.md | TR-neighbors-004: `request_completed`; `Main` chuyển tiền thưởng | Quy tắc 1 và 4 |
| village-restoration.md | TR-village-004: làng chạy theo `request_completed` | Quy tắc 6: `Main` nối, `VillageProgress` không biết `NeighborBook` |

## Performance Implications
- **CPU**: Không đáng kể; tín hiệu GDScript rẻ, `_refresh_all()` chỉ chạy sau khi tải.
- **Memory**: Không đổi.
- **Load Time**: Không đổi; thêm một bước kiểm lỗi khởi động.
- **Network**: Không áp dụng.

## Migration Plan
1. `VillageProgress`: bỏ `bind_book`, thêm hàm công khai thuần; `Main` nối `request_completed` vào đó.
2. Thêm `sync()` cho mỗi view và `Main._refresh_all()`; thay danh sách tay trong `_load_saved_game()`. Đổi `VillageView.sync_instant()` thành `sync()` và thay `_farm_view.queue_redraw()` bằng `FarmView.sync()`.
3. Thêm `_show_startup_error()` và thay các `return` im lặng trong `_ready()`.
4. Tách `_ready()` thành `_build()`, `_wire()`, `_load_saved_game()`.
5. Viết test tích hợp cho ghép nối trong `tests/integration/`.
6. ADR `Inventory` sẽ áp dụng cùng quy tắc ngay khi tách.

## Validation Criteria
- Không có mục `[autoload]` trong `project.godot`.
- Không còn `bind_book` hay `connect` trực tiếp giữa hai mô-đun miền trong `src/gameplay/`.
- Một bài kiểm tự động xác nhận mọi view đăng ký trong `_refresh_all()`.
- Khi một file dữ liệu bị xoá, game hiện thông báo lỗi thay vì màn hình trống.
- `main.gd` còn dưới 500 dòng, hoặc đã có composer theo quy tắc ở mục 8.

## Related
- ADR-0001 (định dạng lưu): `Main.save_game` dùng API của nó.
- `docs/architecture/architecture.md`: Layer Map, Module Ownership, Data Flow, API Boundaries.
- `design/gdd/time-system.md`, `farming-system.md`, `market-system.md`, `neighbors-system.md`, `village-restoration.md`.
- `docs/architecture/architecture-review-2026-10-27.md`: khoảng trống nền tảng mà ADR này đóng.
