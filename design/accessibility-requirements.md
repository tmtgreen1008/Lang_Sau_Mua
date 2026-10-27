# Accessibility Requirements

> **Status**: In Design
> **Author**: To Truong + ux-designer
> **Last Updated**: 2026-10-27
> **Template**: Accessibility Requirements

## Accessibility Tier Definition

### Tier Definitions

| Tier | Cam kết cốt lõi | Mức công sức |
|------|-----------------|--------------|
| **Basic** | Chữ quan trọng đọc được; không có chức năng nào chỉ dựa vào màu; có chỉnh âm lượng riêng cho nhạc, SFX, giọng; không rủi ro chớp sáng. | Thấp, chủ yếu là ràng buộc thiết kế |
| **Standard** | Basic, cộng: chỉnh cỡ chữ; ít nhất một chế độ mù màu; không có thao tác định giờ nào không thể kéo dài hoặc tắt; ánh xạ lại phím (với game cảm ứng thay bằng quy tắc vùng chạm). | Trung bình, cần làm riêng |
| **Comprehensive** | Standard, cộng: đọc màn hình cho menu, âm thanh mono, hỗ trợ độ khó, dời HUD, giảm chuyển động, chỉ báo hình ảnh cho âm thanh quan trọng. | Cao, cần API nền tảng |
| **Exemplary** | Comprehensive, cộng: tuỳ biến phụ đề đầy đủ, tương phản cao, kiểm toán bên ngoài. | Rất cao |

### This Project's Commitment

**Target Tier**: Standard (điều chỉnh cho cảm ứng)

**Rationale**: Làng Sau Mưa là game nông trại cozy chỉ dùng cảm ứng, chơi ngắn 20 đến 30 phút, và không có thao tác nào đòi phản xạ nhanh; rào cản vận động chính vì vậy là kích thước và khoảng cách vùng chạm, không phải tốc độ. Game đọc khá nhiều chữ (lời hàng xóm, bảng chợ, danh sách món ăn) và hiện dùng khối màu để báo trạng thái ô ruộng, nên rào cản thị giác (cỡ chữ, mù màu) là lớn nhất; Standard xử lý cả hai. Ánh xạ lại phím không áp dụng cho game chỉ có cảm ứng, nên được thay bằng quy tắc vùng chạm bên dưới. Các hạng mục còn lại của Comprehensive (đọc màn hình, dời HUD) vượt khả năng của một người làm game ở giai đoạn này; hạ xuống Basic sẽ bỏ chỉnh cỡ chữ và chế độ mù màu, hai thứ cần thiết nhất cho game này. Đối tượng người chơi chi tiết chưa xác định (INTENT UNKNOWN trong game-concept), nên mức này nên được xem lại khi có dữ liệu người chơi thật.

**Features explicitly in scope (beyond tier baseline)**:
- **Giảm chuyển động** (nâng từ Comprehensive): hiệu ứng dựng làng là chuyển động đáng kể duy nhất, và `VillageView.reduce_motion` đã có trong mã nhưng chưa nối vào tuỳ chọn nào. Mọi hiệu ứng mới (câu cá, nấu ăn) cũng phải tôn trọng cờ này.
- **Quy tắc vùng chạm** (thay cho ánh xạ lại phím): mọi điều khiển chạm được tối thiểu 72×72 px (mã hiện đã đạt); không có thao tác chỉ-hover; không thao tác nào bắt buộc giữ lâu, kéo, hoặc hai ngón mà không có cách thay thế bằng một lần chạm.
- **Không có thao tác nào bị giới hạn thời gian không thể kéo dài**: đồng hồ ngày tạm dừng khi mở bảng (ý định đã xác nhận trong time-system, chưa cài). Việc có thêm tuỳ chọn tốc độ ngày hay không được ghi ở Open Questions.

