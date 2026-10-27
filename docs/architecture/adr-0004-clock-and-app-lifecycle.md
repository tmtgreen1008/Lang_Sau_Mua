# ADR-0004: Đồng hồ và vòng đời ứng dụng

## Status
Proposed

## Date
2026-10-27

## Last Verified
2026-10-27

## Decision Makers
To Truong (người làm game), cùng phiên `/architecture-decision`.

## Summary
`DayClock` cộng thẳng `delta` thô nên một lần quay lại từ nền có thể làm game nhảy nhiều ngày và ghi file nhiều lần, đồng hồ không tạm dừng khi mở bảng, chưa có Tốc độ ngày, và vòng đời Android chưa được định nghĩa. Quyết định: `DayClock` tự kẹp bước thời gian theo `max_step_seconds` từ dữ liệu, có nhiều nguồn tạm dừng do `Main` đặt (bảng mở, ứng dụng bị tạm dừng, mất focus, người chơi), có Tốc độ ngày ba mức từ dữ liệu, và `Main` ánh xạ rõ từng thông báo vòng đời vào tạm dừng và lưu.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH theo `VERSION.md`. Không có thay đổi API vòng đời hay thời gian ở 4.5 đến 4.7 trong `breaking-changes.md`, nhưng hành vi vòng đời trên Android hoàn toàn không có trong tài liệu engine |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/input.md`, `modules/ui.md` |
| **Post-Cutoff APIs Used** | Không có API mới. Dùng `Node._notification` với tám thông báo: `NOTIFICATION_APPLICATION_PAUSED`, `_RESUMED`, `_FOCUS_IN`, `_FOCUS_OUT`; `NOTIFICATION_WM_WINDOW_FOCUS_IN`, `_FOCUS_OUT`; `NOTIFICATION_WM_CLOSE_REQUEST`; `NOTIFICATION_WM_GO_BACK_REQUEST`. **Đã quan sát:** cả tám tên đều tồn tại và biên dịch được ở Godot 4.7.2 trên máy tính (kiểm bằng `--check-only`, có đối chứng âm: tên giả báo lỗi và exit 1) |
| **Verification Required** | Tất cả **NOT SOURCEABLE**, kiểm trên máy Android thật: (1) khi nào và theo thứ tự nào mỗi thông báo đến (PAUSED, FOCUS_OUT, WM_WINDOW_FOCUS_OUT, RESUMED, FOCUS_IN); (2) còn bao nhiêu thời gian để ghi file đồng bộ trong lúc PAUSED; (3) `delta` của khung hình đầu tiên sau khi quay lại có bị engine kẹp không; (4) nút Back có gửi `WM_GO_BACK_REQUEST` hay thoát thẳng, và cài đặt dự án nào quyết định (tên cài đặt `application/config/quit_on_go_back` là từ trí nhớ, chưa xác minh; `project.godot` hiện không có); (5) `auto_accept_quit` giữ mặc định thì `WM_CLOSE_REQUEST` có dẫn tới thoát sau khi lưu |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (`Main` đặt nguồn tạm dừng và xử lý thông báo), ADR-0003 (thêm khoá bắt buộc vào `time_config.json` qua `configure` và `DataValidator`) |
| **Enables** | ADR giao diện (bảng Tạm dừng, Tuỳ chọn), ADR nơi lưu thiết lập trợ năng (lưu Tốc độ ngày), ADR chính sách phiên bản bản lưu (độ bền ghi) |
| **Blocks** | Story kẹp bước thời gian, tạm dừng khi mở bảng, Tốc độ ngày, xử lý nút Back |
| **Ordering Note** | Độ bền ghi file (không `fsync`, phục hồi `.tmp`, giữ `.bak` là bản tốt cuối) là việc còn lại của ADR-0001 và thuộc ADR chính sách phiên bản bản lưu kế tiếp, không thuộc ADR này. ADR này chỉ quyết **khi nào** lưu |

## Context

### Problem Statement
Đọc từ `day_clock.gd` và `main.gd`:
- `tick(delta)` cộng `delta` thô rồi lặp `while` qua mọi giai đoạn và ngày đã vượt. Một `delta` 300 giây phát ba lần `day_advanced` liên tiếp.
- Mỗi `day_advanced`, `Main` gọi `grid.advance_day()` **và `save_game()`**. Quay lại sau lâu thì cây lớn hoặc héo nhiều ngày và file bị ghi nhiều lần, trái ý định đã xác nhận trong GDD thời gian ("ngoài game không trôi thời gian").
- `Main._process` truyền `delta` thô, không biết bảng đang mở; đồng hồ chạy khi bảng chợ hay hàng xóm mở.
- `_notification` chỉ lưu khi `PAUSED`, `FOCUS_OUT`, `WM_WINDOW_FOCUS_OUT`, `WM_CLOSE_REQUEST`; không xử lý quay lại (`RESUMED`, `FOCUS_IN`) và không xử lý nút Back. Trên máy tính, mất focus lưu hai đến ba lần liền.
- Thứ tự phát khi sang ngày là đổi mùa, đổi giai đoạn, sang ngày; hai tin báo (sang mùa, sang ngày) bị ghi đè nhau (xử lý trong ADR thông báo).
- Chưa có tạm dừng hay tốc độ ngày, trong khi tài liệu trợ năng cam kết mức Standard ("không có thao tác định giờ không thể kéo dài").

### Constraints
- `DayClock` là `RefCounted` thuần, xác định, không đọc đồng hồ hệ thống (TR-time-001).
- Quy tắc ADR-0002: `DayClock` không biết bảng hay ứng dụng; `Main` là nơi duy nhất nối và điều phối.
- Quy tắc ADR-0003: giá trị tuning đến từ dữ liệu; khoá mới trong `time_config.json` là bắt buộc.
- Hành vi vòng đời Android chưa kiểm được trong phiên làm việc này (không có máy thật, không có bản xuất).
- Chỉ cảm ứng; tất cả chạy trên luồng chính.

### Requirements
- TR-time-001: `tick(delta)` được đưa từ ngoài vào; không đọc đồng hồ hệ thống.
- TR-time-004: bước thời gian lớn, bảng mở, ứng dụng ở nền: không được nhảy ngày; ý định "đồng hồ tạm dừng khi bảng mở và khi ứng dụng ở nền".
- Từ `design/accessibility-requirements.md`: Tốc độ ngày (Bình thường, Chậm gấp đôi, Dừng), tạm dừng ở mọi trạng thái, Back không thoát đột ngột.

## Decision

1. **`DayClock` tự kẹp bước thời gian.** Mỗi lần `tick(delta)`, bước dùng là `minf(delta, max_step_seconds)`. `max_step_seconds` đọc từ `time_config.json` (khoá bắt buộc, số >0; giá trị khởi điểm **0,25 giây**) và phải ≤ độ dài giai đoạn ngắn nhất, để một lần `tick` vượt qua nhiều nhất một ranh giới giai đoạn. Kẹp nằm trong `DayClock` (không phải `Main`) để mọi người gọi và mọi bài kiểm được hưởng. Giá trị 0,25 là điểm khởi đầu: một khựng khung hình tới 250 ms vẫn trôi đúng; dưới 4 khung hình mỗi giây thì game chạy chậm hơn thời gian thật, chấp nhận được. `tick` phải trả về sớm khi bước đã kẹp và nhân tốc độ bằng 0 (không chỉ khi `delta` thô ≤0). Tính chất "tối đa một ranh giới giai đoạn mỗi lần `tick`" là **hệ quả suy ra**, không phải mã riêng: bước ≤ giai đoạn ngắn nhất, và `from_dict` bảo đảm thời gian đã trôi < độ dài giai đoạn (`day_clock.gd`); vòng `while` hiện có giữ nguyên.
2. **Nhiều nguồn tạm dừng.** `DayClock.set_paused(source: StringName, paused: bool)` và `is_paused()`; đồng hồ đứng khi còn bất kỳ nguồn nào bật. Năm nguồn: `&"panel"` (có bảng mở), `&"app_paused"` (PAUSED/RESUMED), `&"app_focus"` (APPLICATION_FOCUS_OUT/IN), `&"window_focus"` (WM_WINDOW_FOCUS_OUT/IN), `&"player"` (bảng Tạm dừng, do ADR giao diện dựng). Mỗi họ thông báo có nguồn riêng vì thứ tự và việc chúng có đến hay không trên Android chưa biết (NOT SOURCEABLE); một cờ chung có thể bị tắt sớm hoặc kẹt bật. Khi `APPLICATION_RESUMED` đến, `Main` tắt **cả ba** nguồn `app_*` và `window_focus` làm lưới an toàn: ứng dụng đã ở tiền cảnh.
3. **Tạm dừng chỉ áp cho `DayClock`.** Không dùng `SceneTree.paused`. `Player` không biết về tạm dừng: nhân vật đang đi dở sẽ đi nốt và việc chờ được giữ nguyên; bảng Tạm dừng và các bảng chặn chạm mới nên không phát sinh việc mới.
4. **Tốc độ ngày.** `DayClock.set_day_speed(mode: StringName)` với `normal`, `slow`, `stop`. Bảng hệ số đọc từ `time_config.json`: `day_speed` = `{normal: 1.0, slow: 0.5, stop: 0.0}` (khoá bắt buộc; mỗi hệ số là số ≥0, `normal` >0). Bước thực dùng là `step * hệ_số`. `stop` làm đồng hồ không tiến; `sleep()` không bị ảnh hưởng bởi tốc độ ngày nên "Đi ngủ" vẫn là cách duy nhất qua ngày ở chế độ `stop`. Vì `sleep()` bỏ qua tạm dừng, **`Main` phải chặn nút "Đi ngủ" khi có bảng hoặc bảng Tạm dừng đang mở**. Tốc độ ngày chỉ nằm trong `DayClock`; **không dùng `Engine.time_scale`** (nó nhân cả `delta` của mọi thứ khác). Chế độ mặc định khi khởi động là `normal`; `Main` áp giá trị đã lưu sau khi tải (nơi lưu: ADR thiết lập trợ năng).
5. **`Main` ánh xạ thông báo vòng đời** (trong `_notification`):

| Thông báo | Tác dụng |
|---|---|
| `APPLICATION_PAUSED` | bật `app_paused`; **lưu** |
| `APPLICATION_RESUMED` | tắt `app_paused`, `app_focus` và `window_focus` |
| `APPLICATION_FOCUS_OUT` | bật `app_focus`; **lưu** |
| `APPLICATION_FOCUS_IN` | tắt `app_focus` |
| `WM_WINDOW_FOCUS_OUT` | bật `window_focus`; **lưu** |
| `WM_WINDOW_FOCUS_IN` | tắt `window_focus` |
| `WM_CLOSE_REQUEST` | **lưu**; để engine thoát (giữ mặc định `auto_accept_quit`) |
| `WM_GO_BACK_REQUEST` | xem quy tắc 7 |

6. **Lưu một lần, bỏ qua khi không đổi.** `Main.save_game()` so chuỗi JSON của trạng thái với lần ghi thành công gần nhất và bỏ qua khi giống nhau. Vì đồng hồ đã tạm dừng, trạng thái ngay sau `PAUSED` và `FOCUS_OUT` giống nhau nên lần thứ hai không ghi. Sự kiện lưu hiện có (sang ngày, bán, nộp nhờ vả) giữ nguyên. Độ bền của chính việc ghi file không thuộc ADR này.
7. **Nút Back.** `Main` xử lý `WM_GO_BACK_REQUEST`: đóng lớp phủ trên cùng nếu có; nếu không có thì mở bảng Tạm dừng. **Không bao giờ thoát ứng dụng trực tiếp.** Người chơi thoát từ bảng Tạm dừng hoặc bằng nút Home. Cần tắt hành vi "thoát khi Back" của engine bằng cài đặt dự án `application/config/quit_on_go_back` (tên từ trí nhớ, chưa xác minh; `project.godot` hiện không có); phương án dự phòng là gọi `get_tree().set_quit_on_go_back(false)` lúc khởi động (cũng từ trí nhớ, chưa xác minh). Việc `WM_GO_BACK_REQUEST` vẫn được gửi tới `_notification` khi cài đặt này bật hay tắt chưa biết (xem Verification Required).
8. **Quay lại không bù thời gian.** Khi ứng dụng quay lại, đồng hồ tiếp tục từ chỗ dừng; không tính thời gian đã ở nền (không dùng đồng hồ hệ thống, không có "tiến độ ngoại tuyến"). Kẹp ở quy tắc 1 là lưới an toàn cho khung hình đầu tiên sau khi quay lại, dù thông báo RESUMED đến trước hay sau khung hình đó.
9. **Nguồn `panel` được tính lại mỗi khung hình, không theo sự kiện.** Đầu mỗi `Main._process`, `Main` đặt `set_paused(PAUSE_PANEL, any_panel_open())`, với `any_panel_open()` là `is_open()` của các bảng (cùng cách `_on_tap` đã dùng). Không có trạng thái để quên tắt, và không phụ thuộc thời điểm của `visibility_changed`. Bảng món ăn hiện được nối thẳng từ HUD tới `DishPanel.open`, không qua `Main`; việc tính theo khung hình làm điều này không ảnh hưởng, nhưng nó vẫn nên đi qua `Main` theo ADR-0002.
10. **Dữ liệu.** `time_config.json` có thêm hai khoá bắt buộc: `max_step_seconds`, `day_speed`; ghi trong `_schema`; `DayClock.configure` và `DataValidator` kiểm theo ADR-0003 (ví dụ `max_step_seconds` ≤ giai đoạn ngắn nhất).

### Architecture Diagram
```
 thông báo vòng đời ──▶ Main._notification ──▶ DayClock.set_paused(app_paused | app_focus, ...)
 bảng mở/đóng ───────▶ Main (gom "có bảng nào mở")──▶ DayClock.set_paused(panel, ...)
 bảng Tạm dừng ──────▶ Main ──▶ DayClock.set_paused(player, ...)
 Tuỳ chọn tốc độ ────▶ Main ──▶ DayClock.set_day_speed(normal | slow | stop)
 _process(delta) ────▶ Main ──▶ DayClock.tick(delta)
                                   │ bước = min(delta, max_step_seconds) × hệ_số_tốc_độ
                                   │ (không làm gì nếu còn nguồn tạm dừng)
                                   ▼ tối đa một ranh giới giai đoạn mỗi lần
                          season_changed → phase_changed → day_advanced
 PAUSED / FOCUS_OUT / CLOSE_REQUEST ──▶ Main.save_game (bỏ qua nếu trạng thái không đổi)
 WM_GO_BACK_REQUEST ──▶ Main: đóng lớp phủ trên cùng, hoặc mở bảng Tạm dừng
