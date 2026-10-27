# Làng Sau Mưa: đề cương cốt truyện

> **Trạng thái:** bản nháp để duyệt (narrative-director soạn 2026-10-26, đã chỉnh theo quyết định của người làm game).
> **Không thay thế** `design/game-brief.md`: brief vẫn là bản ghi thiết kế của MVP. Đề cương này mô tả hướng mở rộng sau MVP.
> **Lời thoại mẫu** chỉ để thử giọng; mọi lời thoại cần người làm game đọc lại cho đúng chất quê.

## Quyết định bổ sung (2026-10-26)
- **Mốc làng:** đổi từ 0/2/4 thành **0/3/9** nhờ vả (tổng 12 nhờ vả).
- **Chỗ tiêu tiền:** thêm **mua hạt giống ở chợ** (và vật liệu dựng làng khi cần).
- **Sau lễ hội:** **chơi tự do tiếp**, không dừng ở cuối năm.
- **Độ nghiêm ngặt:** nâng `modes.rigor` lên **standard** (mỗi hệ thống mới có tài liệu thiết kế riêng).
- Còn mở: bí mật của Bà Tư (sợ quên) và Cô Sáu (con gái xa) đã đúng độ ấm chưa.

## Quyết định đã chốt
- Nhân vật chính là **người con về lại làng** sau trận lũ. Tên **Mận** (tên ở nhà, hợp cả hai giới). **Người chơi chọn giới tính**; lời thoại dùng cách xưng hô trung tính ("con").
- Giọng kể: **ấm áp, hài hước nhẹ** (hàng xóm trêu nhau).
- Không có phản diện; "đối thủ" là lũ và sự bỏ bê.
- Truyện **tuyến tính, không phân nhánh** (theo brief). Toàn bộ lời thoại và nhờ vả nằm trong file dữ liệu ngoài.
- **Phạm vi đợt đầu: màn 1 và màn 2**, với hai hệ thống mới là **câu cá** và **nấu ăn / bảo quản**. Gà vịt, mương và chợ hồi sinh để đợt sau (màn 3).

## 1. Tiền đề và nhân vật chính
- **Mận:** lớn lên ở làng, 18 tuổi lên thành phố học rồi đi làm văn phòng. Hứa "về sớm" mà đi 12 năm.
- **Vì sao đi:** ruộng nhà nhỏ, ba mẹ muốn con "đỡ khổ"; Mận cũng muốn tự thử sức.
- **Vì sao về:** lũ cuốn trôi gần hết nhà cửa trong làng. Mận bỏ việc về; còn mảnh ruộng phù sa của nhà và ba mẹ nhắn "con về giữ đất".
- **Chủ đề:** nhớ và quên (quên cách cuốc đất, quên công thức, quên con đường). Cái cần thắng là "quên và bỏ".
- **Trò đùa chạy suốt:** hàng xóm trêu Mận là "dân thành phố".
  - Màn 1, trêu: "Đi thành phố về mà cuốc đất cũng quên rồi hả con?"
  - Màn 2, Mận cãi lại: "Con nhớ rồi mà!"
  - Màn 3, đảo chiều: hàng xóm hỏi Mận mấy thứ "thành phố" mà họ mới học, và Mận trêu lại.

## 2. Ba màn, bám theo ba mức làng
Mỗi hàng xóm có chuỗi 4 nhờ vả (2 đã có trong `neighbors.json` + 2 mới), xếp theo mùa hạ, thu, hạ, thu. Hội làng rơi vào mùa thu.

| Màn | Mục tiêu | Nhờ vả | Nhịp cảm xúc | Kết màn |
|---|---|---|---|---|
| **1. Hoang tàn** (mùa hạ) | Dọn ruộng, trồng ngô, chứng minh mình còn nhớ nghề | R1 của cả ba (`ba_tu_1`, `chu_ba_1`, `co_sau_1`, có sẵn) | Lạc lõng, bị trêu, được đón về | Làng lên cấp "Đang hồi sinh", dựng xong đoạn đường đầu. Chiều xuống nghe tiếng gà gáy ngoài chợ. |
| **2. Đang hồi sinh** (thu, rồi hạ) | Tìm lại nếp sống: bếp, ao | R2 có sẵn (`ba_tu_2`, `chu_ba_2`, `co_sau_2`) và R3 mới (`ba_tu_3`, `chu_ba_3`, `co_sau_3`) | Hàng xóm mở lòng, lộ bí mật nhỏ, Mận cãi lại | Làng lên cấp "Sung túc", ngôi nhà thứ ba sáng đèn. Cả xóm ăn chung một bữa. |
| **3. Sung túc** (thu) | Chuẩn bị hội làng | R4 mới (`ba_tu_4`, `chu_ba_4`, `co_sau_4`) | Đảo chiều trò đùa, hoàn thành bí mật | Đoạn đường cuối nối ra sân hội, vào lễ hội. *(đợt sau)* |

## 3. Từng hàng xóm
- **Bà Tư, bếp và ký ức**
  - Muốn: nấu lại các món của chị Hai.
  - Bí mật: cuốn sổ công thức của chị Hai bị nước cuốn. Bà nhớ chỗ được chỗ quên, và giấu vì sợ mình đang quên dần.
  - Mở khoá: `ba_tu_3` (màn 2) mở nấu ăn và phơi. `ba_tu_4` (màn 3) mở muối dưa và làm mắm.
