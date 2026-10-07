# Phản hồi nhận xét của thầy (23/09/2026): RL-UVM phát hiện Hardware Trojan

> **Ngày:** 25/09/2026  
> **Kèm theo:** `01_scope_threat_model.md` v0.2, `02_literature_review.md` v0.2, `03_experiment_protocol.md` v0.2, `04_lab_notebook.md`, `FIFO_VERIFICATION_PLAN.md` v1.1

## Lịch sử thay đổi

| Ngày | Thay đổi |
|---|---|
| 25/09/2026 | Tạo mới: phản hồi từng ý nhận xét ngày 23/09/2026 |

---

## 1. Tóm tắt

Nhóm em nhận mục tiêu **Q2** làm đích chính. Các hạng mục Q1 được đặt sau cổng G4 và chỉ làm nếu pilot sớm cho thấy RL có tín hiệu.

Khi kiểm tra các tài liệu thầy nêu, em phát hiện thêm ba điểm làm thay đổi thiết kế:

1. **Krieg (ICCAD 2023)** phân tích 83 benchmark Trust-Hub và chỉ đánh giá 3 thiết kế là Trojan hiệu quả: BasicRSA-T100, memctrl-T100, wb_conmax-T300. Vì vậy danh sách benchmark thầy gợi ý cần thêm bước sàng lọc có công bố:
   - Host UART của RS232 bản RTL không gửi được dữ liệu, tức là bản sạch cũng sai spec.
   - Trigger của PIC16F84 dùng logic nhạy mức nên mất sau tổng hợp.
2. **"Gadde et al."** là arXiv:2405.19815, đăng tại SMACD 2024. Bài này đã làm RL không phụ thuộc thiết kế, nối RL với mô phỏng qua DPI-C và dùng reward theo code coverage. Nhóm em bỏ hai ý định claim là mới: vòng DPI-C coverage→reward, và RL không phụ thuộc thiết kế. Bài này còn cho thấy trên FIFO, RL không hơn random về code coverage (23 so với 22–31 stimuli).
3. **DETERRENT (DAC 2022)** giả định có full scan với mạch tuần tự. Đây là khác biệt rõ nhất của đề tài: trigger tuần tự ở mức giao dịch UVM, không có scan. Tuy vậy, bài gần nhất cần đọc ngay là Dai & Yavuz (GLSVLSI 2024, trigger theo thời gian ở RTL) và Dai et al. (HOST 2025, đánh giá các phương pháp phát hiện HT ở RTL).

---

## 2. Phản hồi từng ý

