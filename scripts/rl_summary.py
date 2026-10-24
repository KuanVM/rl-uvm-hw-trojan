#!/usr/bin/env python3
# =============================================================================
# LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
# 2026-10-24: Nhận thư mục hoặc mẫu *.csv và tự mở rộng (PowerShell trên Windows
#             không tự glob như bash). Bỏ qua file CSV rỗng/hỏng thay vì dừng.
# 2026-10-13: Tạo mới. Tổng hợp CSV của vòng lặp RL: theo từng policy, số test
#             tới lần chạm RB-01 đầu tiên (censored = NA nếu không chạm) và số
#             test chạm RB-01 trong ngân sách, qua các seed. Chỉ dùng thư viện chuẩn.
# =============================================================================
"""Dùng: python scripts/rl_summary.py results/rl
       python scripts/rl_summary.py "results/rl/*.csv"

Chỉ để kiểm tra vòng lặp với mục tiêu giả RB-01 — KHÔNG phải kết quả nghiên cứu.
"""
import csv
import glob
import os
import statistics
import sys
from collections import defaultdict


def expand(args):
    out = []
    for a in args:
        if os.path.isdir(a):
            out += sorted(glob.glob(os.path.join(a, "*.csv")))
        elif any(c in a for c in "*?["):
            out += sorted(glob.glob(a))
        else:
            out.append(a)
    return out


def main(paths):
    paths = expand(paths)
    if not paths:
        sys.exit("Không tìm thấy file CSV nào.")
    runs = defaultdict(dict)  # (method, reward_mode) -> seed -> (first_hit, n_hit, n_tests, arm_counts)
    for p in paths:
        try:
            with open(p, newline="", encoding="utf-8") as f:
                rows = list(csv.DictReader(f))
        except OSError as e:
            print(f"Bỏ qua {p}: {e}")
            continue
        if not rows or "rb01_hit" not in rows[0]:
            print(f"Bỏ qua {p}: rỗng hoặc không đúng định dạng")
            continue
        key = (rows[0]["method"], rows[0]["reward_mode"])
        seed = rows[0]["seed"]
        first = next((int(r["test_id"]) for r in rows if r["rb01_hit"] == "1"), None)
        n_hit = sum(r["rb01_hit"] == "1" for r in rows)
        arms = defaultdict(int)
        for r in rows:
            arms[r["arm_name"]] += 1
        runs[key][seed] = (first, n_hit, len(rows), arms)

    for (method, reward), seeds in sorted(runs.items()):
        firsts = [v[0] for v in seeds.values()]
        hit_firsts = [x for x in firsts if x is not None]
        n_hits = [v[1] for v in seeds.values()]
        budget = max(v[2] for v in seeds.values())
        print(f"== {method} / reward={reward}: {len(seeds)} seed, B={budget}")
        print(f"   first_hit_test theo seed: {[('NA' if x is None else x) for x in firsts]}")
        if hit_firsts:
            print(f"   median first_hit (chỉ seed có chạm): {statistics.median(hit_firsts)}"
                  f"  | seed không chạm (censored): {firsts.count(None)}")
        print(f"   số test chạm RB-01 / B: mean={statistics.mean(n_hits):.1f}"
              f"  min={min(n_hits)}  max={max(n_hits)}")
        tot = defaultdict(int)
        for v in seeds.values():
            for a, c in v[3].items():
                tot[a] += c
        share = ", ".join(f"{a}:{c}" for a, c in sorted(tot.items()))
        print(f"   số lần chọn mỗi tay (cộng mọi seed): {share}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
