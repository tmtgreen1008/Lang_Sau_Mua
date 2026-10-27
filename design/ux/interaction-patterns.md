# Interaction Pattern Library

> **Status**: In Design
> **Author**: To Truong + ux-designer
> **Last Updated**: 2026-10-27
> **Template**: Interaction Pattern Library

---

## Overview

Thư viện này định nghĩa các mẫu tương tác dùng chung của Làng Sau Mưa, để mọi màn hình và hệ thống mới dùng lại thay vì tự nghĩ lại.

- **Phạm vi:** game điện thoại, chỉ cảm ứng, một lần chạm, màn hình ngang. Khung nhìn gốc 1152×648; chữ cơ bản 24 px, tiêu đề 30 px, đồng hồ 36 px.
- **Nguồn:** các mẫu được **rút từ mã** ngày 2026-10-27 (`hud.gd`, `market_panel.gd`, `neighbor_panel.gd`, `dish_panel.gd`, `main.gd`), vì dự án chưa có UX spec nào. Mô tả đánh dấu **[Hiện tại]** khớp mã. Đánh dấu **[Yêu cầu, chưa cài]** là yêu cầu từ `design/accessibility-requirements.md` mà mã chưa đáp ứng.
- **Quy tắc chung từ yêu cầu trợ năng (Standard):** vùng chạm tối thiểu 72×72 px; "đang chọn" không chỉ khác màu; thông tin hành động không tự tắt dưới 5 giây và không bị ghi đè; không thao tác nào cần giữ, kéo hay nhiều ngón.
- **Sai khác có chủ ý với `.claude/rules/ui-code.md`:** quy tắc đó đòi hỗ trợ bàn phím/chuột và tay cầm cho mọi điều khiển, và mọi chữ đi qua hệ thống bản địa hoá. Dự án chỉ cảm ứng (`focus_mode = FOCUS_NONE` ở mọi nút) và chữ tiếng Việt viết thẳng trong mã, nên **hai quy tắc này hiện không được đáp ứng**. Thư viện chỉ định nghĩa mẫu cảm ứng. Bản địa hoá chữ là một khoảng trống (xem Gaps & Patterns Needed).

---

## Pattern Catalog

| # | Mẫu | Category | Dùng ở | Trạng thái |
|---|-----|----------|--------|-----------|
| 1 | Chạm để đi, rồi mới làm | Input | Ô ruộng, quầy chợ, hàng xóm, đất trống | Hiện tại |
| 2 | Bảng chặn nền (modal) | Modal | Bảng chợ, bảng hàng xóm, bảng món ăn | Hiện tại |
| 3 | Nhóm nút chọn một | Input | Hàng công cụ, hàng chọn hạt | Hiện tại; cần dấu hiệu "đang chọn" không chỉ bằng màu |
| 4 | Bộ chọn số lượng | Input | Bảng chợ | Hiện tại |
| 5 | Nút tắt tới khi hợp lệ, kèm lý do | Input | "Nộp", "Bán", `[-]` `[+]` | Hiện tại |
| 6 | Dòng thông báo thoáng qua | Feedback | Lỗi thao tác, bán, thu hoạch, sang ngày | Hiện tại; cần xếp hàng và ≥5 giây |
| 7 | Chỉ số luôn hiện | Data Display | Tiền, túi đồ, ngày/giai đoạn/mùa | Hiện tại |
| 8 | Nút hành động một chạm | Input | "Đi ngủ", "Món ăn" | Hiện tại; "Đi ngủ" cần xác nhận |
| 9 | Trạng thái rỗng kèm gợi ý | Data Display | Bảng chợ, bảng món ăn | Hiện tại |
| 10 | Kết quả hiện trong bảng | Feedback | Bảng hàng xóm | Hiện tại |

---

## Patterns

### 1. Chạm để đi, rồi mới làm

**Category**: Input
**Used In**: bản đồ chính (ô ruộng, quầy chợ, hàng xóm, đất trống)

**Description**: Người chơi chạm một điểm trên bản đồ; nhân vật đi thẳng tới đó, và việc tương ứng được làm khi đến nơi. Nhịp "đi rồi mới làm" là chủ ý giữ cảm giác chậm rãi.

