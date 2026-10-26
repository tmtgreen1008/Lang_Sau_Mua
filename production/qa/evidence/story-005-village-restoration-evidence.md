# Test Evidence: Làng hồi sinh hiển thị

> **Story**: `production/epics/lang-sau-mua/story-005-village-restoration.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-10-26
> **Tester**: Claude (screenshots driven by scratch scripts through the real main scene); lead sign-off by the developer
> **Build / Commit**: working tree on top of `53ad0b5`

---

## What Was Tested

The village starts devastated after the flood and one piece (3 houses, 3 road segments) is restored per completed neighbor request, across three appearance levels (hoang tàn / đang hồi sinh / sung túc). Screenshots were taken from the real `main.tscn` at 1152x648 (base), 1440x648 (wide) and 1152x864 (tall).

**Acceptance criteria covered**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6. AC-7 (smoothness on a mid-range phone) is not measured.

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | Làng bắt đầu ở trạng thái hoang tàn sau lũ: nhà hỏng, đường đứt, bùn đất. | PASS | `level1-0requests.png`: crooked roofless-looking houses, mud rings, puddles, gapped road, dull olive ground |
| AC-2 | Mỗi mốc tiến độ thay đổi diện mạo làng: dựng lại một ngôi nhà hoặc một đoạn đường. | PASS | `level2-2requests.png`: house 1 and road 1 restored, the rest still ruined |
| AC-3 | Thay đổi hiển thị rõ ràng ngay khi đạt mốc. | PASS (stills) / DEFERRED (feel) | `mid-effect-house2.png` shows the blend; the timing and pulse feel needs a human look in a real run |
| AC-4 | Có ít nhất 3 mức diện mạo của làng. | PASS | levels 1, 2, 3 in `level1-0requests.png`, `level2-2requests.png`, `level3-6requests.png` |
| AC-5 | Mốc và tài nguyên hình ảnh đọc từ dữ liệu, không hardcode. | PASS | `assets/data/village_restoration.json` |
| AC-6 | Màu sắc và không khí đúng định hướng: màu đất, lúa, nắng chiều, ấm áp. | PASS (placeholder) | warm earth tones and golden roofs at level 3; final art not made yet |
| AC-7 | Chạy mượt trên điện thoại tầm trung. | NOT MEASURED | only 6 pieces of 4 to 9 shapes each; not profiled on a phone |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `story-005-village-restoration/level1-0requests.png` | devastated village, 0 requests | AC-1, AC-4 |
| 2 | `story-005-village-restoration/level2-2requests.png` | house 1 and road 1 restored | AC-2, AC-4 |
| 3 | `story-005-village-restoration/level3-6requests.png` | fully restored village, brighter ground | AC-4, AC-6 |
| 4 | `story-005-village-restoration/mid-effect-house2.png` | a piece mid-blend (pale, pulsing) | AC-3 |
| 5 | `story-005-village-restoration/wide-level3.png`, `tall-level3.png` | layout at 1440x648 and 1152x864, no overlaps | AC-2 |

---

## Test Conditions

- **Game state at start**: fresh game, requests completed through the same hand-over call the neighbor panel uses
- **Platform / hardware**: Windows 10 desktop, Godot 4.7.2, windowed
- **Framerate during test**: not measured
- **Any special setup required**: scratch driver scripts outside the project

---

## Observations

- Pieces are drawn with flat shapes as placeholders; art style is still open.
- The level name (Hoang tàn / Đang hồi sinh / Sung túc) is stored but not shown to the player.
- The restoration effect waits until the neighbor panel closes, because the panel dims the map.

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | To Truong | 2026-10-26 | [x] Approved |

*Solo developer. The developer said in chat on 2026-10-26 that stories 0 to 5 work fine in play and asked Claude to tick this row for them; Claude made the edit at that request. AC-7 (smoothness on a mid-range phone) was not measured and stays open until an Android build is tested.*