```

### Key Interfaces
```gdscript
# DayClock
func tick(delta: float) -> void                      # kẹp, tạm dừng, nhân tốc độ; tối đa một ranh giới giai đoạn
func set_paused(source: StringName, paused: bool) -> void
func is_paused() -> bool
func set_day_speed(mode: StringName) -> void         # &"normal" | &"slow" | &"stop"; mode lạ bị bỏ qua và ghi lỗi
func sleep() -> void                                 # không bị ảnh hưởng bởi tốc độ hay tạm dừng

const PAUSE_PANEL := &"panel"
const PAUSE_APP := &"app_paused"
const PAUSE_FOCUS := &"app_focus"
const PAUSE_WINDOW := &"window_focus"
const PAUSE_PLAYER := &"player"

# time_config.json (khoá mới, bắt buộc)
#   "max_step_seconds": 0.25
#   "day_speed": { "normal": 1.0, "slow": 0.5, "stop": 0.0 }

# Main
func _notification(what: int) -> void                # ánh xạ ở quy tắc 5 và 7
func _process(delta: float) -> void                  # đầu hàm: set_paused(PAUSE_PANEL, any_panel_open()) rồi tick(delta)
func any_panel_open() -> bool                        # một chỗ duy nhất tính "có bảng nào mở"
```

### Implementation Guidelines
- `DayClock` **must** kẹp bước theo `max_step_seconds` và **must never** đọc đồng hồ hệ thống.
- `DayClock` **must never** biết về bảng, ứng dụng hay vòng đời; `Main` **must** là nơi duy nhất gọi `set_paused`.
- Nguồn tạm dừng **must** là một trong năm hằng số đã định nghĩa; **must never** dùng một cờ chung cho các nguồn có thể đến không theo thứ tự.
- Nguồn `panel` **must** được tính lại mỗi khung hình từ `is_open()` của các bảng; **must never** bật hay tắt nó theo sự kiện mở và đóng.
- Tốc độ ngày **must** nằm trong `DayClock`; **must never** dùng `Engine.time_scale`.
- `Main` **must** chặn nút "Đi ngủ" khi có bảng hoặc bảng Tạm dừng đang mở, vì `sleep()` bỏ qua tạm dừng.
- Mỗi lần `tick` **must** vượt tối đa một ranh giới giai đoạn; **must never** vòng lặp phát nhiều `day_advanced` trong một lần gọi.
- `Main` **must** xử lý cả hai chiều của mỗi cặp thông báo (`PAUSED` và `RESUMED`, `FOCUS_OUT` và `FOCUS_IN`); **must never** chỉ bật nguồn mà quên tắt.
- Lưu khi vòng đời **must** đồng bộ trong lúc xử lý thông báo (ADR-0001) và **must** bỏ qua khi trạng thái không đổi.
- Nút Back **must never** thoát ứng dụng trực tiếp.
- Mọi giá trị tuning (`max_step_seconds`, hệ số tốc độ) **must** đến từ dữ liệu (ADR-0003).
- Thay đổi hành vi vòng đời **must** được kiểm trên máy Android thật trước khi ADR được chuyển sang Accepted.

## Alternatives Considered

### Alternative 1: Dừng bằng `SceneTree.paused`
- **Description**: Đặt cả cây scene ở trạng thái tạm dừng; lớp phủ Tạm dừng chạy ở chế độ luôn xử lý.
- **Pros**: Đóng băng mọi thứ (nhân vật, tween) mà đồng hồ không cần biết gì.
- **Cons**: Phải cấu hình `process_mode` cho từng lớp phủ; `SceneTree.paused` không có trong tài liệu engine của dự án (từ trí nhớ, chưa xác minh); khó kiểm thử `DayClock` riêng; kéo thêm hành vi vào `Player`, hiệu ứng làng.
- **Rejection Reason**: Chỉ đồng hồ mới cần dừng (nhân vật không thể nhận việc mới khi bảng chặn chạm); chọn cách hẹp, kiểm thử được.

### Alternative 2: Chỉ kẹp bước, không tạm dừng
- **Description**: Kẹp `delta` rồi để đồng hồ chạy mọi lúc.
- **Pros**: Ít mã nhất; ngăn nhảy ngày.
- **Cons**: Đồng hồ vẫn chạy khi bảng mở và khi ở nền (mỗi lần ở nền 10 giây vẫn trôi thời gian); không đáp ứng ý định "ngoài game không trôi thời gian" lẫn yêu cầu trợ năng.
- **Rejection Reason**: Không đáp ứng yêu cầu đã xác nhận.

### Alternative 3: Bù thời gian đã vắng (tiến độ ngoại tuyến)
- **Description**: Đọc đồng hồ hệ thống hoặc thời gian ở nền rồi tiến game tương ứng khi quay lại.
- **Pros**: Cảm giác "thế giới vẫn chạy".
- **Cons**: Trái ý định đã xác nhận (không mất vụ khi vắng); cần đọc đồng hồ hệ thống (trái TR-time-001); dễ bị lợi dụng đổi giờ máy; một trụ cột là "không áp lực".
- **Rejection Reason**: Trái GDD thời gian và trụ cột "ấm áp, không áp lực".

### Alternative 4: Kẹp bằng `Main` thay vì bên trong `DayClock`
- **Description**: `Main` kẹp `delta` trước khi gọi `tick`.
- **Pros**: `DayClock` không đổi.
- **Cons**: Mỗi người gọi phải nhớ kẹp; bài kiểm của `DayClock` không bắt được lỗi; luật nằm ở chỗ khó kiểm thử (`Main`).
- **Rejection Reason**: Bất biến thuộc về `DayClock`; để nơi sở hữu dữ liệu tự bảo vệ.

## Consequences

### Positive
- Quay lại từ nền không còn nhảy ngày hay ghi file nhiều lần.
- Đồng hồ dừng khi mở bảng và khi ở nền, đáp ứng GDD thời gian và yêu cầu trợ năng.
- Tốc độ ngày là dữ liệu, chỉnh được không cần sửa mã.
- Mỗi thông báo vòng đời có tác dụng rõ, kiểm thử được bằng cách gọi `notification(what)` trên máy tính.
- Nút Back không còn gây thoát đột ngột.

### Negative
- Hai khoá dữ liệu mới và thêm bốn nguồn tạm dừng làm `DayClock` và `Main` phức tạp hơn.
- Kẹp 0,25 giây làm game chạy chậm hơn thời gian thật khi khung hình dưới 4 mỗi giây.
- Người chơi mở bảng để "nghĩ" sẽ thấy đồng hồ đứng, khác với hành vi hiện tại (đây là ý định đã xác nhận).
- Hành vi vòng đời Android vẫn là giả định cho tới khi kiểm trên máy thật.

## Risks
- **Thứ tự và thời điểm các thông báo Android chưa biết** (NOT SOURCEABLE). Giảm nhẹ: nguồn riêng cho `app_paused` và `app_focus`; kiểm trên máy thật; ADR chưa được Accepted khi chưa kiểm.
- **Thời gian ghi file trong `PAUSED` có thể không đủ** (NOT SOURCEABLE). Giảm nhẹ: ghi đồng bộ vài KB (ADR-0001); bỏ qua khi không đổi; độ bền ghi xử lý ở ADR phiên bản bản lưu.
- **Tên cài đặt tắt "thoát khi Back" chưa xác minh.** Giảm nhẹ: kiểm khi tạo `export_presets.cfg` và bản xuất đầu tiên; nếu cài đặt không như dự kiến, Back có thể thoát ngay và ADR phải sửa.
- **Quên tắt một nguồn tạm dừng** làm đồng hồ đứng vĩnh viễn. Giảm nhẹ: quy tắc xử lý hai chiều; bài kiểm gọi chuỗi PAUSED, RESUMED, FOCUS_OUT, FOCUS_IN theo nhiều thứ tự và khẳng định đồng hồ chạy lại.
- **Giá trị 0,25 giây do ADR đặt**, không có dữ liệu đo. Giảm nhẹ: là dữ liệu, chỉnh được; xem lại sau khi đo trên máy thật.
- **Họ thông báo `WM_WINDOW_FOCUS_*` có thể không đến trên Android** (từ trí nhớ). Giảm nhẹ: có nguồn riêng và `RESUMED` tắt cả ba nguồn `app_*`/`window_focus`.
- **Kiểm bởi chuyên gia Godot (2026-10-27):** không có vấn đề chặn. Tài liệu engine của dự án không có nội dung nào về vòng đời, nên mọi khẳng định về hành vi Android trong ADR này là từ trí nhớ, chưa xác minh. Các ghi chú nhỏ (tách nguồn focus, tick trả về sớm khi bước bằng 0, tính nguồn `panel` mỗi khung hình, không dùng `Engine.time_scale`, phương án dự phòng cho Back) đã đưa vào các quy tắc 1, 2, 4, 5, 7, 9 và Implementation Guidelines.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| time-system.md | TR-time-001: `tick(delta)` được đưa từ ngoài vào, không đọc đồng hồ hệ thống | Quy tắc 1 và 8: `DayClock` giữ `tick(delta)`, kẹp bên trong, không dùng đồng hồ hệ thống |
| time-system.md | TR-time-004: bước lớn, bảng mở, nền: không nhảy ngày; ý định đồng hồ dừng khi bảng mở và khi ở nền | Quy tắc 1, 2, 5, 8, 9: kẹp, bốn nguồn tạm dừng, ánh xạ vòng đời, không bù thời gian |
| time-system.md | Tiêu chí 7 và 8 (chưa cài): đồng hồ không tiến khi bảng mở hoặc ở nền | Quy tắc 2, 5 và 9 |
| time-system.md | Tiêu chí 9 và ý định mùa dài (dữ liệu) | Không đổi ở ADR này; khoá mới nằm cạnh `days_per_season` trong cùng file |

## Performance Implications
- **CPU**: Không đáng kể; thêm vài phép so sánh mỗi khung hình trong `tick`.
- **Memory**: Không đổi.
- **Load Time**: Không đổi; thêm hai khoá dữ liệu được kiểm một lần.
- **Network**: Không áp dụng.

## Migration Plan
1. Thêm `max_step_seconds` và `day_speed` vào `time_config.json` (giá trị khởi điểm trong quy tắc 1 và 4) và `_schema`.
2. `DayClock`: thêm kẹp, nguồn tạm dừng, tốc độ ngày; sửa `tick` để vượt tối đa một ranh giới giai đoạn.
3. `Main`: mở rộng `_notification` theo bảng ở quy tắc 5 và 7; thêm `_update_panel_pause()`; thêm bỏ qua lưu khi trạng thái không đổi.
4. Viết bài kiểm trong `tests/unit/time/` (kẹp, nguồn tạm dừng, tốc độ, `sleep` bất biến) và `tests/integration/` (gọi `notification(what)` theo nhiều thứ tự).
5. Cập nhật GDD thời gian (các Edge Case về bước lớn).
6. Khi có bản xuất Android: kiểm tất cả mục trong Verification Required trên máy thật, rồi mới chấp nhận ADR.

## Validation Criteria
- Gọi `tick(300.0)` trên đồng hồ ở giai đoạn đầu ngày: không có `day_advanced` nào và tối đa một lần đổi giai đoạn.
- Chuỗi `PAUSED`, `RESUMED` khi ở giữa ngày: số ngày và `phase_elapsed` không đổi sau khi quay lại.
- Mọi thứ tự của `PAUSED`, `RESUMED`, `FOCUS_OUT`, `FOCUS_IN` kết thúc bằng đồng hồ chạy lại.
- Mở một bảng: đồng hồ đứng; đóng bảng: chạy lại; mở hai bảng liên tiếp không để lại nguồn `panel` treo.
- Tốc độ `slow` làm ngày dài gấp đôi; `stop` làm đồng hồ không tiến nhưng `sleep()` vẫn qua ngày.
- Lưu hai lần liền không đổi trạng thái chỉ ghi một lần.
- **Trên máy Android thật:** để ứng dụng ở nền vài phút rồi quay lại: số ngày không đổi, chỉ một bản lưu được ghi; nút Back khi không có bảng mở thì mở bảng Tạm dừng và không thoát.

## Related
- ADR-0001: ghi file lưu; độ bền ghi là việc của ADR phiên bản bản lưu.
- ADR-0002: `Main` là nơi duy nhất nối nguồn tạm dừng và xử lý thông báo.
- ADR-0003: khoá dữ liệu mới và kiểm tra.
- `design/gdd/time-system.md`, `design/accessibility-requirements.md` (Motor: Tốc độ ngày, tạm dừng; Cognitive: tạm dừng ở mọi trạng thái).
- `docs/architecture/architecture-review-2026-10-27.md`: khoảng trống mà ADR này đóng.