**Specification**:
- [Hiện tại] Nhận một lần chạm khi nhấn (hoặc chuột trái, bỏ qua chuột giả lập từ cảm ứng để không chạm đôi).
- [Hiện tại] Bỏ qua chạm khi có bảng đang mở hoặc chạm vào nút HUD.
- [Hiện tại] Xác định đích theo thứ tự ưu tiên: hàng xóm, quầy chợ, ô ruộng, rồi đất trống. Nhân vật đi thẳng với tốc độ không đổi, độc lập tốc độ khung hình.
- [Hiện tại] Đến nơi: mở bảng (hàng xóm, chợ) hoặc áp dụng công cụ đang chọn lên ô. Thao tác không hợp lệ hiện thông báo lý do (mẫu 6).
- [Hiện tại] Chỉ có một việc chờ: chạm lần hai khi đang đi thay đích và thay việc đang chờ.
- [Yêu cầu, chưa cài] Mọi việc chỉ cần một lần chạm; không giữ, kéo hay hai ngón.

**When to Use**: thao tác lên đối tượng trên bản đồ.
**When NOT to Use**: hành động cần tức thời, không liên quan vị trí nhân vật (dùng mẫu 8).

**Reference**: `main.gd` (`_on_tap`, `_on_player_arrived`).

### 2. Bảng chặn nền (modal)

**Category**: Modal
**Used In**: bảng chợ, bảng hàng xóm, bảng món ăn

**Description**: Một hộp nằm giữa màn hình trên lớp tối, chặn mọi chạm bên dưới, dùng khi cần người chơi tập trung vào một việc.

**Specification**:
- [Hiện tại] Lớp riêng (`layer = 2`), lớp phủ đen độ mờ 60% phủ cả màn hình và chặn chạm, hộp ở giữa. Chiều rộng tối thiểu 760 px (chợ, hàng xóm) hoặc 520 px (món ăn).
- [Hiện tại] Tiêu đề căn giữa, chữ 30 px; nội dung chữ 24 px; nút "Đóng" ở cuối, tối thiểu 72×72.
- [Hiện tại] Bảng bắt đầu ẩn, mở khi nhân vật đến nơi (hoặc từ nút HUD với bảng món ăn). Chỉ đóng bằng nút "Đóng"; chạm lên lớp tối không đóng bảng.
- [Hiện tại] Khi có bảng mở, chạm lên bản đồ bị bỏ qua.
- [Yêu cầu, chưa cài] Đồng hồ ngày tạm dừng khi bảng mở (hiện vẫn chạy).
- [Yêu cầu, chưa cài] Bảng rộng cố định phải kiểm ở cỡ chữ 150%: không tràn, không bị cắt; nút giữ ≥72×72.

**When to Use**: nhập liệu hoặc đọc có nhiều thông tin (bán hàng, nhờ vả, danh sách).
**When NOT to Use**: phản hồi ngắn (dùng mẫu 6) hoặc thông tin luôn cần thấy (dùng mẫu 7).

**Reference**:

    +--------------------------------------+
    |   (lớp tối 60%, chặn chạm)           |
    |   +------------------------------+   |
    |   |        Tiêu đề (30 px)       |   |
    |   |   nội dung (24 px)           |   |
    |   |   [      Đóng (>=72 px)    ] |   |
    |   +------------------------------+   |
    +--------------------------------------+

### 3. Nhóm nút chọn một

**Category**: Input
**Used In**: hàng công cụ (Cuốc, Gieo hạt, Tưới, Thu hoạch), hàng chọn hạt ("Hạt …")

**Description**: Một hàng nút bật tắt, chỉ một nút được chọn; lựa chọn giữ nguyên cho tới khi đổi.

**Specification**:
- [Hiện tại] Nút bật tắt thuộc một nhóm loại trừ nhau; nút tối thiểu 120×72, chữ 24 px.
- [Hiện tại] Công cụ mặc định là Cuốc. Hàng chọn hạt chỉ liệt kê hạt đã mở khoá; nếu hạt đang chọn không còn trong danh sách thì chọn hạt đầu tiên.
- [Hiện tại] Trạng thái "đang chọn" hiện theo kiểu nút nhấn mặc định của theme.
- [Yêu cầu, chưa cài] "Đang chọn" phải có dấu hiệu không chỉ bằng màu (viền dày hoặc dấu chọn). Kiểu theme hiện tại chưa được kiểm.

