// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Tạo mới. Logger CSV tổng quát: một dòng mỗi test, header lấy từ
//             danh sách cột, flush sau mỗi dòng để log còn nguyên nếu mô phỏng
//             bị dừng giữa chừng (watchdog, $finish).
// =============================================================================
//
// Không phụ thuộc FIFO. Test tự lắp danh sách giá trị theo đúng thứ tự cột.
// Giá trị không xảy ra ghi "NA" (protocol §11), không ghi 0.

class rl_csv_logger;
  protected int    fd = 0;
  protected int    n_cols = 0;
  string           path;

  function bit open(string p, string cols[$]);
    path = p;
    fd   = $fopen(p, "w");
    if (fd == 0) return 0;
    n_cols = cols.size();
    $fdisplay(fd, join_csv(cols));
    $fflush(fd);
    return 1;
  endfunction

  function void write_row(string vals[$]);
    if (fd == 0) return;
    if (vals.size() != n_cols)
      $display("[rl_csv_logger] CẢNH BÁO: %0d giá trị nhưng header có %0d cột", vals.size(), n_cols);
    $fdisplay(fd, join_csv(vals));
    $fflush(fd);
  endfunction

  function void close();
    if (fd != 0) $fclose(fd);
    fd = 0;
  endfunction

  static function string join_csv(string v[$]);
    string s;
    s = "";
    foreach (v[i]) s = (i == 0) ? v[i] : {s, ",", v[i]};
    return s;
  endfunction
endclass : rl_csv_logger
