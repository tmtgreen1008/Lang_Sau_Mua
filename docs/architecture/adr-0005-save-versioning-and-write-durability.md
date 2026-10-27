# ADR-0005: Chính sách phiên bản và độ bền ghi bản lưu

## Status
Proposed

## Date
2026-10-27

## Last Verified
2026-10-27

## Decision Makers
To Truong (người làm game), cùng phiên `/architecture-decision`.

## Summary
Bản lưu hiện chỉ đọc được đúng một phiên bản, mọi lỗi (kể cả đọc thoáng qua và bản lưu của game mới hơn) đều bị đổi tên thành `.corrupt.json` rồi game bắt đầu mới và lưu đè, không có bản sao lưu bền, và không dùng `.tmp` để phục hồi. Quyết định: nâng cấp từng bước qua mô-đun `SaveMigrations` riêng có file lưu mẫu đóng băng, không bao giờ đổi tên hay ghi đè bản lưu không đọc được hoặc mới hơn, đọc theo thứ tự `.tmp`, file chính, `.bak`, và ghi có đọc lại kiểm tra kèm một `.bak` bền là bản tốt trước đó. ADR này sửa đổi các phần phiên bản và ghi an toàn của ADR-0001.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH theo `VERSION.md`; riêng `FileAccess`, `DirAccess`, `JSON` không có thay đổi nào được ghi cho 4.5 đến 4.7 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` (không có mô-đun tham chiếu cho Core) |
| **Post-Cutoff APIs Used** | Không có. `FileAccess.store_*` trả `bool` từ 4.4 (đã xác minh trong `breaking-changes.md`) |
| **Verification Required** | Tất cả **NOT SOURCEABLE**, kiểm trên Android và Windows thật: (1) `DirAccess.rename_absolute` có ghi đè file đích nguyên tử không, từng nền tảng; (2) `FileAccess.flush()` có tương đương `fsync` không, có API ghi bền hơn không; (3) hành vi khi hết dung lượng giữa lúc ghi (`store_string` trả `false`?); (4) `FileAccess.get_open_error()` có phân biệt được lỗi tạm thời (khoá file, quyền) với file không tồn tại; (5) ngữ nghĩa của `FileAccess.get_file_as_string` khi đọc lỗi (trả chuỗi rỗng và đặt mã lỗi?) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (đã Accepted), ADR-0002 (`Main` điều phối tải và hiện lỗi) |
| **Enables** | ADR `Inventory` và mô hình vật phẩm (thêm phần mới nên cần nâng phiên bản), ADR nơi lưu thiết lập trợ năng, mọi hệ thống mới thêm phần vào bản lưu |
| **Blocks** | Story chuyển túi đồ sang `Inventory` (cần migrate v1 lên v2); story nút "Thử lại" và "Game mới" khi bản lưu không đọc được |
| **Ordering Note** | Sửa đổi ADR-0001 (các mục "Ghi an toàn" và "Đọc nghiêm ngặt"); ADR-0001 giữ trạng thái Accepted và nên thêm một dòng "sửa đổi bởi ADR-0005" vào Version History khi ADR này được Accepted. Khi nào lưu (sự kiện vòng đời, bỏ qua khi không đổi) thuộc ADR-0004 |

## Context

### Problem Statement
Đọc từ `save_game.gd`, `main.gd` và danh sách việc còn lại của ADR-0001:
- `FORMAT_VERSION = 1` và mọi phiên bản khác bị `_reject`: bản lưu của game **mới hơn** bị đổi tên thành `.corrupt.json` rồi game bắt đầu mới. Chưa có đường nâng cấp; thêm một phần vào bản lưu (như `Inventory`) làm mọi bản lưu v1 không đọc được.
- `_reject` xử lý **mọi** lỗi như nhau: JSON hỏng, sai phiên bản, thiếu phần, và cả đọc lỗi tạm thời đều đổi tên file tốt thành `.corrupt.json` (ghi đè bản corrupt trước). `Main` sau đó bắt đầu game mới và tự lưu đè lên `savegame.json`.
- `.bak` chỉ tồn tại giữa hai lần đổi tên và bị xoá ngay khi thành công (`save_game.gd:118`): không còn bản tốt trước đó để quay về.
- `.tmp` không bao giờ được dùng để phục hồi: bị ngắt sau khi ghi đầy đủ `.tmp` mà trước khi đổi tên là mất bản mới.
- `flush()` không phải `fsync` (ghi nhận của chuyên gia engine, từ trí nhớ): mất điện hệ điều hành có thể để lại file rỗng, rồi bị coi là hỏng và đổi tên.
- Sau khi ghi không có bước đọc lại để bắt ghi lỗi một phần.
- `has_save()` có tác dụng phụ ngầm: đổi tên `.bak` thành file chính.

### Constraints
- `SaveGame` không biết game (ADR-0001); chỉ lưu `Dictionary`.
- Game chưa phát hành; hiện chỉ có bản lưu của chính người làm. Người chơi sau này sẽ dùng nhiều phiên bản game liên tiếp.
- Một khe lưu, chỉ trên máy; mọi thứ chạy trên luồng chính.
- Quy tắc ADR-0002: `Main` điều phối; lỗi nghiêm trọng phải hiện ra (`silent_startup_failure`); mô-đun không gọi nhau.
- Hành vi ghi file trên Android chưa kiểm được trong phiên làm việc này.

### Requirements
- TR-time-005, TR-farm-004, TR-market-001, TR-neighbors-002, TR-village-002: trạng thái lưu và khôi phục đúng; ADR này giữ chúng đúng **qua các phiên bản định dạng và qua các kiểu lỗi**.
- Danh sách việc còn lại của ADR-0001: chính sách phiên bản, phục hồi `.tmp`, kiểm tra mở file trước khi coi là hỏng.

## Decision

### Phiên bản và nâng cấp
1. **Một phiên bản toàn cục.** Vỏ `{version, data}` giữ một số nguyên `version`; `FORMAT_VERSION` là phiên bản hiện tại. Không có phiên bản theo từng phần.
2. **Khi nào phải nâng.** Bắt buộc nâng khi thay đổi hình dạng mà mã cũ không đọc đúng: thêm, xoá, đổi tên hay đổi kiểu một phần hoặc một khoá bắt buộc, hoặc đổi ý nghĩa giá trị. Không cần nâng khi chỉ thêm khoá tuỳ chọn mà `from_dict` chịu được khi thiếu.
3. **`SaveMigrations` (mô-đun mới, Foundation).** Chứa các hàm thuần `migrate_vN_to_vN+1(data: Dictionary) -> Dictionary` (không đụng file, không phát tín hiệu), bảng `MIGRATIONS` liên tiếp từ 1 tới `FORMAT_VERSION - 1`, và `upgrade(root: Dictionary) -> UpgradeResult` chạy từng bước trên **bản sao** và đặt `version` mới sau mỗi bước. Một bước lỗi thì cả lần nâng thất bại, không áp một phần. `REQUIRED_SECTIONS` của phiên bản hiện tại chuyển về đây và được kiểm **sau** khi nâng.
4. **`SaveGame` vẫn không biết game.** `SaveGame` chỉ biết định dạng vỏ và `FORMAT_VERSION`. `load_state(accept: Callable)` thử lần lượt từng ứng viên và, với mỗi ứng viên hợp lệ ở mức vỏ, gọi `accept(root: Dictionary) -> String` do `Main` tiêm vào (hàm thành viên, không phải lambda): hàm này chạy `SaveMigrations.upgrade` và `validate_sections` và trả chuỗi rỗng nếu dùng được, hoặc lý do nếu không. Nhờ vậy việc rơi xuống `.bak` khi một ứng viên thiếu phần vẫn hoạt động mà `SaveGame` không biết tên phần nào.
5. **Bản sao trước khi nâng.** Khi `Main` thấy ứng viên được chọn có phiên bản cũ hơn hiện tại, `Main` gọi `SaveGame.backup_loaded_file(version)`: **sao chép** (đọc rồi ghi, không đổi tên) đúng file đã được tải (`LoadResult.source`) thành `savegame.v<N>.bak`; nếu file đó đã tồn tại thì giữ nguyên, không ghi đè. Việc này làm trước khi game lưu bản đã nâng.
6. **Bản lưu mới hơn game (`version` > `FORMAT_VERSION`).** Trạng thái `NEWER_VERSION`: **không đọc, không đổi tên, không xoá, không tự lưu đè.** `Main` hiện thông báo quan trọng "bản lưu từ phiên bản game mới hơn" và **tắt tự lưu** cho tới khi người chơi chủ động chọn "game mới" với xác nhận rõ; khi đó file cũ được giữ thành `savegame.v<N>.bak`.
7. **File lưu mẫu đóng băng.** Mỗi phiên bản định dạng đã từng được dùng có một file `tests/fixtures/saves/v<N>.json` không bao giờ bị sửa. Một bài kiểm chạy trong CI nâng mọi fixture tới phiên bản hiện tại và tải được. Một lần nâng `FORMAT_VERSION` mà thiếu hàm migrate và fixture thì bài kiểm đỏ.
8. **Bắt buộc từ bây giờ.** Hàm migrate v1 lên v2 viết ngay khi thêm `Inventory`; v1 hiện có (bản lưu của người làm game) được đóng băng thành `v1.json`.

### Đọc và xử lý lỗi
9. **Trạng thái kết quả (`LoadResult.status`).** `OK`; `NO_SAVE`; `NEWER_VERSION`; `UNREADABLE` (không mở hoặc không đọc được: lỗi tạm thời, **không đổi tên file**, thử lại một lần); `CORRUPT` (đọc được nhưng nội dung hỏng: JSON sai, vỏ sai, `version` không phải số nguyên không âm, `accept` từ chối); `RECOVERED` (ứng viên được chọn không phải file chính). `version` đến từ JSON dưới dạng float: phải là số nguyên không âm (kiểm tính nguyên rồi mới `int()`); chuỗi, bool, số có phần thập phân là `CORRUPT`; mọi hàm migrate phải `int()` các số nguyên lồng bên trong mà chúng sao chép.
10. **Thứ tự thử: `.tmp`, file chính, `.bak`, và quy tắc dừng.** Mỗi ứng viên được đánh giá: mở và đọc được, JSON hợp lệ, vỏ đúng, `version` hợp lệ, `accept`. Lý do `.tmp` đứng đầu: một `.tmp` hợp lệ là bản ghi đầy đủ bị ngắt trước khi đổi tên, nên không bao giờ cũ hơn file chính (xem quy tắc 19).
    - **`CORRUPT` thì thử ứng viên kế tiếp.** Riêng một `.tmp` `CORRUPT` luôn bị **bỏ qua im lặng và không được tính là bản lưu hỏng** (nó là bản ghi dở của lần lưu bị ngắt); nếu chỉ còn mỗi `.tmp` hỏng thì kết quả là `NO_SAVE`.
    - **`NEWER_VERSION` hoặc `UNREADABLE` thì DỪNG, không rơi xuống ứng viên cũ hơn.** `load_state` trả ngay trạng thái đó và `SaveGame` chặn ghi (quy tắc 18). Rơi xuống một `.bak` cũ khi file chính chỉ tạm thời đọc lỗi hoặc thuộc phiên bản mới hơn sẽ để lần lưu kế tiếp xoay vòng hay đè mất file tốt.
    - Ứng viên đầu tiên đạt mà không phải file chính cho kết quả `RECOVERED`.
11. **`RECOVERED`:** `Main` hiện thông báo quan trọng "đã khôi phục từ bản lưu trước" (kênh thông báo xếp hàng); lần lưu bình thường kế tiếp đưa bản khôi phục về file chính.
12. **Không ứng viên nào dùng được: không tự lưu đè.** Khi `load_state` trả `NEWER_VERSION`, `UNREADABLE`, hoặc `CORRUPT` (mọi ứng viên không phải `.tmp` đều hỏng), `Main` **tắt tự lưu**, giữ nguyên mọi file, và hiện lỗi qua ADR-0002 quy tắc 9. Người chơi chọn "Thử lại" hoặc "Bắt đầu game mới" (giao diện thuộc ADR giao diện; ADR này định nghĩa trạng thái và hợp đồng). Chọn game mới gọi `SaveGame.archive_for_new_game()`:
    - File nào đang tồn tại trong ba file (chính, `.tmp`, `.bak`) được **đổi tên** thành bộ lưu trữ có số thứ tự `<n>`: `savegame.corrupt.<n>.json`, `savegame.corrupt.<n>.tmp.json`, `savegame.corrupt.<n>.bak.json`. `<n>` là số lớn nhất đã có trong thư mục cộng 1 (quét bằng `DirAccess.get_files_at`).
    - Giữ tối đa **3 bộ** `corrupt` gần nhất; xoá bộ cũ nhất. File `savegame.v<N>.bak` (quy tắc 5 và 6) **không bao giờ bị tỉa**, vì có thể là bản lưu của game mới hơn; nếu đã có `v<N>.bak`, thêm hậu tố đếm.
    - Sau đó tự lưu được bật lại.
13. **Bỏ `_reject` và tác dụng phụ của `has_save()`.** Không có thao tác huỷ hoại (đổi tên, xoá) nào xảy ra khi tải; mọi đổi tên chỉ xảy ra khi người chơi chọn game mới. `has_save()` chỉ trả lời "có file nào không".

### Độ bền ghi
14. **Quy trình ghi.** (a) Mở `savegame.tmp`, `store_string`, kiểm giá trị trả về và `get_error()`, `flush()`, đóng. (b) **Đọc lại `.tmp` và so với đúng chuỗi vừa ghi** (so bằng nhau từng ký tự). So với chuỗi đã ghi thì không cần biết game, và `save({})` vẫn qua. Việc đọc lại bắt ghi lỗi một phần và hết dung lượng; nó **không** chứng minh dữ liệu đã xuống đĩa khi mất điện (có thể đọc từ bộ nhớ đệm). Nếu (b) thất bại thì xoá `.tmp` và `save` trả `false`. (c) Nếu file chính tồn tại và hợp lệ, xoay vòng nó thành `savegame.bak` (xoá `.bak` cũ trước nếu việc đổi tên không ghi đè được). (d) Đổi tên `.tmp` thành file chính. (e) Nếu (d) thất bại, đưa `.bak` về file chính.
15. **`.bak` bền.** `savegame.bak` là bản lưu tốt ngay trước đó và **không bị xoá sau khi thành công**; đây là nơi quay về khi file chính hỏng hoặc rỗng sau mất điện.
16. **Giới hạn đã biết.** Godot không có API `fsync` (từ trí nhớ, chưa xác minh): ADR chấp nhận rằng mất điện hệ điều hành có thể làm mất bản ghi mới nhất; `.bak` bảo đảm tối đa mất một lần tự lưu, không mất cả tiến độ.
17. **Lưu thất bại phải thấy.** `Main` đếm số lần `save_game()` thất bại liên tiếp; từ lần thứ hai, hiện thông báo quan trọng "không lưu được" (ví dụ hết dung lượng), và dừng thông báo lặp lại sau khi lưu thành công.
18. **`SaveGame` tự chặn ghi, không chỉ dựa vào cờ của `Main`.** `SaveGame` giữ cờ nội bộ `_write_blocked`, đặt khi `load_state` trả `NEWER_VERSION`, `UNREADABLE` hoặc `CORRUPT`, và chỉ xoá khi `archive_for_new_game()` chạy hoặc khi một lần tải sau đó trả `OK` hay `RECOVERED`. Khi bị chặn, `save()` trả `false` và không động tới file nào. Thêm một lớp bảo vệ độc lập với cờ: trước khi xoay vòng, `save()` đọc `version` của file chính và **từ chối** nếu nó lớn hơn `FORMAT_VERSION` hoặc không đọc được dù file tồn tại. Lý do: một cờ chỉ nằm trong `Main` là hàng rào yếu, và mọi đường gọi `save()` (kể cả sau này) phải an toàn.
19. **Bất biến của `.tmp`.** Một `.tmp` hợp lệ không bao giờ cũ hơn file chính, vì mọi nhánh lỗi hoặc xoá `.tmp` (khi (b) hỏng hay ghi hỏng) hoặc để lại một bản mới hơn: nếu (c) không xoay vòng được thì `save` huỷ bỏ, giữ file chính nguyên vẹn và để `.tmp` hợp lệ lại, rồi trả `false`; nếu (d) thất bại và (e) khôi phục `.bak` về file chính thì `.tmp` vẫn còn và mới hơn, rồi trả `false`. Lần lưu kế tiếp ghi đè `.tmp`.

### Architecture Diagram
```
LƯU    Main.save_game ──▶ SaveGame.save(state)
         (a) ghi .tmp ──▶ (b) đọc lại + kiểm ──▶ (c) file chính → .bak (xoay vòng)
                                                  ▶ (d) .tmp → file chính ──(lỗi)▶ (e) .bak → file chính