**When to Use**: chọn một chế độ hay công cụ kéo dài qua nhiều thao tác.
**When NOT to Use**: hành động làm một lần (mẫu 8).

**Reference**: `hud.gd` (`tool_group`, `crop_group`).

### 4. Bộ chọn số lượng

**Category**: Input
**Used In**: bảng chợ

**Description**: Chọn một số lượng trong khoảng cho phép rồi thực hiện hành động trên chính hàng đó.

**Specification**:
- [Hiện tại] Một hàng gồm nhãn "Tên - giá N - có M", nút `[-]`, số lượng đã chọn, nút `[+]`, nút hành động "Bán". `[-]` và `[+]` tối thiểu 72×72, "Bán" 120×72; số rộng tối thiểu 56 px.
- [Hiện tại] Số lượng bị kẹp trong 0 tới số đang có. `[-]` tắt ở 0, `[+]` tắt ở mức tối đa, "Bán" tắt khi số bằng 0.
- [Hiện tại] Bán xong thì số của hàng đó về 0; mở lại bảng thì số đã chọn bị xoá.
- [Yêu cầu, chưa cài] Nút "Tối đa" chọn hết số đang có bằng một lần chạm (ý định đã xác nhận trong GDD chợ), để giảm số lần chạm.

**When to Use**: chọn số lượng nguyên với cận trên rõ ràng.
**When NOT to Use**: lựa chọn có/không (mẫu 5 hoặc 8).

**Reference**:

    Ngô - giá 50 - có 3     [-]  2  [+]  [Bán]

### 5. Nút tắt tới khi hợp lệ, kèm lý do

**Category**: Input
**Used In**: "Nộp" (bảng hàng xóm), "Bán", `[-]` và `[+]` (bảng chợ)

**Description**: Một nút bị tắt cho tới khi điều kiện đủ; khi lý do không hiển nhiên, lý do phải hiện bằng chữ ngay trên màn hình.

**Specification**:
- [Hiện tại] "Nộp" chỉ bật khi đủ mọi thứ cần nộp. Khi chưa đủ, bảng hiện từng hàng "Ngô 2/3" và dòng "Còn thiếu: Ngô x1, …".
- [Hiện tại] Nút `[-]`, `[+]`, "Bán" tắt tại các cận, lý do tự rõ nên không cần chữ.
- [Yêu cầu, chưa cài] Trạng thái tắt không được là cách duy nhất để hiểu vì sao không làm được; luôn có lý do bằng chữ khi không tự rõ.

**When to Use**: hành động có điều kiện mà người chơi có thể tự đáp ứng.
**When NOT to Use**: thao tác lên bản đồ không có nút để tắt (dùng thông báo, mẫu 6).

**Reference**: `neighbor_panel.gd` (`can_hand_over`, "Còn thiếu").

### 6. Dòng thông báo thoáng qua

**Category**: Feedback
**Used In**: lỗi thao tác trên ô ("Chưa có hạt giống này…"), thu hoạch, bán, sang ngày hoặc mùa, làng dựng lại, lỗi đọc file lưu

**Description**: Một dòng chữ ngắn báo kết quả của việc vừa làm, nằm ở lề trái cạnh ruộng, không đè lên ô.

**Specification**:
- [Hiện tại] Một nhãn tại (16, 140), rộng 320 px, tự xuống dòng, chữ 24 px có viền đen, không chặn chạm.
- [Hiện tại] Tin mới ghi đè tin cũ và khởi động lại bộ đếm; tự xoá sau 2,5 giây.
- [Yêu cầu, chưa cài] Tin có thông tin hành động hiện tối thiểu 5 giây và xếp hàng, không ghi đè. **Tin quan trọng:** lý do thao tác thất bại, sang mùa, mở khoá hạt hoặc món, làng dựng lại, lỗi đọc file lưu. **Tin phụ (giữ 2,5 giây):** thu hoạch, bán.
- [Yêu cầu, chưa cài] Thời lượng đọc từ dữ liệu, không hardcode.