**Features explicitly out of scope**:
- Đọc màn hình (TalkBack, VoiceOver) cho menu và thế giới: thuộc Comprehensive; chưa có cơ sở để cam kết. Sẽ ghi vào Known Intentional Limitations.
- Âm thanh mono, phụ đề tuỳ biến, chỉ báo hình ảnh cho âm thanh: game chưa có âm thanh hay giọng đọc; xem lại khi thiết kế hệ thống Âm thanh (#17).
- Dời HUD, chế độ tương phản cao, hỗ trợ độ khó, kiểm toán bên ngoài: ngoài phạm vi Standard.

---

## Visual Accessibility

> Trạng thái "Chưa làm" nghĩa là chưa có trong mã. Giá trị cỡ chữ lấy từ `hud.gd` và các bảng (FONT_SIZE 24, đồng hồ 36, tiêu đề bảng 30) trên khung nhìn gốc 1152×648.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Cỡ chữ tối thiểu: bảng và nút | Standard | Bảng chợ, hàng xóm, món ăn; mọi nút | Đã đạt | Tối thiểu 24 px ở khung nhìn gốc 1152×648 (tương đương khoảng 40 px ở 1080, vì chế độ kéo giãn là `canvas_items`). Không dùng chữ nhỏ hơn cho thông tin người chơi phải đọc. |
| Cỡ chữ tối thiểu: HUD | Standard | HUD | Đã đạt | Đồng hồ 36 px; tiền, ngày, túi đồ 24 px. Thông tin thiết yếu không được nhỏ hơn 24 px. |
| Chỉnh cỡ chữ | Standard | Toàn bộ chữ và nút | Chưa làm | 3 mức: 100%, 125%, 150%; mặc định 100%. Nút vẫn tối thiểu 72×72 px ở mọi mức. Phải kiểm mọi màn ở 100% và 150%: bảng hàng xóm có `TEXT_WIDTH` cố định 720 px, cần xuống dòng hoặc cuộn, không tràn. |
| Tương phản chữ | Standard | Mọi chữ UI | Chưa đo | Tối thiểu 4,5:1 cho chữ thường, 3:1 cho chữ lớn. Chữ HUD có viền đen 6 đến 8 px. Màu chữ và nền lấy từ theme mặc định, chưa đo; đo bằng công cụ, ghi kết quả vào Audit History, đo lại khi thay nghệ thuật thật. |
| Tương phản đối tượng: cây so với nền ô | Standard | Ô ruộng | Chưa đo | Hình cây tối thiểu 3:1 so với nền ô ở mọi trạng thái (đã cuốc, đã tưới). |
| Hỗ trợ mù màu | Standard | Loại cây và trạng thái ô | Chưa làm | Không đổi bảng màu. (1) Mỗi cây có hình dạng riêng, luôn bật, không chỉ khác màu; hình cụ thể do art bible quyết. (2) Tuỳ chọn **Nhãn cây**: hiện tên ngắn (Cải, Cà, Ngô) trên ô. Hai cây dễ nhầm nhất, cải xanh `#5fbf4a` và cà chua `#e0463a`, tính tay chỉ chênh khoảng 1,8:1 về độ sáng; nên chọn màu cách xa nhau hơn. |
| Kiểm toán "màu là dấu hiệu duy nhất" | Basic | Toàn bộ UI và game | Một phần | Xem bảng bên dưới; mọi dòng chưa "Đạt" phải có dấu hiệu dự phòng trước khi phát hành. |
| Chỉnh độ sáng | Basic | Toàn cục | Không áp dụng | Điện thoại dùng độ sáng của hệ điều hành; game không có màn hình hiệu chỉnh. |
| Chớp sáng, chớp nháy | Basic | Mọi hiệu ứng | Đạt hiện tại | Hiệu ứng dựng làng chạy 1 giây, một lần mỗi mảnh, độ sáng 0,45 (theo GDD làng). Yêu cầu: không hiệu ứng nào có hơn 3 chớp mỗi giây; hiệu ứng mới (câu cá, nấu ăn, lễ hội) phải tuân thủ và tôn trọng `reduce_motion`. |

### Color-as-Only-Indicator Audit

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| Ô ruộng: loại cây | Xanh, đỏ, vàng (cả ba hiện là hình tròn) | Cây nào đang trồng | Hình riêng cho từng cây (luôn bật) + tuỳ chọn Nhãn cây | Chưa làm |
| Ô ruộng: đã tưới | Nền đậm hơn, viền xanh dương 3 px | Đã tưới hôm nay | Viền (có hoặc không) là dấu hiệu hình dạng; nền chỉ đậm hơn chút | Cần kiểm bằng mô phỏng mù màu |
| Ô ruộng: chín | Vòng vàng 4 px | Sẵn sàng thu hoạch | Vòng (hình dạng) và cây ở kích thước lớn nhất | Đạt |
| Ô ruộng: héo | Nền xám-nâu, chấm tối bán kính 10 | Cây héo | Chấm tối là hình, nhưng gần cỡ mầm mới gieo (bán kính 8); cần hình riêng khác mầm non | Cần kiểm |
| HUD: công cụ và cây đang chọn | Màu nút nhấn của theme | Đang chọn gì | Chưa có; cần thêm dấu hiệu (viền dày hoặc dấu chọn) | Chưa kiểm |
| Mức làng | Màu phủ nền | Mức hồi sinh | Mảnh làng đổi hình (xiêu thành dựng lại); thông báo tên mức (ý định, chưa cài) | Đạt |
| Nút "Nộp" bật hay tắt | Xám khi tắt | Đủ hàng chưa | Lời "còn thiếu" kèm phần thiếu bằng chữ (theo GDD hàng xóm) | Đạt |

---

## Motor Accessibility

> Trạng thái "Chưa làm" nghĩa là chưa có trong mã. Kích thước tính bằng điểm ảnh của khung nhìn gốc 1152×648. Mã nhập liệu: `main.gd` (`_unhandled_input`).

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Điều khiển chỉ bằng một lần chạm (thay cho ánh xạ lại phím) | Standard | Mọi điều khiển | Đạt hiện tại | Game chỉ nhận một lần chạm khi nhấn (và chuột trái khi phát triển); không kéo, giữ lâu, vuốt hay hai ngón. Yêu cầu giữ khi thêm hệ thống mới: không thao tác nào bắt buộc kéo, giữ lâu, vuốt hoặc nhiều ngón mà thiếu cách thay bằng một lần chạm. |
| Vùng chạm tối thiểu | Standard | Mọi điều khiển chạm được | Đạt trong mã, chưa thử máy thật | Tối thiểu 72×72 px. Hiện: ô ruộng 80, quầy chợ 180×120, hàng xóm 100×100, nút HUD ≥120×72, nút trong bảng ≥72×72. Quy đổi khoảng 40 đến 46 dp trên điện thoại có cạnh ngắn 360 đến 412 dp (72 × cạnh ngắn ÷ 648). Hướng dẫn thường gặp của Android (48 dp) và iOS (44 pt) KHÔNG nằm trong tài liệu dự án; kiểm trên máy thật, và nếu thiếu thì nâng mức tối thiểu lên 88 px. |
| Không có thao tác chỉ-hover | Standard | Toàn bộ UI | Đạt | Game chỉ cảm ứng; ghi chú nền tảng đã cấm thao tác chỉ-hover. |
| Chế độ một tay | Standard | Mọi thao tác chơi | Đạt hiện tại | Toàn bộ game chơi được bằng một ngón của một bàn tay. Giữ nguyên khi thêm hệ thống mới. |
| Giữ để làm, nhập nhanh, nhắm | Standard | Không có | Không áp dụng | Hiện không có thao tác giữ, nhập quá 3 lần mỗi giây hay nhắm. Ghi lại để chặn khi thêm hệ thống mới. |
| Cửa sổ thời gian của câu cá | Standard | Câu cá (hệ thống #12) | Chưa thiết kế | Bất kỳ cửa sổ cá cắn nào đòi phản xạ phải có hệ số kéo dài (khoảng 0,5x đến 3,0x, mặc định 1,0x, theo mẫu) hoặc chế độ chạm một lần không định giờ. Ghi vào GDD câu cá khi thiết kế. |
| Tốc độ ngày | Standard | Đồng hồ ngày (hệ thống #2) | Chưa làm | Thao tác định giờ duy nhất của game. 3 mức: **Bình thường** (90 giây một ngày, theo `time_config.json`), **Chậm** (độ dài ngày gấp đôi), **Dừng** (ngày chỉ qua khi bấm "Đi ngủ"). Thực hiện bằng hệ số trong dữ liệu, không hardcode. Số ngày cây cần để lớn (`growth_days`) và mùa tính theo ngày nên không đổi. |
| Tạm dừng đồng hồ khi mở bảng | Standard | Bảng chợ, hàng xóm, món ăn | Chưa làm | Ý định đã xác nhận trong GDD thời gian (tiêu chí 7), đồng thời là yêu cầu trợ năng: hiện đồng hồ vẫn chạy khi bảng mở. Liên kết TR-time-004. |
| Chạm thừa khi nhân vật đang đi | Standard | Điều khiển nhân vật | Rủi ro ghi nhận | Chạm lần hai khi đang đi thay việc đang chờ (GDD nhân vật). Giữ nguyên hành vi đã xác nhận; rủi ro với người run tay hoặc lỡ chạm được ghi ở Open Questions và kiểm bằng chơi thử. |
| Ánh xạ lại phím, chuyển phương thức nhập | Standard | Không có | Không áp dụng | Game chỉ cảm ứng. Quy tắc vùng chạm ở trên thay cho ánh xạ lại phím. |
| Dời vị trí HUD | Comprehensive | HUD | Ngoài phạm vi | Ghi vào Known Intentional Limitations. |

---

## Cognitive Accessibility

> Trạng thái "Chưa làm" nghĩa là chưa có trong mã. Mã tham chiếu: `hud.gd` (`show_message`, `MESSAGE_SECONDS`), `main.gd`, `assets/data/neighbors.json`.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Thời gian đọc thông báo | Standard | Dòng thông báo trên HUD | Chưa đạt | Hiện mọi tin tự xoá sau 2,5 giây và tin mới ghi đè tin cũ (theo đọc mã, chưa chạy thử; thông báo sang mùa có vẻ bị thông báo ngày ghi đè ngay). Yêu cầu: tin có thông tin hành động hiện tối thiểu 5 giây và xếp hàng, không ghi đè. **Tin quan trọng:** lý do thao tác thất bại, sang mùa, mở khoá hạt hoặc món, làng dựng lại, lỗi đọc file lưu. **Tin phụ (giữ 2,5 giây):** thu hoạch, bán. Thời lượng đọc từ dữ liệu, không hardcode. |
| Lời hàng xóm | Standard | Bảng hàng xóm | Đạt | 21 đoạn lời, dài nhất 120 ký tự, trung bình khoảng 78; không tự tắt, đóng khi người chơi đóng bảng. Nội dung mới (câu cá, nấu ăn, nhờ vả R3 và R4) giữ trong mức này; đoạn vượt khoảng 120 ký tự là dấu hiệu cần xem lại. |
| Tạm dừng ở mọi trạng thái | Basic | Mọi trạng thái chơi | Chưa làm | Hiện không có nút tạm dừng hay menu. Thêm **nút Tạm dừng trên HUD** mở bảng tạm dừng và dừng đồng hồ; đây cũng là nơi đặt Tuỳ chọn trợ năng (#15) và Hướng dẫn. Cùng với tự dừng khi mở bảng và khi xuống nền (xem Motor, TR-time-004). |
| Mục tiêu hiện tại trong tối đa 2 lần bấm | Standard | HUD | Chưa làm | Hiện phải đi tới hàng xóm và mở bảng mới xem được nhờ vả. Thêm **Sổ nhờ vả**: một nút trên HUD mở bảng chỉ đọc liệt kê nhờ vả hiện tại của cả 3 hàng xóm kèm "có/cần". Nộp hàng vẫn ở bảng hàng xóm. Yêu cầu này thuộc hệ thống HUD (#9), chưa có GDD, nên phải đưa vào đó. |
| Hướng dẫn xem lại | Standard | Mọi hướng dẫn và trợ giúp | Chưa làm | Hiện game chưa có hướng dẫn hay trợ giúp nào. Khi thêm, mọi hướng dẫn xem lại được từ mục **Hướng dẫn** trong bảng Tạm dừng. Hướng dẫn đầu tiên đi qua nhờ vả đầu tiên của hàng xóm đầu tiên (lời luôn xem lại được ở bảng hàng xóm). |
| Tuỳ chọn độ khó | Standard | Toàn game | Không áp dụng | Game không có trạng thái thua; cây héo là rủi ro nhẹ có chủ ý (trụ cột "ấm áp, không áp lực"). Áp lực thời gian được xử lý bằng Tốc độ ngày (xem Motor). |
| Chỉ báo hình ảnh cho thông tin chỉ có âm thanh | Standard | Âm thanh | Không áp dụng hiện tại | Game chưa có âm thanh. Xem lại khi thiết kế hệ thống Âm thanh (#17). |
| Hỗ trợ điều hướng | Standard | Bản đồ | Không áp dụng | Bản đồ một màn, thấy mọi thứ cùng lúc; không cần đi nhanh hay chỉ dẫn. Xem lại khi thêm màn 2 và màn 3. |
| Ghi tải nhận thức theo hệ thống | Comprehensive | Mỗi hệ thống | Ngoài phạm vi | Ghi vào Known Intentional Limitations. HUD hiện có ít nhất 7 mục cùng lúc theo GDD (tiền, đồng hồ, túi đồ, công cụ, chọn hạt, Đi ngủ, Món ăn). |

### Auto-dismissing elements

| Element | Duration hiện tại | Chứa thông tin hành động | Yêu cầu |
|---------|------------------|--------------------------|---------|
| Dòng thông báo HUD | 2,5 giây (`MESSAGE_SECONDS`) | Có | Tin quan trọng ≥5 giây, xếp hàng; tin phụ 2,5 giây |
| Hiệu ứng dựng làng | 1 giây | Không (không có chữ) | Giữ; tuân theo `reduce_motion` |
| Bảng chợ, hàng xóm, món ăn | Không tự tắt | Có | Giữ nguyên |

---

## Auditory Accessibility

> **Hiện trạng:** game chưa có âm thanh (không có `AudioStreamPlayer`, file âm thanh hay bus nào). Mục này là **yêu cầu cho hệ thống Âm thanh (#17)**, không mô tả cái đã có. Hướng âm thanh theo `game-brief.md`: nhạc nền đàn bầu hoặc sáo nhẹ, tiếng ve, gà gáy. Không có giọng đọc: mọi lời thoại là chữ.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Âm thanh không bao giờ là kênh duy nhất | Basic | Mọi âm thanh | Quy tắc cho #17 | Mọi sự kiện có tiếng đều phải có phản hồi hình ảnh. Hiện đã đúng với mọi sự kiện của game (xem bảng bên dưới). Sự kiện mới (nhất là câu cá) phải giữ quy tắc này. |
| Chơi được hoàn toàn khi tắt tiếng | Basic | Toàn game | Quy tắc cho #17 | Không tính năng, hướng dẫn hay tiến độ nào phụ thuộc vào việc nghe được. |
| Âm lượng độc lập | Basic | 3 thanh: Nhạc, Hiệu ứng, Môi trường | Chưa làm | Khoảng 0 đến 100%, mặc định 80% (theo mẫu). Tách tiếng ve và gà gáy khỏi hiệu ứng thao tác vì chúng liên tục. Thêm thanh **Giọng** nếu sau này có giọng đọc. Có trong bảng Tạm dừng và trong Tuỳ chọn trợ năng (#15). Nơi lưu thiết lập: xem Open Questions. Ghi chú engine: nếu dùng `AudioStreamPlayer2D` với `audio_bus_override` trên `Area2D`, ở 4.7 phải đặt lại `area_mask` về lớp 1 (mặc định là 0), theo `docs/engine-reference/godot/modules/audio.md`. |
| Phụ đề cho lời nói | Basic | Mọi nội dung có giọng | Không áp dụng hiện tại | Không có giọng đọc. Nếu thêm giọng, phụ đề 100% là bắt buộc, kể cả lời nghe từ xa. |
| Chú thích cho âm thanh quan trọng | Comprehensive | Danh sách SFX bên dưới | Ngoài phạm vi | Không cần: mọi âm thanh quan trọng đã có phản hồi hình ảnh (quy tắc đầu bảng). |
| Âm thanh mono | Comprehensive | Đầu ra toàn cục | Ngoài phạm vi | Ghi vào Known Intentional Limitations. |
| Chỉ báo hình ảnh cho âm thanh định hướng | Comprehensive | Sự kiện ngoài màn hình | Không áp dụng | Bản đồ 2D một màn, không có sự kiện ngoài màn hình. |
| Tương thích máy trợ thính | Standard | Âm thanh tần số cao | Quy tắc cho #17 | Không cue nào mang thông tin quan trọng chỉ bằng âm cao (trên khoảng 4 kHz). Tiếng ve và chim là không khí, không mang thông tin. Kiểm khi có âm thanh thật. |
| Tôn trọng chế độ im lặng và ngắt âm của điện thoại | Standard | Android và iOS | NOT SOURCEABLE | `docs/engine-reference/godot/modules/audio.md` không nêu cách Godot 4.7 xử lý chế độ im lặng, cuộc gọi hay mất focus âm thanh trên điện thoại. Không điền từ trí nhớ; kiểm trên máy thật khi làm #17. |
| Phản hồi rung (haptic) thay cho âm thanh | Exemplary | Mọi cue chỉ có âm thanh | Ngoài phạm vi | Ghi vào Known Intentional Limitations. |

### Gameplay-Critical SFX Audit

> Chưa có âm thanh nào; bảng này liệt kê các âm thanh **dự kiến** từ vòng chơi hiện có và dấu hiệu hình ảnh đã có sẵn. Cập nhật khi thiết kế #17.

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| Tưới cây | Tưới thành công | Viền xanh dương trên ô | Không | Chưa có âm thanh |
| Thu hoạch | Thu được 1 cây | Số trong túi đồ tăng; thông báo | Không | Chưa có âm thanh |
| Bán hàng | Tiền tăng | Nhãn tiền trên HUD; thông báo | Không | Chưa có âm thanh |
| Nộp nhờ vả, mở khoá | Hoàn thành nhờ vả, nhận thưởng | Lời xong và thưởng trong bảng hàng xóm | Không | Chưa có âm thanh |
| Dựng làng | Một mảnh làng được dựng | Hiệu ứng dựng lại; thông báo | Không | Chưa có âm thanh |
| Sang ngày hoặc mùa | Ngày mới, đổi mùa | Nhãn ngày, mùa; thông báo | Không | Chưa có âm thanh |
| Thao tác thất bại | Không làm được | Thông báo nêu lý do | Không | Chưa có âm thanh |
| Cá cắn (câu cá, #12) | Phải kéo trong cửa sổ thời gian | Chưa thiết kế: **bắt buộc** có dấu hiệu hình ảnh, và có hệ số kéo dài (xem Motor) | Cần quyết trong GDD câu cá | Chưa thiết kế |
| Nhạc nền, tiếng ve, gà gáy | Không khí | Không cần (không mang thông tin) | Không | Chưa có âm thanh |

---

## Platform Accessibility API Integration

> Nền tảng mục tiêu chỉ là iOS và Android (`technical-preferences.md`). Dự án chưa có `export_presets.cfg`, nên chưa có bản xuất Android hay iOS để thử.
>
> **Nguồn duy nhất về trợ năng của engine** là `docs/engine-reference/godot/`: từ Godot 4.5, các node `Control` tích hợp với công cụ trợ năng qua AccessKit; ở 4.7, `Control.accessibility_live` có kiểu `AccessibilityServer.AccessibilityLiveMode` (enum đã chuyển từ `DisplayServer`). Tài liệu không nói gì thêm. Mọi ô ghi `NOT SOURCEABLE` bên dưới là chỗ tài liệu engine không nêu, và không được điền từ trí nhớ.

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| Android | AccessibilityService / TalkBack | Đọc màn hình cho HUD và các bảng (chưa cam kết) | Ngoài phạm vi; NOT SOURCEABLE | Tài liệu engine không nêu AccessKit có chạy trên Android hay không. Toàn bộ thế giới game (ruộng, quầy chợ, hàng xóm, làng, nhân vật) là `Node2D` tự vẽ bằng `_draw()`, không phải `Control`, nên dù AccessKit chạy, người dùng đọc màn hình vẫn không tiếp cận được vòng chơi chính (chạm ô ruộng) nếu không có lớp `Control` thay thế. Chỉ HUD và các bảng là `Control`. |
| iOS | UIAccessibility / VoiceOver | Đọc màn hình cho HUD và các bảng (chưa cam kết) | Ngoài phạm vi; NOT SOURCEABLE | Cùng giới hạn như Android: tài liệu engine không nêu hỗ trợ iOS. |
| Windows (NVDA, Narrator) | Trình đọc màn hình trên PC | Không có | Không áp dụng | Windows chỉ là nền phát triển, không phải nền phát hành. |
| Xbox, PlayStation 5, Steam | XAG, hướng dẫn của Sony, Steam Input | Không có | Không áp dụng | Không phải nền tảng mục tiêu. |

### Quy tắc sẵn sàng (áp dụng ngay)

Đọc màn hình đang ngoài phạm vi (xem Accessibility Tier Definition), nhưng các quy tắc rẻ sau giữ khả năng làm sau:

1. Mọi `Control` mới có chữ đọc được (`Button` và `Label` có `text`); không dùng biểu tượng trần không nhãn.
2. Thông tin quan trọng không chỉ nằm trong `_draw()`: mỗi trạng thái cần biết có bản chữ tương đương ở một `Control` (túi đồ, Sổ nhờ vả, thông báo).
3. Thông báo động trên HUD (`Label`) là ứng viên cho `Control.accessibility_live`. Nếu dùng, dùng kiểu `AccessibilityServer.AccessibilityLiveMode` (không dùng `DisplayServer.AccessibilityLiveMode`, enum cũ đã chuyển ở 4.7). Các giá trị của enum, và cách đặt tên và mô tả cho từng `Control`: NOT SOURCEABLE.

### Điều kiện xem lại

Khi có bản xuất Android (`export_presets.cfg`), thử TalkBack trên HUD và các bảng, ghi kết quả vào Audit History, rồi mới quyết định giữ ngoài phạm vi hay cam kết "HUD và bảng đọc được". Chừng nào các ô NOT SOURCEABLE còn đó, dự án **không được tuyên bố** hỗ trợ đọc màn hình.

---

## Per-Feature Accessibility Matrix

> Mỗi khi thêm hệ thống vào `systems-index.md`, phải thêm một hàng ở đây. Hệ thống còn mối lo trợ năng chưa xử lý thì không được đánh dấu Approved trong systems index. Cột Addressed dùng: Partial (đã xử lý một phần), Not Started. Hiện chưa hệ thống nào ở mức đầy đủ, và systems index cũng chưa có hệ thống nào Approved (0/17).
>
> Hàng ghi "(dự kiến)" thuộc hệ thống chưa có GDD: mối lo suy ra từ ý định, không phải từ thiết kế đã duyệt.

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| #1 Dữ liệu cây trồng (chưa có GDD) | Loại cây chỉ khác nhau bằng màu (`crops.json`: `#5fbf4a`, `#e0463a`, `#f0c93c`) | Không | 3 cây | Không | Not Started | Cần thêm trường hình dạng hoặc nhãn ngắn (Cải, Cà, Ngô) vào dữ liệu để hỗ trợ mù màu. |
| #2 Thời gian | Nhãn ngày, giai đoạn, mùa là chữ 36 px (đạt) | Đồng hồ 90 giây một ngày là thao tác định giờ duy nhất | Áp lực thời gian nhẹ; đồng hồ vẫn chạy khi mở bảng | Không | Not Started | Cần: Tốc độ ngày (Bình thường, Chậm, Dừng) và tạm dừng khi mở bảng. Xem Motor. |
| #3 Ruộng | Loại cây chỉ bằng màu; ô đã tưới, ô héo cần kiểm bằng mô phỏng mù màu | 20 ô, mỗi ô tới 4 lần chạm (cuốc, gieo, tưới, thu hoạch): lặp nhiều; ô 80 px đạt | 4 công cụ, 3 cây, 20 ô cùng lúc | Không | Partial | Đạt: viền ô đã tưới, vòng ô chín. Chưa: hình dạng riêng cho cây, hình riêng cho cây héo. Số lần chạm lặp chưa có biện pháp giảm. |
| #4 Nhân vật và điều khiển chạm | Nhân vật là vòng tròn cam, có thể che ô | Một lần chạm đủ (đạt); chạm thừa thay việc đang chờ | Nhịp "đi rồi mới làm" | Không | Partial | Rủi ro chạm thừa ghi ở Open Questions. |
| #5 Chợ và tiền | Chữ 24 px (đạt); tương phản chưa đo | Nút ≥72×72 (đạt); chọn số lượng bằng [-] và [+], nhiều lần chạm | Túi trống có dòng báo; số lượng và giá | Không | Partial | Nút "Tối đa" (ý định đã xác nhận, chưa cài) giảm số lần chạm. |
| #6 Hàng xóm và nhờ vả | Lời tối đa 120 ký tự; bảng rộng cố định 720 px, cần kiểm ở cỡ chữ 150% | Nút "Nộp" ≥72 (đạt) | Phải đi tới hàng xóm mới xem được nhờ vả; lời không tự tắt (đạt) | Không | Partial | Cần Sổ nhờ vả (xem Cognitive). |
| #7 Làng hồi sinh | Màu phủ theo mức; hiệu ứng dựng 1 giây, độ sáng 0,45, một lần mỗi mảnh | Không | Thông báo "Làng đã dựng lại thêm X" chỉ 2,5 giây | Không | Partial | `reduce_motion` đã có trong `VillageView`, chưa nối vào tuỳ chọn nào. Mức làng đã có dự phòng không phải màu. |
| #8 Lưu và tải | Không | Không (tự lưu, không cần thao tác) | Thông báo lỗi đọc file lưu chỉ 2,5 giây | Không | Partial | Thông báo lỗi đọc file nên giữ lâu hơn (Open Questions). |
| #9 HUD và các bảng (chưa có GDD) | Chữ cố định, chưa chỉnh cỡ; tương phản chưa đo; kiểu "đang chọn" của nút theo theme, chưa kiểm | Nút HUD ≥120×72, nút bảng ≥72×72 (đạt) | Ít nhất 7 mục cùng lúc; chưa có nút Tạm dừng, Sổ nhờ vả; thông báo 2,5 giây, ghi đè nhau | Không | Partial | Các yêu cầu mới (Tạm dừng, Sổ nhờ vả, thông báo xếp hàng, chỉnh cỡ chữ) phải vào GDD của hệ thống này. |
| #10 Hiển thị cho điện thoại (chưa có GDD) | Kéo giãn `canvas_items` và `expand`; vùng an toàn của màn hình (khuyết, bo góc) chưa kiểm | Kích thước vùng chạm thực tế phụ thuộc kích thước máy | Không | Không | Not Started | Cần thử trên máy thật (Test Plan). Quy đổi dp xem Motor. |
| #11 Cốt truyện và sự kiện (dự kiến) | Hiệu ứng lễ hội: không quá 3 chớp mỗi giây, tôn trọng giảm chuyển động | Không | Lời thoại giữ ngắn (khoảng 120 ký tự mỗi đoạn) | Nếu có giọng đọc thì phải có phụ đề 100% | Not Started | |
| #12 Câu cá (dự kiến) | Dấu hiệu cá cắn không chỉ bằng màu | Cửa sổ phản xạ: cần hệ số kéo dài 0,5x đến 3,0x hoặc chế độ chạm một lần không định giờ | Quy tắc mới, cần Hướng dẫn xem lại | Tiếng cá cắn không được là kênh duy nhất | Not Started | Rủi ro lớn nhất về vận động trong các hệ thống sắp làm. |
| #13 Nấu ăn và bảo quản (dự kiến) | Công thức, nguyên liệu không chỉ phân biệt bằng màu | Một chạm cho mỗi bước; không giữ để làm | Nhiều nguyên liệu và công thức: trên 4 thứ phải theo dõi là dấu hiệu cần xem lại | Không | Not Started | |
| #14 Màn bắt đầu và chọn nhân vật (dự kiến) | Chọn dáng Mận không chỉ bằng màu | Nút ≥72 | Rõ ràng giữa "game mới" và "tiếp tục" | Không | Not Started | |
| #15 Tuỳ chọn trợ năng (dự kiến) | Chứa: cỡ chữ 100%, 125%, 150%; Nhãn cây | Chứa: Tốc độ ngày | Chứa: Hướng dẫn xem lại | Chứa: 3 thanh âm lượng | Not Started | Là nơi hiện thực các thiết lập trên, cùng giảm chuyển động. Nơi lưu thiết lập chưa quyết (Open Questions). Bản thân màn này cũng phải theo mọi quy tắc ở trên. |
| #16 Gà vịt, mương, chợ hồi sinh (dự kiến) | Vật nuôi chuyển động nhiều: tôn trọng giảm chuyển động | Chăm sóc lặp lại hằng ngày | Thêm việc mỗi ngày làm tăng số thứ phải theo dõi | Tiếng vật nuôi không được là kênh duy nhất | Not Started | |
| #17 Âm thanh (dự kiến) | Không | Không | Không | 3 thanh âm lượng; chơi được khi tắt tiếng; xử lý chế độ im lặng của điện thoại: NOT SOURCEABLE | Not Started | Yêu cầu nằm ở mục Auditory. |

---

## Accessibility Test Plan

> Ba loại kiểm: **tự động** (gdUnit4 hoặc script, chạy trong CI), **thủ công nội bộ** (mô phỏng, có ảnh chụp giữ lại trong `production/qa/evidence/`) và **máy thật / người dùng thật**.
>
> Hiện chưa chạy được gì: **gdUnit4 chưa cài** (`addons/gdUnit4/` chưa có) và **chưa có bản xuất Android** (`export_presets.cfg` chưa có). Trạng thái ghi rõ điều đang chặn từng hàng.
>
> Cột Responsible: vai trò theo mẫu; mọi thử nghiệm cần máy thật hoặc người thật do To Truong chịu trách nhiệm.

### Kiểm tự động

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Cỡ chữ tối thiểu | gdUnit4: duyệt cây node của HUD và các bảng | Mọi `Label` và `Button` ở mỗi bảng | Không có chữ nhỏ hơn 24 px ở khung nhìn gốc (đồng hồ 36 px) | qa-tester | Not Started (cần gdUnit4) |
| Vùng chạm tối thiểu | gdUnit4: đọc kích thước tối thiểu của điều khiển | Mọi nút HUD và bảng; ô ruộng, quầy chợ, hàng xóm | Nút ≥72×72 (nút HUD ≥120×72); các vùng chạm trên bản đồ ≥72 | qa-tester | Not Started (cần gdUnit4) |
| Tương phản chữ | Script đọc màu chữ và màu nền từ theme và các hằng số, tính tỷ lệ (cách làm cần xác nhận chạy được không cần màn hình) | Mọi cặp chữ và nền ở mỗi bảng | Chữ thường ≥4,5:1; chữ lớn ≥3:1. Chữ HUD nằm trên bản đồ (có viền đen) kiểm thủ công | ux-designer | Not Started |
| Tương phản cây so với nền ô | Script tính tỷ lệ giữa màu cây và màu nền ô | 3 cây × các trạng thái nền (đã cuốc, đã tưới) | Hình cây ≥3:1 so với nền; mỗi cặp cây khác nhau về hình dạng | ux-designer | Not Started |
| Tốc độ ngày và tạm dừng | gdUnit4 trên đồng hồ ngày | Ba mức tốc độ; mức Dừng không qua ngày khi tích luỹ nhiều giây; đồng hồ không tiến khi bảng mở | Độ dài ngày đúng hệ số; Dừng: số ngày không đổi cho tới khi "Đi ngủ" | qa-tester | Not Started (tính năng chưa làm) |
| Thông báo xếp hàng | gdUnit4 trên hàng đợi thông báo | Hai tin liên tiếp (sang mùa rồi sang ngày) | Không tin nào bị ghi đè; tin quan trọng hiện ≥5 giây | qa-tester | Not Started (tính năng chưa làm) |
| Giảm chuyển động | gdUnit4 trên `VillageView.reduce_motion` | Bật cờ rồi dựng một mảnh làng | Thay đổi tức thời, không hiệu ứng (tiêu chí 6 của GDD làng) | qa-tester | Not Started (cần gdUnit4; cờ đã có trong mã) |

### Kiểm thủ công nội bộ

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Mù màu | Ảnh chụp ô ruộng qua công cụ mô phỏng mù màu (như Coblis) cho đỏ-xanh lục, xanh lục-đỏ, xanh dương-vàng; lưu ảnh vào `production/qa/evidence/` | Ô trống, đã cuốc, đã tưới, mỗi cây đã gieo, cây chín, cây héo | Phân biệt được loại cây và trạng thái chỉ bằng hình dạng; không mất thông tin nào | ux-designer | Not Started (cần hình dạng riêng cho cây) |
| Cỡ chữ 100%, 125%, 150% | Chạy mọi bảng ở ba mức | HUD, bảng chợ, bảng hàng xóm (rộng cố định 720 px), bảng món ăn | Không chữ nào tràn hay bị cắt; nút vẫn ≥72×72 | ux-designer | Not Started (tính năng chưa làm) |
| Chơi bằng một ngón | Chơi vòng đầy đủ: cuốc, gieo, tưới, thu hoạch, bán, nộp nhờ vả | Một ngón của một tay, không giữ, không kéo | Hoàn thành mọi bước | qa-tester | Not Started |
| Chạm thừa khi đang đi | Chạm lần hai trong lúc nhân vật đang đi | Chạm cùng ô, chạm ô khác, chạm HUD | Ghi lại hành vi thật; kết quả đưa vào quyết định ở Open Questions | qa-tester | Not Started |
| Tắt tiếng và âm lượng | Thủ công khi có Âm thanh (#17) | Tắt từng thanh; chơi hoàn toàn khi tắt tiếng | Không mất thông tin hay tiến độ nào | qa-tester | Not Started (chưa có âm thanh) |

### Kiểm trên máy thật

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Kích thước vùng chạm thực tế | Đo kích thước vật lý của nút và ô trên ít nhất 2 máy khác cỡ (cạnh ngắn khoảng 360 dp và khoảng 412 dp) | Nút HUD, nút bảng, ô ruộng | Đạt 48 dp theo hướng dẫn thường gặp của Android (không có trong tài liệu dự án, cần xác nhận); nếu không đạt thì nâng mức tối thiểu lên 88 px | To Truong | Not Started (cần bản xuất Android) |
| Vùng an toàn của màn hình | Chạy trên máy có khuyết hoặc bo góc | HUD ở các góc | Không điều khiển nào bị che | To Truong | Not Started (cần bản xuất Android) |
| Đọc màn hình (thăm dò) | Bật TalkBack, duyệt HUD và các bảng | Mọi nút, nhãn; thông báo | Ghi kết quả; quyết định giữ ngoài phạm vi hay cam kết "HUD và bảng đọc được". Ngoài phạm vi ở mức Standard; NOT SOURCEABLE | To Truong | Not Started (cần bản xuất Android) |
| Chế độ im lặng và ngắt âm | Bật chế độ im lặng; gọi điện trong lúc chơi | Nhạc, hiệu ứng, môi trường | Không crash, không mất tiếng sau khi quay lại. NOT SOURCEABLE | To Truong | Not Started (cần #17 và bản xuất) |

### Kiểm với người dùng thật

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Người mù màu | Thử với ít nhất một người mù màu trước phát hành | Một phiên chơi đầy đủ | Hoàn thành mọi nội dung mà không phải hỏi về màu | To Truong | Chưa tìm người thử |
| Người hạn chế vận động | Thử với ít nhất một người dùng một tay hoặc hạn chế vận động trước phát hành | Một phiên chơi đầy đủ với Tốc độ ngày đã chỉnh | Hoàn thành mọi nội dung MVP trong khoảng thời gian chấp nhận được so với người không hạn chế | To Truong | Chưa tìm người thử |

---

## Known Intentional Limitations

> Mỗi dòng dưới đây là một rủi ro đã được chấp nhận có chủ ý, không phải sơ suất. Các mục ngoài phạm vi ở Accessibility Tier Definition, Motor, Cognitive, Auditory và Platform đều có mặt ở đây. Mục có mức "Standard (theo mẫu)" là chỗ dự án lệch khỏi Standard của mẫu và lý do.

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| Đọc màn hình (TalkBack, VoiceOver) cho menu và thế giới | Comprehensive | Ngoài phạm vi của một người làm game. Tài liệu engine không nêu AccessKit có chạy trên Android hay iOS (NOT SOURCEABLE). Thế giới game là `Node2D` tự vẽ bằng `_draw()`, không phải `Control`, nên dù AccessKit chạy, vòng chơi chính vẫn không tiếp cận được. | Người mù hoặc thị lực rất thấp không chơi được game. | Quy tắc sẵn sàng (Control mới có chữ đọc được; thông tin quan trọng có bản chữ). Thăm dò TalkBack trên HUD và bảng khi có bản xuất Android, rồi quyết định lại. |
| Âm thanh mono | Comprehensive | Game chưa có âm thanh; hệ thống Âm thanh (#17) ở giai đoạn Full Vision. | Người điếc một bên, khi âm thanh được thêm. | Âm thanh không bao giờ là kênh duy nhất; chơi được khi tắt tiếng. Xem lại khi thiết kế #17. |
| Chú thích cho âm thanh quan trọng | Comprehensive | Mọi sự kiện có tiếng đều đã có phản hồi hình ảnh. | Thấp hiện tại; sẽ tăng nếu thêm cue chỉ có âm thanh. | Quy tắc "âm thanh không là kênh duy nhất". Cá cắn (câu cá) bắt buộc có dấu hiệu hình ảnh. |
| Tuỳ biến phụ đề (phông, cỡ, màu, nền) | Comprehensive | Không có giọng đọc, nên chưa có phụ đề. | Không ảnh hưởng hiện tại. | Nếu thêm giọng đọc, phụ đề 100% là bắt buộc. |
| Chế độ tương phản cao | Comprehensive | Ngoài phạm vi Standard; cần thêm theme riêng. | Người thị lực yếu có thể khó đọc. | Mục tiêu tương phản ≥4,5:1 cho chữ, viền đen cho chữ HUD, chỉnh cỡ chữ 100% đến 150%. |
| Dời vị trí HUD | Comprehensive | Ngoài phạm vi Standard. | Người khó với tới một vùng của màn hình. | Mọi điều khiển một chạm, nút ≥72 px; nút Tạm dừng và Sổ nhờ vả trên HUD. |
| Ghi tải nhận thức theo hệ thống | Comprehensive | Ngoài phạm vi Standard. | HUD có ít nhất 7 mục cùng lúc; thêm hệ thống làm tăng tải. | Per-Feature Matrix có cột Cognitive cho từng hệ thống; trên 4 thứ phải theo dõi là dấu hiệu xem lại. |
| Phản hồi rung thay cho âm thanh | Exemplary | Ngoài phạm vi. | Người điếc, khi có cue chỉ âm thanh. | Không cue nào chỉ có âm thanh. |
| Kiểm toán trợ năng bên ngoài | Exemplary | Dự án một người, không có ngân sách. | Có thể bỏ sót lỗi mà kiểm nội bộ không thấy. | Test Plan: kiểm tự động, kiểm thủ công và thử nhỏ với người dùng thật trước phát hành. |
| Chế độ đổi bảng màu cho ba loại mù màu | Standard (theo mẫu) | Thay bằng hình dạng riêng cho từng cây và tuỳ chọn Nhãn cây; không đổi bảng màu. | Người vừa mù màu vừa thị lực thấp có thể khó thấy hình nhỏ. | Chọn màu cây cách xa nhau về độ sáng; kiểm bằng mô phỏng mù màu (Test Plan). |
| Tuỳ chọn độ khó | Standard (theo mẫu) | Game không có trạng thái thua; cây héo là rủi ro nhẹ có chủ ý (trụ cột "ấm áp, không áp lực"). | Người thấy việc tưới hằng ngày quá nặng không có nút giảm. | Tốc độ ngày (Bình thường, Chậm, Dừng). |
| Ánh xạ lại phím và chuyển phương thức nhập | Standard (theo mẫu) | Game chỉ cảm ứng; thay bằng quy tắc vùng chạm. Chưa tìm hiểu hỗ trợ công tắc hay tay cầm ngoài (tài liệu engine không nêu). | Người dùng thiết bị hỗ trợ ngoài (công tắc, tay cầm) có thể không chơi được. | Chưa có biện pháp; ghi vào Open Questions. |
| Chống chạm thừa khi nhân vật đang đi | Không thuộc mẫu | Giữ hành vi đã xác nhận trong GDD nhân vật: chạm lần hai thay việc đang chờ. | Người run tay hoặc lỡ chạm có thể huỷ việc đang định làm. | Kiểm bằng chơi thử (Test Plan); quyết định cuối ở Open Questions. |

---

## Audit History

> Trợ năng không được chứng nhận một lần rồi xong; mỗi lần kiểm thêm một dòng.

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| 2026-10-27 | Nội bộ: To Truong + ux-designer (phiên soạn tài liệu này) | Rà soát bằng đọc mã khi soạn yêu cầu; chưa chạy game, chưa đo, chưa thử trên máy thật | Mã hiện tại (`hud.gd`, các bảng, `farm_view.gd`, `main.gd`, `neighbors.json`, `crops.json`) so với mức Standard đã cam kết | Kiểm toán "màu là dấu hiệu duy nhất": 7 mục; 3 đạt, 2 cần kiểm bằng mô phỏng mù màu, 1 chưa kiểm, 1 chưa làm (loại cây chỉ khác màu). Thông báo tự tắt 2,5 giây, theo đọc mã có ghi đè nhau. Chưa có nút Tạm dừng, Sổ nhờ vả, chỉnh cỡ chữ, tốc độ ngày. Vùng chạm ≥72 px trong mã nhưng chưa quy đổi trên máy thật. Tương phản chưa đo. | Mở: chưa kiểm trên máy thật |

---

## External Resources

> URL lấy từ mẫu của studio, chưa kiểm còn truy cập được.

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 (Web Content Accessibility Guidelines) | https://www.w3.org/TR/WCAG21/ | Nền tảng: tỷ lệ tương phản, cỡ chữ, yêu cầu nhập liệu |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Danh sách kiểm riêng cho game, chia theo hạng mục và chi phí |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | Dịch vụ thử nghiệm với người chơi có khuyết tật (hàng người dùng thật trong Test Plan) |
| Colour Blindness Simulator (Coblis) | https://www.color-blindness.com/coblis-color-blindness-simulator/ | Công cụ mô phỏng mù màu trên ảnh chụp (Test Plan) |
| Accessible Games Database | https://accessible.games | Ví dụ và nghiên cứu về thiết kế game dễ tiếp cận |
| Trợ năng trong Godot 4.7 | `docs/engine-reference/godot/` (VERSION.md, current-best-practices.md, breaking-changes.md, modules/ui.md) | Nguồn duy nhất dự án có về AccessKit; không nêu hỗ trợ Android hay iOS |
| Hướng dẫn kích thước vùng chạm của Android và iOS | NOT SOURCEABLE | Mốc 48 dp / 44 pt trong mục Motor không có trong tài liệu dự án; tìm tài liệu chính thức và dán URL vào đây |
| Cách Godot 4.7 xử lý chế độ im lặng và ngắt âm của điện thoại | NOT SOURCEABLE | `modules/audio.md` không nêu; tìm nguồn khi làm hệ thống Âm thanh (#17) |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Chạm lần hai khi nhân vật đang đi thay việc đang chờ: giữ nguyên, hay thêm hàng đợi việc hoặc lọc chạm thừa? | To Truong | Sau lần chơi thử đầu trên máy thật | Chưa quyết; hiện giữ nguyên |
| Tin "Không đọc được file lưu, bắt đầu game mới" có nên phải bấm mới đóng, thay vì tự tắt sau 5 giây? | To Truong | Khi viết GDD HUD (#9) | Chưa quyết |
| Thông báo sang mùa có thật sự bị thông báo ngày ghi đè? (suy ra từ đọc mã, chưa chạy game) | qa-tester | Khi sửa thông báo xếp hàng | Chưa kiểm |
| Thiết lập trợ năng (cỡ chữ, tốc độ ngày, âm lượng, giảm chuyển động, Nhãn cây) lưu ở đâu: thêm phần vào bản lưu (ADR-0001: mỗi phần mới phải nâng `FORMAT_VERSION`) hay một file riêng? | To Truong | Trước khi làm Tuỳ chọn trợ năng (#15) | Chưa quyết |
| Các yêu cầu mới của HUD (Tạm dừng, Sổ nhờ vả, thông báo xếp hàng, chỉnh cỡ chữ) chưa có GDD để chứa: viết GDD HUD (#9) khi nào? | To Truong | Trước `/design-system` cho HUD | Chưa quyết |
| Ruộng cần tới 4 lần chạm mỗi ô (cuốc, gieo, tưới, thu hoạch): có cần giảm số lần chạm không? | To Truong | Khi sửa GDD ruộng | Chưa quyết |
| Hình dạng riêng cho từng cây và cho cây héo: hình cụ thể là gì? (chưa có art bible) | To Truong | Trước khi thay khối màu bằng nghệ thuật thật | Chưa quyết |
| Vùng an toàn của màn hình (khuyết, bo góc) có che HUD không? Tài liệu engine không nêu. | To Truong | Khi có bản xuất Android | Chưa kiểm |
| Quy đổi vùng chạm sang dp và mốc 48 dp: xác nhận nguồn chính thức; nếu thiếu thì nâng lên 88 px. | To Truong | Khi có bản xuất Android | Chưa kiểm |
| AccessKit trong Godot 4.7 có chạy trên Android và iOS không? (NOT SOURCEABLE) | To Truong | Khi có bản xuất Android | Chưa kiểm |
| Chế độ im lặng và ngắt âm của điện thoại có hoạt động đúng trong Godot 4.7 không? (NOT SOURCEABLE) | To Truong | Khi làm hệ thống Âm thanh (#17) | Chưa kiểm |
| Có cần hỗ trợ thiết bị ngoài (công tắc, tay cầm) không? Chưa tìm hiểu. | To Truong | Trước phát hành | Chưa quyết |
| Cách tính tương phản bằng script không cần màn hình có chạy được trong Godot 4.7 không? | qa-tester | Khi cài gdUnit4 | Chưa kiểm |
| Mức Standard có phù hợp với người chơi thật không? Đối tượng chi tiết chưa xác định (INTENT UNKNOWN trong game-concept). | To Truong | Sau thử nghiệm với người dùng thật | Chưa quyết |