TẢI    SaveGame.load_state ──▶ LoadResult {status, version, data}
         thử: .tmp ▶ file chính ▶ .bak  (mỗi cái: mở, đọc, JSON, vỏ)
       Main ──▶ SaveMigrations.upgrade(root)   (từng bước trên bản sao; giữ savegame.v<N>.bak)
            ──▶ kiểm phần theo FORMAT_VERSION ──▶ from_dict ×N ──▶ _refresh_all

       status  OK / NO_SAVE ──▶ tiếp tục
               RECOVERED    ──▶ thông báo "đã khôi phục"
               NEWER_VERSION / UNREADABLE / CORRUPT (cả ba lỗi) ──▶ TẮT tự lưu, giữ file,
                                  hiện lỗi; người chơi chọn "Thử lại" hoặc "Game mới"
```

### Key Interfaces
```gdscript
class_name LoadResult extends RefCounted
enum Status { OK, NO_SAVE, NEWER_VERSION, UNREADABLE, CORRUPT, RECOVERED }
var status: Status
var version: int                 # phiên bản thấy trong file
var data: Dictionary             # "data" thô, chưa nâng cấp
var source: String               # "main" | "tmp" | "bak"
var message: String              # lý do, cho nhật ký và giao diện

# SaveGame (vẫn không biết game)
func save(state: Dictionary) -> bool            # quy trình (a) đến (e); false khi _write_blocked hoặc file chính mới hơn/không đọc được
func load_state(accept: Callable = Callable()) -> LoadResult   # không đổi tên, không xoá khi tải; accept(root) -> String ("" nếu dùng được)
func has_save() -> bool                         # chỉ kiểm có file nào; không tác dụng phụ
func backup_loaded_file(version: int) -> bool   # SAO CHÉP file đã tải thành savegame.v<N>.bak; không ghi đè nếu đã có
func archive_for_new_game() -> void             # đổi tên các file thành bộ savegame.corrupt.<n>.* (tối đa 3 bộ) hoặc savegame.v<N>.bak; chỉ khi người chơi chọn; bật lại ghi