**When to Use**: xác nhận ngắn cho thao tác vừa làm; thông tin người chơi không cần xem lại.
**When NOT to Use**: thông tin cần xem lại hoặc quan trọng như phần thưởng (dùng mẫu 10, vẫn còn trong bảng).

**Reference**: `hud.gd` (`show_message`, `MESSAGE_SECONDS`).

### 7. Chỉ số luôn hiện

**Category**: Data Display
**Used In**: tiền, túi đồ, ngày/giai đoạn/mùa

**Description**: Nhãn chữ luôn hiển thị trên HUD cho thông tin người chơi cần thấy mọi lúc.

**Specification**:
- [Hiện tại] Hàng trên: túi đồ (chiếm phần còn lại), tiền, rồi nút "Đi ngủ" và "Món ăn". Dòng "Ngày N - giai đoạn - mùa" căn giữa bên dưới, chữ 36 px. Chữ khác 24 px.
- [Hiện tại] Túi đồ chỉ liệt kê cây đã mở khoá, dạng "Ngô: 2 | Cà chua: 0".
- [Hiện tại] Chữ có viền đen để nổi trên bản đồ. Các nhãn bỏ qua chạm (chạm xuyên qua xuống bản đồ).
- [Yêu cầu, chưa cài] Tương phản chữ đạt ≥4,5:1 (chưa đo); chỉnh cỡ chữ 100%, 125%, 150%.

**When to Use**: thông tin thay đổi theo thời gian mà người chơi cần thấy liên tục.
**When NOT to Use**: thông tin chi tiết hoặc ít dùng (đưa vào bảng, mẫu 2).

**Reference**: `hud.gd` (`set_money`, `set_inventory`, `set_time_info`).

### 8. Nút hành động một chạm

**Category**: Input
**Used In**: "Đi ngủ", "Món ăn" (hàng trên của HUD)

**Description**: Nút bấm thực hiện ngay một hành động, không phụ thuộc vị trí nhân vật.

**Specification**:
- [Hiện tại] Nút 120×72, chữ 24 px. "Đi ngủ" kết thúc ngày sớm, không xác nhận, không hoàn tác. "Món ăn" mở bảng món ăn (mẫu 2).
- [Hiện tại] Chạm vào nút không làm nhân vật đi (HUD chặn chạm xuống bản đồ).
- Lưu ý: theo GDD, sang ngày làm cây chưa chín mà không được tưới hôm đó bị héo, nên "Đi ngủ" khi còn cây chưa tưới có thể làm mất vụ. Hiện chưa có xác nhận (xem Gaps).

**When to Use**: hành động tức thời, không cần chọn thêm.
**When NOT to Use**: hành động cần nhắm vào một ô (mẫu 1) hoặc nhiều thông tin (mẫu 2).

**Reference**: `hud.gd` (`sleep_requested`, `dishes_requested`).

### 9. Trạng thái rỗng kèm gợi ý

**Category**: Data Display
**Used In**: bảng chợ ("Chưa có nông sản để bán."), bảng món ăn ("Chưa biết món nào. Giúp hàng xóm để học thêm.")

**Description**: Khi danh sách rỗng, bảng hiện một dòng chữ thay vì để trống, và nên gợi người chơi bước tiếp theo.

**Specification**:
- [Hiện tại] Một nhãn căn giữa, chữ 24 px, thay cho danh sách rỗng.
- [Hiện tại] Bảng món ăn có gợi ý bước tiếp; bảng chợ thì không. Hai bảng chưa nhất quán.
- [Yêu cầu, chưa cài] Mọi danh sách phụ thuộc dữ liệu có trạng thái rỗng, kèm gợi ý khi có bước tiếp rõ ràng.

**When to Use**: mọi danh sách có thể rỗng.
**When NOT to Use**: lỗi của một thao tác (dùng mẫu 6).

**Reference**: `market_panel.gd` (`refresh`), `dish_panel.gd` (`open`).

### 10. Kết quả hiện trong bảng

**Category**: Feedback
**Used In**: bảng hàng xóm sau khi nộp

**Description**: Kết quả quan trọng của một hành động hiện ngay trong bảng và ở lại cho tới khi mở lại bảng, nên người chơi đọc được theo nhịp của mình.