| # | Ý của thầy | Nhóm em điều chỉnh | Căn cứ | Sửa ở đâu | Trạng thái |
|---|---|---|---|---|---|
| 1 | FIFO làm MVP được; AES-T\* không hợp | FIFO chỉ là host MVP và host cho Trojan sinh tự động. AES bị loại khỏi metric chính; AES-T2300–T2800 chỉ có thể làm nhóm đối chứng dễ | Nhận xét thầy; Krieg 2023 | 01 §3.1, §3.5 | Đã sửa |
| 2 | Dùng nhiều DUT bên thứ ba; công bố tiêu chí lọc | Hai tầng benchmark. **Tầng A:** Trust-Hub qua 7 bước sàng lọc S1–S7 (compile; host sạch đúng spec, sửa host thì áp cùng bản vá cho cả bản sạch và bản Trojan; kiểm C/M/S/P bằng Yosys; payload quan sát được ở giao diện; directed test chứng minh đạt được trigger; đo độ hiếm; quyết định kèm lý do). **Tầng B:** Trojan sinh tự động có tham số độ hiếm (ưu tiên DTjRTL, GLSVLSI 2024) | Krieg 2023; DTjRTL | 01 §3.2–3.4; 03 §5 | Chờ thầy duyệt |
| 3 | Không gian hành động A0–A6 riêng cho FIFO | Thay bằng các "núm chỉnh" dùng chung cho mọi DUT (tỉ lệ loại giao dịch, độ dài burst, khoảng nghỉ, chế độ dữ liệu, địa chỉ, reset, phát lại chuỗi). Các núm áp dụng được suy ra từ trường của transaction item. A0–A6 trở thành một bộ giá trị núm của FIFO. Công sức cho mỗi DUT được đo và báo cáo. Nhóm em **không** claim tầng núm là đóng góp, vì đã có tiền lệ (Huang et al., DVCon 2022; Gadde 2024) | Nhận xét thầy | 01 §9; FIFO §3.7 | Chờ thầy duyệt |
| 4 | Độ hiếm định nghĩa theo thực nghiệm, quét 10⁻³–10⁻⁶ | Độ hiếm p = xác suất kích hoạt trong một test dưới baseline π₀ đã đóng băng. Ngân sách mặc định B = 1.000 test: baseline đạt 63% ở 10⁻³, 10% ở 10⁻⁴, 1% ở 10⁻⁵, 0,1% ở 10⁻⁶. Mức quá hiếm để đo trực tiếp thì dùng cận trên "rule of three" và ngoại suy, có ghi nhãn rõ | Nhận xét thầy | 01 §5.3; 03 §6–7 | Chờ chốt N, B sau khi đo chi phí |
| 5 | Rò rỉ oracle qua rare-bin | Đăng ký trước (G0) cho từng DUT: spec → coverage và rare-bin → detector → núm → reward → kế hoạch phân tích. Mọi thứ được commit, gắn tag, ghi hash **trước** khi có Trojan. Tách vai: đội xanh không xem Trojan, đội đỏ lo Trojan và chạy test split. Thầy ký xác nhận. Có ablation β = 0. Thêm hai biện pháp: tách tập dev/test (không tinh chỉnh trên test) và sổ ghi các Trojan đội xanh đã lỡ đọc | Nhận xét thầy | 01 §6.5; 03 §4, §14–15; 04 §H–I | Cần phân vai |
| 6 | Payload đọc sai ngay khiến TTD ≈ TTA | Năm lớp payload: P0 sai ngay (chỉ làm đối chứng); P1 trễ D giao dịch; P2 hỏng dữ liệu lưu, chỉ lộ khi đọc lại và có thể bị che; P3 sai cờ full/empty; P4 DoS, cần bộ giám sát liveness. Scoreboard FIFO có thêm kiểm tra cờ (DET-SB-02). Báo cáo thêm tỉ lệ bị che | Nhận xét thầy | 01 §5.2, §7; FIFO §3.8 | Đã sửa |
| 7 | Sáu bài là quá ít | Mở rộng lên khoảng 40 công trình, chia 7 nhóm, mỗi mục ghi rõ mức đã kiểm chứng (đọc toàn văn / tóm tắt / chỉ qua trích dẫn) | Tìm kiếm ngày 25/09 | 02 §4 | Đang đọc tiếp |
| 8 | Rủi ro chỉ so với constrained-random | Baseline cho Q2: B0 constrained-random, B1 chọn núm ngẫu nhiên, B2 tối ưu hộp đen trên không gian núm, B3 fuzzing có hướng coverage (kiểu VGF). Cho Q1 thêm: B4 kiểu MERO, B5 chuyển thể TGRL/DETERRENT sang RTL | Bảng rủi ro của thầy | 01 §10; 03 §8 | Chờ thầy duyệt |
| 9 | RL có thể không có tín hiệu | Đưa pilot G2 lên sớm, chỉ chạy trên tập dev, với quy tắc đi tiếp hoặc chuyển hướng đăng ký trước. Nếu âm tính thì thử reward hộp xám một lần; vẫn âm thì chuyển claim sang "khi nào RL giúp được" | Bảng rủi ro của thầy | 01 §13; 03 §16 | Chờ thầy duyệt |
| 10 | Novelty mỏng; cần đóng góp cơ chế cho Q1 | Ứng viên: reward tiến độ cấu trúc hộp xám, trích tự động và áp đồng đều cho toàn thiết kế, không biết Trojan ở đâu (khoảng cách tới hằng số trong phép so sánh, tiến độ bộ đếm, trạng thái FSM mới). Phải chứng minh khác VGF, TGRL, DETERRENT, Dai & Yavuz | Nhận xét thầy | 01 §6.2, §9.3; 02 §7 | Giả thuyết, kiểm ở G2 |
| 11 | Thống kê: ≥10 seed, CI 95%, effect size | Giữ tối thiểu 10 seed. Nhóm em lưu ý: 10 lần chạy cho CI rất rộng (5/10 → 24–76%), nên phân tích chính gộp theo Trojan và mức hiếm (hồi quy logistic hiệu ứng hỗn hợp, "biên kích hoạt", RMST có kiểm duyệt). Chạy 30 seed khi đủ rẻ | Tính toán Wilson | 03 §12–13 | Đã sửa |

---

## 3. Câu hỏi xin thầy quyết định

1. **Benchmark tầng A.** Thầy có đồng ý dùng RS232-T100…T901 sau khi sửa host UART (cùng một bản vá cho bản sạch và bản Trojan, công bố diff), và coi PIC16F84 là tập phụ chỉ đúng trong mô phỏng RTL không ạ?
2. **Thiết lập hộp xám.** Bên kiểm chứng có RTL của IP bên thứ ba, nên thiết lập hộp xám là hợp lý. Thầy có chấp nhận đây là hướng cho đóng góp cơ chế Q1 không, nếu luôn báo cáo tách riêng khỏi thiết lập hộp đen ạ?
3. **Kiểm soát đăng ký trước.** Thầy có đồng ý làm người ký xác nhận G0 cho từng DUT không ạ?
4. **Tài nguyên.** Giấy phép Questa có hỗ trợ mô phỏng trộn VHDL (cho BasicRSA) và IEEE 1735 (mã hoá RTL Trojan) không ạ? Nếu không, nhóm em bỏ BasicRSA và để đội đỏ tự chạy toàn bộ test split.

---

## 4. Việc hai tuần tới

- [ ] Sửa `fifo_if.sv` (ISSUE-001, ISSUE-002), dựng skeleton UVM (M3), scoreboard theo §3.8 (M4).
- [ ] Phân vai đội xanh / đội đỏ; đội xanh chốt rare-bin và detector cho FIFO (M9 = G0).
- [ ] Đọc Dai et al. (HOST 2025) và Dai & Yavuz (GLSVLSI 2024); hỏi khả năng lấy tool DTjRTL.
- [ ] Đội đỏ chạy sàng lọc S1–S2 cho RS232, wb_conmax-T300, memctrl-T100.
- [ ] Đo chi phí một test trên FIFO để điền bảng tính toán tài nguyên (03 §17) trước khi chốt N và B.