# SaveMigrations (mô-đun mới)
const MIGRATIONS: Array[Callable] = [migrate_v1_to_v2, ...]   # thứ tự liên tiếp
func upgrade(root: Dictionary) -> UpgradeResult # trên bản sao; thất bại thì không áp gì
func validate_sections(data: Dictionary) -> Array[String]     # REQUIRED_SECTIONS của FORMAT_VERSION
```

### Implementation Guidelines
- `SaveGame` **must never** đổi tên hay xoá file lưu khi tải; mọi thao tác huỷ hoại **must** chỉ xảy ra sau lựa chọn rõ của người chơi.
- Bản lưu có `version` mới hơn `FORMAT_VERSION` **must never** bị đọc, đổi tên, xoá hay ghi đè.
- Lỗi mở hoặc đọc tạm thời (`UNREADABLE`) **must never** bị coi là nội dung hỏng và **must never** dẫn tới đổi tên file.
- Khi không đọc được bản lưu nào, game **must** tắt tự lưu và **must never** tự bắt đầu game mới rồi lưu đè.
- Mọi thay đổi hình dạng bản lưu **must** đi kèm nâng `FORMAT_VERSION`, một hàm `migrate_vN_to_vN+1` thuần, một file `tests/fixtures/saves/v<N>.json` mới, và bài kiểm nâng cấp.
- File trong `tests/fixtures/saves/` **must never** bị sửa sau khi tạo.
- Hàm migrate **must** thuần (không file, không tín hiệu) và chạy trên bản sao.
- Ghi **must** đọc lại `.tmp` và so với đúng chuỗi đã ghi trước khi xoay vòng file chính; **must never** kiểm tên phần trong `SaveGame`.
- Khi đánh giá ứng viên, `NEWER_VERSION` và `UNREADABLE` **must** dừng việc thử, **must never** rơi xuống ứng viên cũ hơn.
- `save()` **must** từ chối khi bị chặn ghi hoặc khi file chính có `version` lớn hơn `FORMAT_VERSION` hay không đọc được; **must never** dựa riêng vào cờ của `Main`.
- Một `.tmp` hỏng **must** bị bỏ qua và **must never** được tính là bản lưu hỏng.
- `version` đọc từ JSON **must** được kiểm là số nguyên không âm trước khi `int()`.
- `archive_for_new_game` **must never** tỉa `savegame.v<N>.bak`.
- `savegame.bak` **must** giữ bản tốt trước đó và **must never** bị xoá sau một lần lưu thành công.
- `Main` **must** hiện lỗi khi lưu thất bại hai lần liền; **must never** bỏ qua im lặng.

## Alternatives Considered

### Alternative 1: Không nâng cấp, lệch phiên bản thì bắt đầu mới
- **Description**: Giữ hành vi hiện tại; chỉ đổi tên bản cũ để không mất file.
- **Pros**: Ít mã nhất; không cần bảo trì migrate hay fixture.
- **Cons**: Mỗi lần thêm hệ thống (câu cá, nấu ăn, `Inventory`) làm mọi người chơi mất tiến độ, trái trụ cột "hồi sinh nhìn thấy được" (làng dựng bao lâu mất bấy nhiêu); không giải quyết bản lưu mới hơn.
- **Rejection Reason**: Cái giá với người chơi lớn hơn nhiều so với chi phí viết một hàm migrate mỗi lần nâng.

### Alternative 2: Mỗi mô-đun tự đọc mọi hình dạng cũ trong `from_dict`
- **Description**: `from_dict` của từng mô-đun chấp nhận mọi phiên bản.
- **Pros**: Không cần mô-đun nâng trung tâm.
- **Cons**: Mã tương thích sống mãi trong từng mô-đun; không có thứ tự và không có chỗ kiểm một lần; việc đổi cấu trúc xuyên mô-đun (như tách túi đồ ra khỏi ruộng) không đặt ở mô-đun nào.
- **Rejection Reason**: Thay đổi xuyên mô-đun cần một nơi nhìn thấy cả bản lưu; nâng tập trung và kiểm bằng fixture dễ bảo đảm hơn.

### Alternative 3: Phiên bản theo từng phần (`farm`, `clock`...)
- **Description**: Mỗi phần có phiên bản riêng.
- **Pros**: Một phần đổi không buộc phần khác.
- **Cons**: Phải theo dõi tổ hợp phiên bản; thay đổi xuyên phần khó diễn tả; nhiều thứ hơn để lưu và kiểm.
- **Rejection Reason**: Một phiên bản toàn cục đủ cho một khe lưu một người; thêm phức tạp không đổi lấy lợi ích rõ.

### Alternative 4: Giữ chính sách "đọc lỗi thì đổi tên và bắt đầu mới"
- **Description**: Như hiện nay: `_reject` đổi tên và game tự bắt đầu mới.
- **Pros**: Không cần giao diện chọn; game luôn khởi động được.
- **Cons**: Một lỗi đọc thoáng qua mất bản lưu tốt; bản corrupt bị ghi đè lần sau; người chơi không biết chuyện gì xảy ra.
- **Rejection Reason**: Mất tiến độ im lặng là rủi ro lớn nhất của một game cozy; không được đánh đổi lấy sự tiện.

## Consequences

### Positive
- Thêm hệ thống mới (kể cả `Inventory`) không còn làm mất bản lưu hiện có.
- Bản lưu của game mới hơn, đọc lỗi tạm thời và nội dung hỏng không còn biến thành mất tiến độ im lặng.
- Mất điện hoặc bị ngắt giữa lúc ghi tối đa mất một lần tự lưu nhờ `.bak` bền và phục hồi `.tmp`.
- Nâng cấp có fixture đóng băng và bài kiểm trong CI nên lỗi migrate bị bắt sớm.
- `SaveGame` vẫn không biết game.

### Negative
- Thêm `SaveMigrations`, `LoadResult`, thư mục fixture và một bảng migrate phải bảo trì mãi mỗi lần nâng.
- Cần giao diện "Thử lại" và "Game mới" khi bản lưu không đọc được (thuộc ADR giao diện); cho tới khi có, trạng thái lỗi chỉ hiện thông báo và tắt tự lưu.
- Mỗi lần lưu ghi thêm một bước đọc lại và một lần đổi tên; chưa đo.
- `.bak` luôn là bản tự lưu ngay trước, nên có thể giống bản hỏng nếu lỗi nằm trong chính trạng thái game (không phải trong file).
- Bản chấp nhận: không `fsync` nên mất điện hệ điều hành vẫn có thể mất bản ghi mới nhất.

## Risks
- **Ngữ nghĩa `rename_absolute` ghi đè, `flush()` và hết dung lượng chưa xác minh** (NOT SOURCEABLE). Giảm nhẹ: xoá `.bak` cũ trước khi đổi tên, bước (e) khôi phục, đọc lại sau ghi; kiểm trên Android và Windows thật trước khi chấp nhận ADR.
- **Hàm migrate sai làm hỏng bản lưu đã nâng.** Giảm nhẹ: nâng trên bản sao, giữ `savegame.v<N>.bak`, fixture đóng băng và bài kiểm trong CI.
- **Quên nâng phiên bản khi đổi hình dạng.** Giảm nhẹ: quy tắc 2 và 7; rà soát mã khi mô-đun đổi `to_dict`.
- **Tắt tự lưu khi lỗi có thể bị bỏ sót** nếu thông báo không hiện. Giảm nhẹ: dùng thông báo quan trọng xếp hàng (ADR giao diện) và ADR-0002 quy tắc 9.
- **Thứ tự `.tmp` rồi chính rồi `.bak`** khác thứ tự "lưu, bak, tmp" bạn đã chọn trong phiên: ADR đặt `.tmp` trước vì `.tmp` hợp lệ luôn mới hơn. Cần bạn xác nhận.
- **`.bak` chỉ là lần tự lưu ngay trước đó**, nên không bảo vệ khỏi trạng thái game đã sai trước khi được lưu. ADR-0004 (bỏ qua lưu khi không đổi) giúp `.bak` không trở thành bản sao của file chính sau vài lần mất focus liên tiếp.
- **Sao lưu tự động của Android và `user://`.** Chưa quyết (ADR-0001 đã ghi là việc sau); theo trí nhớ `user://` trên Android là bộ nhớ riêng của ứng dụng và có thể thuộc sao lưu tự động của hệ điều hành.
- **Kiểm bởi chuyên gia Godot (2026-10-27):** có **hai vấn đề chặn** đã được sửa: (1) ứng viên `NEWER_VERSION` hoặc `UNREADABLE` rơi xuống `.bak` cũ rồi bị lưu đè (nay dừng, `SaveGame` tự chặn ghi: quy tắc 10, 18); (2) bước đọc lại kiểm "đủ phần" phá phân lớp (nay so với chuỗi đã ghi: quy tắc 14; kiểm phần qua `accept` được tiêm: quy tắc 4). Bảy ghi chú nhỏ đã vào quy tắc 5, 9, 10, 12, 19, Implementation Guidelines và Migration Plan. Mọi hành vi nền tảng của `rename_absolute`, `flush`, hết dung lượng, `get_open_error` là từ trí nhớ, chưa xác minh trong tài liệu engine.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| time-system.md | TR-time-005: lưu ngày, giai đoạn, giây đã trôi | Quy tắc 1 đến 8 và 14 đến 16: bản lưu của đồng hồ sống sót qua nâng phiên bản và qua lỗi ghi |
| farming-system.md | TR-farm-004: lưu ô và túi đồ; cây lạ thì về ô đã cuốc | Quy tắc 3 và 8: migrate v1 lên v2 mang túi đồ sang phần `Inventory` mà không mất số lượng |
| market-system.md | TR-market-001: tiền được lưu | Quy tắc 9 đến 15 |
| neighbors-system.md | TR-neighbors-002: lưu nhờ vả, cây, món đã mở | Quy tắc 1 đến 8 |
| village-restoration.md | TR-village-002: lưu tiến độ; tải thì dựng ngay không hiệu ứng | Quy tắc 9 đến 15 |