**Specification**:
- [Hiện tại] Sau khi nộp, bảng hiện lời xong của hàng xóm cùng phần thưởng ("Nhận N tiền. Mở khoá hạt X. Học món Y.") phía trên nhờ vả kế tiếp. Văn bản ở lại tới khi bảng mở lại.
- [Hiện tại] Phần thưởng cũng được đẩy lên dòng thông báo HUD (mẫu 6). Vì bảng ở lớp cao hơn HUD, tin trên HUD có thể bị lớp tối phủ lên khi bảng còn mở (chưa kiểm).

**When to Use**: kết quả cần đọc kỹ hoặc xem lại, đặc biệt phần thưởng và mở khoá.
**When NOT to Use**: xác nhận ngắn (dùng mẫu 6).

**Reference**: `neighbor_panel.gd` (`show_result`), `main.gd` (`_on_request_completed`).

---

## Gaps & Patterns Needed

Mẫu chưa có trong mã, nêu trong `design/accessibility-requirements.md`, hoặc chưa nhất quán:

| # | Khoảng trống | Nguồn | Dựa trên mẫu |
|---|--------------|-------|--------------|
| 1 | **Bảng Tạm dừng:** nút trên HUD mở bảng, dừng đồng hồ; chứa Tuỳ chọn trợ năng, Hướng dẫn, âm lượng | Cognitive (Basic) | 2 |
| 2 | **Sổ nhờ vả:** bảng chỉ đọc liệt kê nhờ vả hiện tại của cả 3 hàng xóm kèm có/cần, mở bằng một nút HUD | Cognitive | 2, 5 |
| 3 | **Thông báo xếp hàng:** tin quan trọng ≥5 giây, không ghi đè; phân loại tin quan trọng và phụ | Cognitive | 6 |
| 4 | **Xác nhận cho hành động không hoàn tác được** ("Đi ngủ"): chưa chọn cách (hộp xác nhận hay cửa sổ hoàn tác) | Phát hiện khi rút mẫu | 8 |
| 5 | **"Đang chọn" không chỉ bằng màu** cho nhóm nút | Visual | 3 |
| 6 | **Nút "Tối đa"** | Ý định đã xác nhận (GDD chợ) | 4 |
| 7 | **Trang Hướng dẫn xem lại** | Cognitive | 2 |
| 8 | **Bản địa hoá chữ:** chữ tiếng Việt viết thẳng trong mã, trái `ui-code.md` | `ui-code.md` | tất cả |
| 9 | **Không nhất quán:** nút "Đóng" chiếm cả hàng (chợ, món ăn) nhưng đứng cạnh "Nộp" (hàng xóm); trạng thái rỗng của chợ không có gợi ý | Rút từ mã | 2, 9 |
| 10 | **Mẫu cho hệ thống sắp làm** (câu cá, nấu ăn, màn bắt đầu): chưa có GDD, thêm mẫu khi có | Systems index | mới |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| "Đi ngủ" khi còn cây chưa tưới: hộp xác nhận, cửa sổ hoàn tác, hay giữ nguyên? | To Truong | Khi viết GDD HUD (#9) | Chưa quyết |
| Chạm lên lớp tối có nên đóng bảng? Hiện chỉ đóng bằng nút "Đóng" (tránh đóng nhầm cho người run tay, nhưng khác thói quen thường gặp trên điện thoại). | To Truong | Khi viết GDD HUD (#9) | Chưa quyết; hiện chỉ nút "Đóng" |
| Hai quy tắc trong `.claude/rules/ui-code.md` (hỗ trợ bàn phím/tay cầm, bản địa hoá chữ): xác nhận sai khác cho dự án chỉ cảm ứng, hay sửa quy tắc cho phù hợp? | To Truong | Trước cổng Production | Chưa quyết; ghi là sai khác có chủ ý |
| Tin thưởng trên HUD có bị lớp tối của bảng hàng xóm phủ lên, khiến khó đọc? | qa-tester | Khi chạy game thử | Chưa kiểm |
| Kiểu "đang chọn" của nút theo theme mặc định có phân biệt được không chỉ bằng màu? | ux-designer | Khi chụp ảnh mô phỏng mù màu | Chưa kiểm |