- **Chú Ba, ao cá, vật nuôi, sửa nhà**
  - Muốn: ao có cá lại.
  - Bí mật: ông khoe tài câu mà ao gần trống, và lén mua cá giống bằng tiền để dành.
  - Mở khoá: `chu_ba_3` (màn 2) mở câu cá. `chu_ba_4` (màn 3) mở gà vịt *(đợt sau)*.
- **Cô Sáu, chợ, đường, mương, buôn bán**
  - Muốn: chợ chiều đông trở lại như xưa.
  - Bí mật: con gái cô ở thành phố mấy năm chưa về. Cô mở hội để con có cớ về.
  - Mở khoá: `co_sau_3` (màn 2) mở mương *(đợt sau)*. `co_sau_4` (màn 3) mở chợ hồi sinh *(đợt sau)*.

## 4. Chung kết: "Hội cơm mới" (ngày cuối mùa thu)
Một màn kể tuyến tính, chạy một lần, sau đó chơi tự do tiếp. *(đợt sau)*
- Cây trồng nộp trong các nhờ vả R4; món ăn gồm 4 món có sẵn cộng món muối, mắm và món cá; đủ 3 nhà và 3 đoạn đường quanh sân hội.
- Bà Tư nấu đúng món chị Hai; Cô Sáu thấy con gái xuất hiện ở đầu đường; Mận được trêu lần cuối, lần này bằng lời khen.

**Mẫu giọng (để duyệt):**
- Bà Tư: "Đi thành phố về mà cuốc đất cũng quên rồi hả con? Cuốc kiểu đó là cuốc trúng chân mình đấy."
- Chú Ba: "Cá hả? Chú câu hồi sáng, to cỡ này nè. Thì... nó đang ở ao, chờ con ra bắt."
- Cô Sáu: "Ở thành phố mua rau bằng cái điện thoại, ở đây mua bằng cái miệng, con ạ."

## 5. Câu chuyện → hệ thống và dữ liệu
| Nhịp truyện | File | Dữ liệu hay mã mới |
|---|---|---|
| Lời thoại nhờ vả R3, R4 mới | `neighbors.json` | Chỉ dữ liệu |
| Mốc màn (đề xuất 0/3/9 thay cho 0/2/4) và `unlock_at` của 6 công trình | `village_restoration.json` | Chỉ dữ liệu |
| Khoá nhờ vả theo mức làng (`min_level`) để màn tuyến tính | `neighbors.json` + `neighbor_book.gd` | **Mã mới (nhỏ)** |
| Phần thưởng mở tính năng (`unlock_feature`) | `neighbors.json` | **Mã mới (nhỏ)** |
| Nộp cá, món ăn, đồ muối làm yêu cầu (hiện `require` chỉ nhận cây trồng) | `neighbors.json` | **Mã mới** |
| Màn mở đầu và cảnh lễ hội | `story_beats.json` (mới) | **Mã mới** (màn chữ đơn giản) |
| Câu cá (cửa sổ cá cắn) | `fish.json` (mới) | **Mã mới** *(đợt đầu)* |
| Nấu ăn, phơi, muối, mắm (thời gian theo ngày) | `cooking_recipes.json` (mới), `time_config.json` | **Mã mới** *(đợt đầu)* |
| Gà vịt | `livestock.json` (mới) | **Mã mới** *(đợt sau)* |
| Mương | `irrigation.json` (mới) | **Mã mới** *(đợt sau)* |
| Chợ hồi sinh, mặt hàng mới | file chợ mới | **Mã mới** *(đợt sau)* |
| Thêm cây và mùa | `crops.json`, `time_config.json` | Chỉ dữ liệu (mã mùa phải khớp giữa hai file) |

## 6. Câu hỏi còn mở và rủi ro
**Câu hỏi còn mở:**
1. Mốc làng: đổi 0/2/4 thành 0/3/9 (đủ 12 nhờ vả) hay giữ mốc cũ và để R3, R4 không tính vào tiến độ làng?
2. Tiền hiện chưa có chỗ tiêu. Có muốn thêm một chỗ tiêu (mua giống, vật liệu) không?
3. Sau lễ hội: chơi tự do tiếp hay dừng ở một năm như brief?
4. Bí mật của Bà Tư (sợ quên) và Cô Sáu (con gái xa) đã đúng độ ấm mong muốn chưa?

**Rủi ro:**
- **Phạm vi:** brief hiện loại trừ chăn nuôi và nấu ăn phức tạp, và game mới có 2 mùa. Cần cập nhật brief (hoặc nâng rigor lên `standard` và viết tài liệu thiết kế riêng cho từng hệ thống mới) trước khi làm.
- **Giọng thoại tiếng Việt:** phương ngữ, cách xưng hô và độ trêu cần người bản xứ đọc lại.
- **Dữ liệu hiện có:** `ba_tu_2` đòi cà chua vào mùa thu, mà cà chua chỉ trồng được mùa hạ. Người chơi phải để dành, và đó là lý do hợp lý để mở bảo quản; cần xác nhận đây là chủ ý.
- **Khối lượng:** nếu trễ, cắt từ cuối danh sách (màn 3, gà vịt, mương, chợ).