## Performance Implications
- **CPU**: Thêm một lần đọc lại và phân tích JSON vài KB mỗi lần lưu; chưa đo.
- **Memory**: Không đáng kể (bản sao khi nâng cấp chỉ lúc tải).
- **Load Time**: Thêm nâng cấp từng bước khi tải bản lưu cũ; chạy một lần.
- **Network**: Không áp dụng.

## Migration Plan
1. Thêm `LoadResult`, `UpgradeResult`, `SaveMigrations` (bảng `MIGRATIONS` rỗng cho tới v2).
2. Sửa `SaveGame`: `LoadResult`, thứ tự thử `.tmp`, chính, `.bak`; bỏ `_reject` và tác dụng phụ của `has_save()`; ghi có đọc lại, xoay vòng `.bak` bền; `archive_for_new_game()`.
3. Sửa `Main._load_saved_game` theo trạng thái `LoadResult`: `NEWER_VERSION`, `UNREADABLE`, `CORRUPT` tắt tự lưu và hiện lỗi; `RECOVERED` hiện thông báo; đếm lưu thất bại liên tiếp.
4. Đóng băng bản lưu v1 hiện có thành `tests/fixtures/saves/v1.json` (tạo bằng `SaveGame.save` với trạng thái mẫu, không dùng file thật của người chơi).
5. Viết bài kiểm trong `tests/unit/save/`: bảng mọi tổ hợp `.tmp`, chính, `.bak` (không có, rỗng, hỏng, hợp lệ, mới hơn) và kết quả mong đợi, kèm từng điểm bị ngắt: chỉ có `.tmp`, chỉ có `.bak`, `.tmp` cộng `.bak` không có file chính, một `.tmp` hỏng đứng một mình (phải ra `NO_SAVE`); `NEWER_VERSION` và `UNREADABLE` dừng chứ không rơi xuống `.bak`; `save()` từ chối khi file chính mới hơn; nâng fixture; `save({})`; `archive_for_new_game` (đánh số, tỉa 3 bộ, không tỉa `v<N>.bak`). Dựng trạng thái ngắt bằng cách tạo sẵn các file, như bài kiểm hiện có đã làm.
6. Cập nhật 8 bài kiểm `SaveGame` hiện có cho API mới. Bài kiểm `test_save_twice_keeps_latest_and_leaves_no_temp_file` đang khẳng định `.bak` **không** tồn tại sau khi lưu; nó mâu thuẫn quy tắc 15 và phải đổi thành khẳng định `.bak` chính là bản lưu trước.
7. Khi ADR `Inventory` được cài: thêm `migrate_v1_to_v2`, nâng `FORMAT_VERSION`, thêm `v2.json`.
8. Khi ADR này được Accepted: thêm dòng "sửa đổi bởi ADR-0005" vào Version History của ADR-0001.
9. Kiểm các mục Verification Required trên Android và Windows thật.

