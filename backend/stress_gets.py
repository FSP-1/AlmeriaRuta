"""Simple GET stress test to simulate concurrent users.

Uses only the Python standard library (no extra deps).

Examples:
  python stress_gets.py --base-url http://127.0.0.1:5000 --duration 30 --concurrency 20
  python stress_gets.py --duration 60 --concurrency 50 --timeout 8

Targets (if available):
  GET /lines
  GET /lines/<line_id>/stops
  GET /lines/<line_id>/arrivals
  GET /stops/<stop_id>

It first fetches /lines once to discover lineIds and stopIds.
"""

from __future__ import annotations

import argparse
import json
import random
import threading
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple


@dataclass(frozen=True)
class Mix:
    lines: int
    line_stops: int
    line_arrivals: int
    stop_detail: int

    def total(self) -> int:
        return self.lines + self.line_stops + self.line_arrivals + self.stop_detail


@dataclass
class Stats:
    total: int = 0
    ok: int = 0
    non_200: int = 0
    errors: int = 0
    bytes: int = 0

    # Store a bounded sample of latencies to compute percentiles.
    latency_ms_sample: List[float] = None  # type: ignore[assignment]

    def __post_init__(self) -> None:
        if self.latency_ms_sample is None:
            self.latency_ms_sample = []


def _http_get(url: str, timeout_s: float) -> Tuple[int, bytes]:
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        body = resp.read()
        return int(getattr(resp, "status", 200)), body


def _percentile(sorted_values: List[float], p: float) -> Optional[float]:
    if not sorted_values:
        return None
    if p <= 0:
        return sorted_values[0]
    if p >= 100:
        return sorted_values[-1]
    k = (len(sorted_values) - 1) * (p / 100.0)
    f = int(k)
    c = min(f + 1, len(sorted_values) - 1)
    if f == c:
        return sorted_values[f]
    d0 = sorted_values[f] * (c - k)
    d1 = sorted_values[c] * (k - f)
    return d0 + d1


def _discover(base_url: str, timeout_s: float) -> Tuple[List[str], List[str]]:
    status, body = _http_get(f"{base_url}/lines", timeout_s=timeout_s)
    if status != 200:
        raise RuntimeError(f"GET /lines failed: {status}")

    data = json.loads(body.decode("utf-8"))
    if not isinstance(data, list):
        raise RuntimeError("GET /lines did not return a list")

    line_ids: List[str] = []
    stop_ids: List[str] = []

    for item in data:
        if not isinstance(item, dict):
            continue
        lid = str(item.get("id") or item.get("name") or "").strip()
        if lid:
            line_ids.append(lid)

        stops = item.get("stops")
        if isinstance(stops, list):
            for s in stops:
                if isinstance(s, dict):
                    sid = str(s.get("id") or "").strip()
                    if sid:
                        stop_ids.append(sid)

        routes = item.get("routes")
        if isinstance(routes, list):
            for r in routes:
                if not isinstance(r, dict):
                    continue
                r_stops = r.get("stops")
                if isinstance(r_stops, list):
                    for s in r_stops:
                        if isinstance(s, dict):
                            sid = str(s.get("id") or "").strip()
                            if sid:
                                stop_ids.append(sid)

    # Dedup + keep some randomness.
    line_ids = sorted(set(line_ids))
    stop_ids = sorted(set(stop_ids))
    return line_ids, stop_ids


def _pick_target(
    mix: Mix,
    base_url: str,
    line_ids: List[str],
    stop_ids: List[str],
) -> str:
    # Weighted choice.
    n = mix.total()
    r = random.randint(1, n)
    if r <= mix.lines:
        return f"{base_url}/lines"
    r -= mix.lines

    if r <= mix.line_stops:
        line_id = random.choice(line_ids) if line_ids else "L1"
        return f"{base_url}/lines/{line_id}/stops"
    r -= mix.line_stops

    if r <= mix.line_arrivals:
        line_id = random.choice(line_ids) if line_ids else "L1"
        return f"{base_url}/lines/{line_id}/arrivals"

    stop_id = random.choice(stop_ids) if stop_ids else "1"
    return f"{base_url}/stops/{stop_id}"


