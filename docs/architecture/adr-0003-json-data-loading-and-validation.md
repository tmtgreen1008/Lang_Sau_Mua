# ADR-0003: Nạp và kiểm tra dữ liệu JSON

## Status
Proposed

## Date
2026-10-27

## Last Verified
2026-10-27

## Decision Makers
To Truong (người làm game), cùng phiên `/architecture-decision`.

## Summary
Bốn bộ nạp JSON (`CropDatabase`, `DayClock`, `NeighborBook`, `VillageProgress`) mỗi nơi đọc file và kiểm lỗi một kiểu, chỉ báo lỗi ra console, bỏ qua mục sai và không kiểm tham chiếu giữa các file, nên dữ liệu sai làm game kẹt mà không ai thấy. Quyết định: một `DataLoader` dùng chung đọc JSON có dòng và lý do lỗi, mỗi mô-đun tách `configure(data, result)` khỏi việc đọc file, một `DataValidator` kiểm chéo giữa các file, lỗi cấu trúc và tham chiếu là lỗi chết hiển thị cho người chơi, và các hằng số gameplay đang viết cứng chuyển vào `game_config.json`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH theo `VERSION.md` (4.5 đến 4.7 sau mốc kiến thức). Các API dùng ở đây (`FileAccess`, `JSON`) không có thay đổi nào được ghi cho 4.5 đến 4.7 trong `breaking-changes.md` |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` (không có mô-đun tham chiếu cho Core) |
| **Post-Cutoff APIs Used** | Không có. `FileAccess.store_*` trả `bool` từ 4.4 chỉ liên quan tới ghi, không dùng ở đây |
| **Verification Required** | (1) **NOT SOURCEABLE:** tài liệu engine không nói file `.json` dưới `assets/data/` có vào bản xuất Android không. Theo trí nhớ (chưa xác minh), `.json` không phải loại resource nên bộ lọc xuất mặc định có thể bỏ nó, và phải đặt "Filters to export non-resource files" (ví dụ `assets/data/*`) trong preset xuất; dự án chưa có `export_presets.cfg`. Kiểm trên bản xuất thật đầu tiên. (2) `JSON.new().parse()` với `get_error_line()` và `get_error_message()` đã chạy trên 4.7.2 (quan sát khi chạy thử `SaveGame` với JSON hỏng: "line 0: Expected key"); `get_error_line()` chỉ có nghĩa sau một lần `parse()` thất bại; cần xác nhận số dòng đúng với file nhiều dòng |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (phải Accepted trước khi cài: lỗi nạp hiện ra qua quy tắc 9 của nó) |
| **Enables** | ADR `Inventory` và mô hình vật phẩm (cần schema vật phẩm), ADR đồng hồ và vòng đời (thêm trường `max_step_seconds`, tốc độ ngày vào `time_config.json`), ADR giao diện (thời lượng thông báo từ dữ liệu) |
| **Blocks** | Story chuyển hằng số cứng sang `game_config.json`; story thêm file dữ liệu mới (câu cá, nấu ăn, cốt truyện) |
| **Ordering Note** | Viết sau ADR-0002, trước ADR đồng hồ và vòng đời vì ADR đó thêm trường vào dữ liệu |

## Context

### Problem Statement
Dữ liệu nội dung (cây, thời gian, nhờ vả, làng) nằm trong `assets/data/*.json` (tổng khoảng 16 KB). Đọc từ mã hiện tại:
- Cả bốn bộ nạp đều lặp cùng một đoạn `file_exists`, `JSON.parse_string(get_file_as_string(...))`. `parse_string` trả `null` mà không kèm dòng hay lý do lỗi, trong khi `SaveGame` đã dùng `JSON.new().parse()` có `get_error_line()` và `get_error_message()`.
- Lỗi chỉ `push_error` ra console; `Main` chỉ `return` im lặng, người chơi thấy màn hình trống (cấm bởi `silent_startup_failure` của ADR-0002).
- Mục sai bị bỏ qua và game chạy tiếp thiếu nội dung ("skipping invalid ..."); `CropDatabase` chỉ thất bại khi không còn cây nào.
- **Không có kiểm chéo giữa file:** mùa của cây không đối chiếu với `time_config.json`; nhờ vả đòi cây không tồn tại thì không bao giờ hoàn thành; số lượng ≤0 không bị bắt; mốc mức làng không kiểm khoá chết (GDD hàng xóm yêu cầu; TR-neighbors-001).
- Chỉ `DayClock` có `configure(Dictionary)` tách khỏi đọc file; ba mô-đun còn lại phải đọc file thật mới kiểm thử được.
- Giá trị gameplay vẫn nằm cứng trong mã (tốc độ nhân vật 360, lưới 5×4, kích thước ô 80 px), trái quy tắc "giá trị gameplay đến từ dữ liệu".

### Constraints
- Định dạng nội dung là JSON (đã chốt trong GDD và ADR-0001); dữ liệu chỉ đọc khi chạy.
- Một người làm; nội dung có thể do người hoặc agent sửa bằng tay nên lỗi gõ nhầm là rủi ro thật.
- Phải tuân `silent_startup_failure`, `direct_cross_module_connect` và `callable_injection` trong registry (ADR-0002).
- Chữ Việt có dấu nằm ngay trong dữ liệu.

### Requirements
- TR-time-002: cấu hình thời gian từ `time_config.json`, lỗi thì nạp thất bại an toàn.
- TR-farm-002, TR-market-002, TR-market-005: dữ liệu cây và giá từ `crops.json`, có kiểm tra; giá hạt và giá theo mùa (ý định) cũng từ dữ liệu.
- TR-neighbors-001: `neighbors.json` có kiểm tra (số lượng >0, vật phẩm tồn tại, không khoá chết).
- TR-village-001: mảnh và mức làng từ JSON, có kiểm tra.
- TR-player-002: tốc độ nhân vật đọc từ dữ liệu.

## Decision

1. **Một định dạng, một nơi.** Nội dung là JSON dưới `assets/data/`, đọc một lần khi khởi động trong `Main._build()`, chỉ đọc khi chạy. Các file: `crops.json`, `time_config.json`, `neighbors.json`, `village_restoration.json` và **`game_config.json` (mới)**. Đường dẫn gom ở một chỗ (`DataPaths`), không rải trong `Main`.
2. **`DataLoader.read_json(path) -> DataResult`** là nơi duy nhất đọc JSON. Dùng `FileAccess` và `JSON.new().parse()`, trả lỗi kèm tên file, dòng và lý do. Không mô-đun nào tự đọc JSON.
3. **`DataResult`** (`RefCounted`) giữ `data: Dictionary`, `errors: Array[String]`, `warnings: Array[String]`, `ok() -> bool`. Mọi lỗi và cảnh báo đều ghi vị trí (file và đường dẫn trong file). Mỗi danh sách bị chặn ở **200 mục** (mục thứ 201 trở đi chỉ tăng bộ đếm), để một schema sai không sinh hàng nghìn dòng.
4. **Tách đọc và kiểm.** Mỗi mô-đun dữ liệu có `configure(data: Dictionary, result: DataResult) -> void`: kiểm, điền, và ghi lỗi vào `result`; không đụng file. `load_from_file` (nếu còn) chỉ là lớp mỏng gọi `DataLoader` rồi `configure`. Nhờ đó kiểm thử bằng từ điển viết tay.
5. **Hai mức nghiêm trọng, chính sách lai.**
   - **Lỗi (chết, chặn khởi động):** không đọc được file hoặc JSON hỏng; sai kiểu gốc; thiếu khoá bắt buộc; danh sách bắt buộc rỗng; mục trong danh sách thiếu `id` hoặc có giá trị sai nghĩa (ví dụ `growth_days` ≤0, `seconds` ≤0, số lượng ≤0); `id` trùng; tham chiếu tới id không tồn tại; điều kiện không thể đạt (khoá chết).
   - **Cảnh báo (không chặn):** màu sai định dạng (dùng màu mặc định); tên hiển thị rỗng (dùng `id`); giá âm (kẹp về 0, như mã hiện tại); khoá lạ không bắt đầu bằng `_` (để bắt lỗi gõ nhầm tên khoá). Cảnh báo ghi `push_warning` ra console, không hiện cho người chơi.
6. **Gom mọi lỗi, không dừng ở lỗi đầu.** `Main` gom kết quả của mọi file vào một `DataResult`. Nếu có lỗi, `Main` hiện lỗi qua quy tắc 9 của ADR-0002: liệt kê tối đa 10 lỗi (file, vị trí, lý do) rồi "và N lỗi khác"; `_initialised` giữ `false`.
7. **Kiểm chéo bằng `DataValidator`.** `Main` gọi `DataValidator.validate(...)` với các mô-đun đã nạp (tiêm vào), chỉ khi **mọi file đã qua kiểm riêng**; nếu có file lỗi, báo rõ "kiểm chéo bị bỏ qua vì [file] lỗi" thay vì im lặng. Các luật (mỗi luật là một lỗi chết):
   - Mùa trong `crops.json` có trong `time_config.json`.
   - Cây trong `require`, `unlock_crop` và `start_unlocked_crops` của `neighbors.json` có trong `crops.json`; `unlock_dish` có trong `dishes`.
   - Số lượng yêu cầu là số nguyên >0; `id` nhờ vả duy nhất trên toàn file. **"Số nguyên"** nghĩa là kiểu `TYPE_INT`, hoặc `TYPE_FLOAT` không có phần thập phân (JSON đưa mọi số về float); chuỗi và bool bị loại. Điều này áp cho mọi trường nguyên (`growth_days`, `unlock_at`, `min_requests`, số lượng).
   - `unlock_at` của mỗi mảnh làng nằm trong 1 tới tổng số nhờ vả; `min_requests` của các mức tăng dần, mức đầu là 0 và không vượt tổng số nhờ vả.
   - **Chỉ áp dụng khi trường `min_level` tồn tại** (`neighbors.json` hiện chưa có; thêm cùng mốc mức làng 0/3/9): với mỗi mức L, số nhờ vả có `min_level` ≤ L phải ≥ mốc của mức L+1 (công thức trong GDD hàng xóm), để không khoá chết.
8. **`game_config.json` và `GameConfig`.** Giá trị gameplay hiện viết cứng (tốc độ nhân vật 360, bán kính vẽ 18, kích thước lưới 5×4, kích thước ô, thời lượng thông báo) chuyển vào đây, **giữ nguyên giá trị** để hành vi không đổi. `GameConfig` có getter có kiểu; khoá thiếu là lỗi chết (không có giá trị mặc định ngầm trong mã). Hằng số bố cục theo điểm ảnh (vị trí quầy, hàng xóm...) chưa chuyển ở đây; để cho ADR hiển thị điện thoại và ADR giao diện quyết.
9. **Tài liệu schema ngay trong file.** Mỗi file giữ khoá `_schema` (mô tả khoá); khoá bắt đầu bằng `_` luôn được bỏ qua. Chưa thêm `schema_version`; thêm khi có thay đổi schema đầu tiên không tương thích.
10. **Kiểm thử.** Mỗi mô-đun dữ liệu có bài kiểm trong `tests/unit/data/` với từ điển viết tay (hợp lệ và từng loại lỗi). Một bài kiểm tích hợp nạp **file thật** dưới `assets/data/` và chạy `DataValidator`; nó phải đạt, nên CI bảo vệ nội dung.

### Architecture Diagram
```
assets/data/*.json
   │  DataLoader.read_json(path)  ── lỗi: tên file, dòng, lý do
   ▼
 DataResult(data, errors, warnings)
   │  mỗi mô-đun: configure(data, result)   (kiểm riêng, thuần, không đụng file)
   ▼
 CropDatabase · DayClock · NeighborBook · VillageProgress · GameConfig
   │  tất cả file đạt kiểm riêng?  ── không ──▶ báo "kiểm chéo bỏ qua vì ..."
   ▼ có
 DataValidator.validate(các mô-đun đã nạp)   (mùa, id, số lượng, mảnh làng, khoá chết)
   │
   ├─ có lỗi ──▶ Main hiện lỗi (ADR-0002 quy tắc 9), _initialised = false
   └─ sạch    ──▶ tiếp tục _wire() và _load_saved_game()
```

### Key Interfaces
```gdscript
class_name DataResult extends RefCounted
var data: Dictionary = {}
var errors: Array[String] = []
var warnings: Array[String] = []
func ok() -> bool                                   # errors.is_empty()
func add_error(where: String, message: String) -> void
func add_warning(where: String, message: String) -> void

class_name DataLoader extends RefCounted
static func read_json(path: String) -> DataResult   # data = JSON gốc (Dictionary); errors có file, dòng, lý do

# Mỗi mô-đun dữ liệu (CropDatabase, DayClock, NeighborBook, VillageProgress, GameConfig)
func configure(data: Dictionary, result: DataResult) -> void   # kiểm, điền, ghi lỗi vào result

class_name DataValidator extends RefCounted
func validate(crops: CropDatabase, clock: DayClock, book: NeighborBook,
        village: VillageProgress, config: GameConfig) -> DataResult
```

### Implementation Guidelines
- Code **must** đọc JSON chỉ qua `DataLoader.read_json`; **must never** gọi `JSON.parse_string` cho file dữ liệu (không có dòng và lý do lỗi).
- Mô-đun dữ liệu **must** tách `configure(data, result)` khỏi việc đọc file và **must never** gọi `push_error` rồi bỏ qua mục sai mà không ghi vào `result`.
- Mọi lỗi cấu trúc và tham chiếu **must** là lỗi chết; **must never** để game khởi động thiếu nội dung vì một mục bị bỏ qua im lặng.
- `Main` **must** gom lỗi của mọi file trước khi hiện, và **must** nói rõ khi kiểm chéo bị bỏ qua.
- Giá trị gameplay **must** đọc từ dữ liệu; **must never** thêm hằng số gameplay cứng mới trong mã.
- Mọi khoá dữ liệu mới **must** có mô tả trong `_schema` và có bài kiểm cho trường hợp thiếu và sai kiểu.
- Khoá lạ không bắt đầu bằng `_` **must** sinh cảnh báo.
- Trường nguyên **must** được kiểm bằng `typeof` và tính nguyên (xem quy tắc 7); **must never** dựa vào `int()` ép kiểu ngầm (`int(2.7)` thành 2, `int("abc")` thành 0).
- Mảng có kiểu (`Array[String]`) **must** được dựng bằng cách thêm từng phần tử sau khi kiểm kiểu; **must never** gán thẳng mảng đã parse vào biến có kiểu, và **must never** gọi `str()` mù quáng lên giá trị không phải chuỗi.
- Màu **must** có kiểm hợp lệ tường minh (không dựa vào giá trị mặc định âm thầm của `Color.from_string`), và chấp nhận màu có kênh alpha (`#rrggbbaa`); cách kiểm cụ thể (ví dụ `Color.html_is_valid`) **must** được xác minh trên 4.7 khi cài.
- `DataLoader` **must** bỏ ký tự BOM UTF-8 đầu file nếu có và ghi cảnh báo.
- **Giới hạn đã biết:** khoá trùng trong cùng một đối tượng JSON bị ghi đè âm thầm (khoá cuối thắng) và bộ nạp không phát hiện được; lớp lỗi này chỉ bắt được khi review nội dung.
- Thêm file dữ liệu mới **must** đi qua `DataLoader`, thêm vào `DataPaths` và vào `DataValidator` nếu có tham chiếu chéo.

## Alternatives Considered

### Alternative 1: Giữ bộ nạp riêng, thêm kiểm từng chỗ
- **Description**: Không thêm `DataLoader` hay `DataValidator`; mỗi mô-đun tự thêm kiểm.
- **Pros**: Ít mã mới nhất.
- **Cons**: Giữ bốn bản sao; không có chỗ nào kiểm chéo; mỗi file mới lặp lại.
- **Rejection Reason**: Không giải quyết khoảng trống kiểm chéo và nhân đôi công sức cho bảy hệ thống sắp thêm.

### Alternative 2: Chuyển dữ liệu sang `Resource` (.tres)
- **Description**: Lớp `Resource` tuỳ chỉnh với trường có kiểu, sửa trong trình soạn thảo.
- **Pros**: Có kiểu, hỗ trợ trình soạn thảo, nạp bằng `load()`.
- **Cons**: Đổi định dạng nội dung đã chốt (JSON); khó sửa bằng tay và bằng agent; phải làm lại dữ liệu hiện có.
- **Rejection Reason**: JSON đã được chốt trong GDD và ADR-0001 vì dễ sửa và dễ đọc khi gỡ lỗi; lợi ích kiểu có thể lấy bằng `configure` và `DataValidator`.

### Alternative 3: Chính sách lỏng (như hiện tại: bỏ qua mục sai, đi tiếp)
- **Description**: Lỗi chỉ ra console; game chạy với phần dữ liệu còn lại.
- **Pros**: Game ít khi bị chặn khởi động.
- **Cons**: Một nhờ vả đòi cây không tồn tại làm game kẹt mà không ai biết; người sửa dữ liệu không thấy lỗi.
- **Rejection Reason**: Trái nguyên tắc "thất bại thì phải thấy" và `silent_startup_failure`.

### Alternative 4: Chính sách nghiêm (mọi vấn đề đều chết)
- **Description**: Ngay cả màu sai hay tên rỗng cũng chặn khởi động.
- **Pros**: Đơn giản; không có trạng thái "đi tiếp có lỗi".
- **Cons**: Một lỗi thẩm mỹ nhỏ trong nội dung chặn cả game.
- **Rejection Reason**: Chính sách lai: chỉ chặn khi lỗi làm game sai hoặc kẹt; lỗi thẩm mỹ chỉ cảnh báo.

## Consequences

### Positive
- Dữ liệu sai bị bắt ngay khi khởi động, không còn kẹt âm thầm giữa chừng.
- Lỗi JSON có dòng và lý do; lỗi chéo nêu đúng khoá nào tham chiếu cái gì.
- Một đường nạp duy nhất cho mọi file mới (câu cá, nấu ăn, cốt truyện).
- Kiểm thử không cần file thật; CI chặn nội dung sai.
- Giá trị gameplay chỉnh được bằng dữ liệu.

### Negative
- Thêm bốn lớp mới (`DataResult`, `DataLoader`, `DataValidator`, `GameConfig`) và phải sửa bốn bộ nạp hiện có.
- Chính sách lai chỉ có hai mức; ranh giới "lỗi nhẹ" cần được bảo trì khi có kiểu dữ liệu mới.
- Một lỗi sai trong nội dung chặn khởi động, nên người sửa dữ liệu phải sửa ngay.

## Risks
- **Bản xuất Android có thể không đóng gói file `.json`** (tài liệu engine không nêu; theo trí nhớ chưa xác minh thì bộ lọc xuất mặc định chỉ lấy resource). Giảm nhẹ: đặt "Filters to export non-resource files" cho `assets/data/*` khi tạo preset xuất, và kiểm trên bản xuất thật đầu tiên (bước trong Migration Plan).
- **Bộ kiểm chéo thiếu luật** vì nội dung mới có kiểu tham chiếu mới. Giảm nhẹ: quy tắc "mọi file mới đi qua `DataValidator`" và bài kiểm tích hợp trên file thật.
- **Phát hiện lỗi sẵn có trong dữ liệu hiện tại khi bật kiểm chéo** có thể chặn game ngay. Giảm nhẹ: chạy bài kiểm tích hợp trước khi bật chặn; sửa dữ liệu trong cùng thay đổi.
- **`DataLoader` dùng `static func`** nên không tiêm thay thế được trong kiểm thử. Giảm nhẹ: mọi logic nằm ở `configure` (nhận từ điển), `DataLoader` chỉ là lớp đọc mỏng.
- **Ép kiểu số ngầm từ JSON** (mọi số là float; `int()` cắt cụt). Giảm nhẹ: quy tắc 7 và hướng dẫn cài đặt về kiểm nguyên.
- **Kiểm bởi chuyên gia Godot (2026-10-27):** không có vấn đề chặn; mười ghi chú nhỏ đã được đưa vào quy tắc 3 và 7, Implementation Guidelines, Risks, Engine Compatibility và Migration Plan. Các khẳng định về hành vi xuất `.json`, `parse_string`, `static func` và `Color.from_string` là từ trí nhớ, chưa xác minh trong tài liệu engine.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| time-system.md | TR-time-002: cấu hình từ `time_config.json`, lỗi thì nạp thất bại an toàn | Quy tắc 2 đến 6: `DayClock.configure`, lỗi chết hiển thị cho người chơi |
| farming-system.md | TR-farm-002: dữ liệu cây từ `crops.json` qua `CropDatabase`, có kiểm tra | Quy tắc 4, 5, 7: `CropDatabase.configure`, mùa phải có trong `time_config.json` |
| market-system.md | TR-market-002: giá từ `crops.json`, không hardcode | Quy tắc 1 và 5 (giá âm kẹp về 0, cảnh báo) |
| market-system.md | TR-market-005: giá hạt và giá theo mùa từ dữ liệu (ý định) | Quy tắc 8 và 9: mở rộng schema qua `_schema`, kiểm bằng `configure` |
| neighbors-system.md | TR-neighbors-001: `neighbors.json` có kiểm tra (số lượng >0, vật phẩm tồn tại, không khoá chết) | Quy tắc 5 và 7: các luật của `DataValidator` |
| village-restoration.md | TR-village-001: mảnh và mức từ JSON, có kiểm tra | Quy tắc 5 và 7: `unlock_at`, `min_requests` được kiểm |
| player-system.md | TR-player-002: tốc độ đi đọc từ dữ liệu | Quy tắc 8: `game_config.json` |

## Performance Implications
- **CPU**: Đọc và kiểm khoảng 16 KB JSON một lần khi khởi động; chưa đo, kỳ vọng không đáng kể.
- **Memory**: Không đổi (dữ liệu đã nằm trong bộ nhớ); `DataResult` bỏ sau khi khởi động.
- **Load Time**: Thêm bước kiểm chéo O(số mục); chưa đo trên máy thật.
- **Network**: Không áp dụng.

## Migration Plan
1. Thêm `DataResult`, `DataLoader`, `DataPaths`, `DataValidator`, `GameConfig`.
2. Sửa `CropDatabase`, `DayClock`, `NeighborBook`, `VillageProgress`: thêm `configure(data, result)`, giữ `load_from_file` là lớp mỏng, thay mọi `push_error`-rồi-bỏ-qua bằng lỗi trong `result`. `DayClock.configure` hiện trả `bool`; đổi sang `void` ghi vào `result` là thay đổi phá vỡ chữ ký, nhưng đã kiểm: không nơi nào ngoài chính `DayClock` gọi `configure`, và chưa có bài kiểm nào dùng nó.
3. Chuyển hằng số gameplay sang `game_config.json` với giá trị giữ nguyên (ví dụ `Player.SPEED` 360 và `Player.RADIUS` 18 trong `player.gd`, kích thước lưới và ô); kiểm game chạy giống cũ.
4. Khi cài ADR-0002, `_ready()` (hiện nạp bốn file bằng bốn lần gọi `load_from_file`, mỗi lần `push_error` rồi `return`) tách thành `_build()`. Trong `_build()`, gom `DataResult` của mọi file, hiện lỗi theo ADR-0002 quy tắc 9, gọi `DataValidator`. Cờ `_initialised` đã có sẵn (`main.gd`, đặt `true` ở cuối `_ready()`).
5. Viết `tests/unit/data/` và bài kiểm tích hợp trên file thật.
6. Chạy `DataValidator` trên dữ liệu hiện có, sửa lỗi nội dung nếu phát hiện, rồi mới bật chặn khởi động.
7. Cập nhật GDD (mục Edge Cases và nạp dữ liệu) cho khớp chính sách mới.
8. Khi tạo `export_presets.cfg`: đặt "Filters to export non-resource files" cho `assets/data/*` (hoặc `*.json`), rồi kiểm bản xuất Android đầu tiên mở được cả năm file dữ liệu.

## Validation Criteria
- Xoá hoặc làm hỏng một file dữ liệu: game hiện lỗi nêu tên file, dòng và lý do, không còn màn hình trống.
- Một nhờ vả đòi cây không tồn tại: `DataValidator` báo lỗi nêu đúng id nhờ vả và id cây.
- Bài kiểm tích hợp nạp `assets/data/*.json` thật và `DataValidator` trả về `ok()`, chạy trong CI.
- Không còn `JSON.parse_string` cho file dữ liệu trong `src/`.
- Không còn hằng số gameplay cứng trong `src/` ngoài bố cục điểm ảnh.
- Bản xuất Android đầu tiên mở được toàn bộ file dữ liệu.

## Related
- ADR-0002 (gốc ghép nối): lỗi khởi động, `Main._build()`.
- ADR-0001: định dạng lưu cũng dùng JSON nhưng có bộ đọc riêng với dòng và lý do lỗi.
- `docs/architecture/architecture.md`: Foundation layer, Data Flow.
- `design/gdd/time-system.md`, `farming-system.md`, `market-system.md`, `neighbors-system.md`, `village-restoration.md`, `player-system.md`.