## Validation Criteria
- Mọi tổ hợp trạng thái `.tmp`, chính, `.bak` trong bảng kiểm cho trạng thái đúng và không đổi tên hay xoá file nào khi tải.
- Fixture v1 nâng được tới phiên bản hiện tại và `from_dict` khôi phục đúng trạng thái (so từng byte với ảnh chụp trước).
- Bản lưu `version` lớn hơn: file không đổi, tự lưu bị tắt, thông báo hiện.
- Cắt cụt file chính (rỗng hoặc nửa chừng): tải từ `.bak` và báo `RECOVERED`.
- Chỉ còn `.tmp` hợp lệ: tải từ `.tmp`.
- Lưu hai lần liền: `.bak` là bản của lần lưu đầu.
- Trên Android và Windows thật: các mục Verification Required đạt, hoặc ADR được sửa theo kết quả.

## Related
- ADR-0001: ADR này sửa đổi các mục "Ghi an toàn" và "Đọc nghiêm ngặt" của nó.
- ADR-0002: `Main` điều phối tải, hiện lỗi (quy tắc 9).
- ADR-0004: khi nào lưu (sự kiện vòng đời, bỏ qua khi trạng thái không đổi).
- ADR `Inventory` (sẽ viết): lần nâng v1 lên v2 đầu tiên.
- `design/gdd/` các tiêu chí lưu và tải; `docs/architecture/architecture-review-2026-10-27.md` (phát hiện độ bền ghi).