def run_stress(
    *,
    base_url: str,
    duration_s: int,
    concurrency: int,
    timeout_s: float,
    mix: Mix,
    sample_limit: int,
) -> int:
    base_url = base_url.rstrip("/")

    try:
        line_ids, stop_ids = _discover(base_url, timeout_s)
    except Exception as e:
        print(f"[discover] failed: {e}")
        print("Is the API running? Try: python almeria_busmaps_api.py")
        return 2

    print(f"[discover] lines={len(line_ids)} stops={len(stop_ids)}")

    stats = Stats()
    lock = threading.Lock()
    end_at = time.perf_counter() + duration_s

    def record(lat_ms: float, status: Optional[int], size: int, err: bool) -> None:
        with lock:
            stats.total += 1
            if err:
                stats.errors += 1
            else:
                if status == 200:
                    stats.ok += 1
                else:
                    stats.non_200 += 1
            stats.bytes += size
            if len(stats.latency_ms_sample) < sample_limit:
                stats.latency_ms_sample.append(lat_ms)
            else:
                # Reservoir sampling: replace randomly.
                j = random.randint(0, stats.total - 1)
                if j < sample_limit:
                    stats.latency_ms_sample[j] = lat_ms

    def worker() -> None:
        while True:
            now = time.perf_counter()
            if now >= end_at:
                return

            url = _pick_target(mix, base_url, line_ids, stop_ids)
            t0 = time.perf_counter()
            try:
                status, body = _http_get(url, timeout_s)
                lat_ms = (time.perf_counter() - t0) * 1000.0
                record(lat_ms, status=status, size=len(body), err=False)
            except urllib.error.HTTPError as e:
                lat_ms = (time.perf_counter() - t0) * 1000.0
                record(lat_ms, status=int(getattr(e, "code", 0)), size=0, err=False)
            except (urllib.error.URLError, TimeoutError, Exception):
                lat_ms = (time.perf_counter() - t0) * 1000.0
                record(lat_ms, status=None, size=0, err=True)

    threads = [threading.Thread(target=worker, daemon=True) for _ in range(concurrency)]

    print(
        f"[run] duration={duration_s}s concurrency={concurrency} timeout={timeout_s}s "
        f"mix=lines:{mix.lines},stops:{mix.line_stops},arrivals:{mix.line_arrivals},stop:{mix.stop_detail}"
    )

    t_start = time.perf_counter()
    for th in threads:
        th.start()
    for th in threads:
        th.join()
    t_total = max(time.perf_counter() - t_start, 1e-9)

    lat_sorted = sorted(stats.latency_ms_sample)
    p50 = _percentile(lat_sorted, 50)
    p95 = _percentile(lat_sorted, 95)
    p99 = _percentile(lat_sorted, 99)

    rps = stats.total / t_total
    mbps = (stats.bytes / (1024 * 1024)) / t_total

    print("\n[summary]")
    print(f"requests: total={stats.total} ok={stats.ok} non_200={stats.non_200} errors={stats.errors}")
    print(f"throughput: {rps:.1f} req/s, {mbps:.2f} MiB/s")
    print(
        "latency_ms(sample): "
        f"p50={p50:.1f} p95={p95:.1f} p99={p99:.1f} "
        f"(n={len(lat_sorted)} sample_limit={sample_limit})"
        if p50 is not None
        else "latency_ms(sample): n=0"
    )

    return 0


def _parse_mix(text: str) -> Mix:
    # format: lines,stops,arrivals,stop
    parts = [p.strip() for p in text.split(",")]
    if len(parts) != 4:
        raise argparse.ArgumentTypeError("--mix must be: lines,stops,arrivals,stop")
    try:
        vals = [max(int(p), 0) for p in parts]
    except ValueError as e:
        raise argparse.ArgumentTypeError(str(e)) from e
    if sum(vals) == 0:
        raise argparse.ArgumentTypeError("--mix total must be > 0")
    return Mix(lines=vals[0], line_stops=vals[1], line_arrivals=vals[2], stop_detail=vals[3])


def main() -> int:
    parser = argparse.ArgumentParser(description="GET stress test (simulate concurrent users)")
    parser.add_argument("--base-url", default="http://127.0.0.1:5000", help="API base URL")
    parser.add_argument("--duration", type=int, default=30, help="Duration in seconds")
    parser.add_argument("--concurrency", type=int, default=20, help="Number of worker threads")
    parser.add_argument("--timeout", type=float, default=6.0, help="Per-request timeout seconds")
    parser.add_argument(
        "--mix",
        type=_parse_mix,
        default=Mix(lines=2, line_stops=4, line_arrivals=4, stop_detail=2),
        help="Request mix weights: lines,stops,arrivals,stop (e.g. 2,4,4,2)",
    )
    parser.add_argument(
        "--sample-limit",
        type=int,
        default=5000,
        help="Max latency samples stored for percentiles",
    )

    args = parser.parse_args()
    return run_stress(
        base_url=args.base_url,
        duration_s=args.duration,
        concurrency=args.concurrency,
        timeout_s=args.timeout,
        mix=args.mix,
        sample_limit=args.sample_limit,
    )


if __name__ == "__main__":
    raise SystemExit(main())
