## Gate Check: Technical Setup → Pre-Production

**Date**: 2026-10-27
**Checked by**: gate-check skill
**Tier**: workflow `standard`, `qa.level: standard`, `review_mode: lean`, `team.size: individual`

### Verdict: FAIL

Cả hai director trả NOT READY; ba mục bắt buộc chưa có. Giai đoạn dự án không đổi.

### Required Artifacts: 6/10 có, 3 thiếu, 1 chưa xác định

Ở `standard`: ADR chỉ tính ADR nền tảng; art bible chỉ khi có story tài sản hình ảnh; traceability, trợ năng, mẫu tương tác, UX spec là khuyến nghị.

- [x] Engine chọn: Godot 4.7
- [ ] Cấu hình dự án có hiệu năng: engine và quy ước đặt tên có; `project.yaml` không có khối `performance`; `technical-preferences.md` còn `[TO BE CONFIGURED]`
- [?] Art bible (`design/art/art-bible.md`): chưa có. Chỉ bắt buộc nếu có story tài sản hình ảnh; story 005 là Visual/Feel nhưng chỉ dùng khối màu. MANUAL CHECK NEEDED
- [ ] ADR nền tảng: 1/3 (chỉ lưu/tải). Thiếu quản lý scene và kiến trúc sự kiện
- [x] Tài liệu engine tham chiếu
- [x] Thư mục test: `tests/unit/` có test, `tests/integration/` còn trống
- [x] `.github/workflows/tests.yml` có file (nhưng chưa chạy được trên CI, xem Recommendations)
- [x] Test mẫu: 8/8 đạt, exit 0 (chạy headless cục bộ ngày 2026-10-27)
- [ ] `docs/architecture/architecture.md`: chưa có
- [x] Đã chạy `/architecture-review` (báo cáo `full`, kết quả FAIL)

Khuyến nghị: traceability index có, yêu cầu trợ năng có (Standard), mẫu tương tác có; chưa có UX spec cho màn hình nào (CONCERNS).

### Quality Checks
- [ ] ADR chưa phủ rendering, input, quản lý trạng thái
- [ ] Ngân sách hiệu năng chưa đặt (quy ước đặt tên đã có)
- [ ] Các miền engine rủi ro HIGH chưa được xử lý trong tài liệu kiến trúc (không có tài liệu); báo cáo review đã nêu bước thời gian của đồng hồ không bị kẹp
- [ ] Ma trận truy vết còn khoảng trống nền tảng (5/28 yêu cầu được phủ)
- [x] Mức trợ năng đã chốt (Standard, điều chỉnh cho cảm ứng)
- [x] ADR có Engine Compatibility và GDD Requirements Addressed
- [x] Không ADR nào dùng API đã lỗi thời; ADR đúng phiên bản 4.7
- [x] Không có vòng phụ thuộc ADR (ghi chú: `NO_DEPS_SECTION: adr-0001`, chưa phân biệt "không có" với "chưa điền")

### Director Panel Assessment
- Technical Director: NOT READY. Thiếu `architecture.md` và hai ADR nền tảng; thiếu khối hiệu năng; CI chưa chạy được vì `addons/gdUnit4` chưa commit; rủi ro HIGH về bước thời gian của đồng hồ cần xử lý trong ADR.
- Producer: NOT READY. Phạm vi ổn, không story nào bị chặn (6/6 Complete); đầu ra bắt buộc của cổng còn thiếu. Ước lượng khoảng 3 đến 5 ngày tập trung, độ tin cậy thấp.
- Panel 2/4 (`workflow: standard`). Creative Director và Art Director chưa được hỏi; nâng `modes.rigor` lên `full` để đủ bốn.

### Blockers
1. Thiếu ADR nền tảng (quản lý scene, kiến trúc sự kiện). Review chia khoảng trống thành nối hệ thống qua `Main`, nạp dữ liệu từ JSON, đồng hồ và vòng đời ứng dụng. Chạy `/architecture-decision`.
2. Chưa có `docs/architecture/architecture.md`. Chạy `/create-architecture`.
3. Chưa có ngân sách hiệu năng trong `project.yaml`.
4. Ma trận truy vết còn khoảng trống nền tảng. Chạy lại `/architecture-review full` sau khi viết ADR.

### Recommendations
- Commit `addons/gdUnit4/` để CI chạy được (`version: installed`). Trước khi commit xem `project.godot`: bản đang sửa xoá `viewport_width=1152`, `viewport_height=648`, `handheld/orientation=0`; nghi editor bỏ vì bằng giá trị mặc định, chưa kiểm; quyết giữ hay khôi phục, vì liên quan khoá màn hình ngang. `.godot/global_script_class_cache.cfg` đổi nhiều do gdUnit4 đăng ký lớp; repo theo dõi file này có chủ ý.
- Log test có 10 dòng ERROR vô hại ("Couldn't open directory user://test_save_game/"): thêm kiểm `DirAccess.dir_exists_absolute` trong `_remove_test_dir`.
- Chưa có test tích hợp dù 3 story thuộc loại Integration.
- Chưa có UX spec cho màn hình nào.
- Độ bền lưu và nút Back của Android (phát hiện của chuyên gia engine): đưa vào ADR vòng đời.
- Thử xuất Android trên máy thật sớm (rủi ro hiển thị; cho số đo hiệu năng thật). Chưa có `export_presets.cfg`.
- Art bible: nếu coi story 005 là story tài sản hình ảnh thì chạy `/art-bible`.
- `control-manifest.md` chưa có; không thuộc cổng này, cần ADR Accepted.

### Chain-of-Verification
5 câu hỏi, 7 lần kiểm lại bằng công cụ; verdict không đổi (FAIL).

### Con đường ngắn nhất tới PASS
(1) Viết các ADR nền tảng và `architecture.md`; (2) đặt ngân sách hiệu năng; (3) commit gdUnit4 và có CI xanh; rồi chạy lại `/architecture-review full` và `/gate-check`.
