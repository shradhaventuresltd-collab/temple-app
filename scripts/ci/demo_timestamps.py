#!/usr/bin/env python3
"""Map the step timing log onto the concatenated demo MP4.

Each line of the timing log is "<epoch-ms> SEG_START <n>",
"<epoch-ms> SEG_END <n>", or "<epoch-ms> STEP <name>".
Segment durations come from ffprobe. A step that lands in the gap
between two segments is placed at the start of the next segment,
which is the first frame that can show it.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


def _format_clock(seconds: float) -> str:
    if seconds < 0:
        seconds = 0.0
    total_ms = int(round(seconds * 1000))
    minutes, ms = divmod(total_ms, 60_000)
    secs, ms = divmod(ms, 1000)
    return f"{minutes}:{secs:02d}.{ms:03d}"


def parse_timing(path: Path) -> tuple[list[dict], list[tuple[int, str]]]:
    segments: dict[str, dict] = {}
    order: list[str] = []
    steps: list[tuple[int, str]] = []
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = raw.split()
        if len(parts) < 3 or not parts[0].isdigit():
            continue
        ms = int(parts[0])
        kind = parts[1]
        name = parts[2]
        if kind == "SEG_START":
            segments[name] = {"name": name, "start": ms, "end": None}
            order.append(name)
        elif kind == "SEG_END" and name in segments:
            segments[name]["end"] = ms
        elif kind == "STEP":
            steps.append((ms, name))
    return [segments[name] for name in order if name in segments], steps


def probe_duration(path: Path) -> float | None:
    ffprobe = shutil.which("ffprobe")
    if ffprobe is None:
        return None
    result = subprocess.run(
        [
            ffprobe,
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "csv=p=0",
            str(path),
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    text = result.stdout.strip()
    if result.returncode != 0 or not text:
        return None
    try:
        value = float(text.splitlines()[0])
    except ValueError:
        return None
    if value <= 0.05:
        return None
    return value


def attach_durations(
    segments: list[dict],
    segments_dir: Path,
    overrides: dict[str, float],
) -> list[dict]:
    usable = []
    cursor = 0.0
    for segment in segments:
        name = segment["name"]
        duration = overrides.get(name)
        if duration is None:
            path = segments_dir / f"demo-{name}.mp4"
            if path.is_file():
                duration = probe_duration(path)
        if duration is None:
            continue
        segment = dict(segment)
        segment["duration"] = duration
        segment["video_start"] = cursor
        cursor += duration
        usable.append(segment)
    return usable


def step_offset(step_ms: int, segments: list[dict]) -> float:
    if not segments:
        return 0.0
    for index, segment in enumerate(segments):
        start = int(segment["start"])
        end = segment.get("end")
        video_start = float(segment["video_start"])
        duration = float(segment["duration"])
        if step_ms < start:
            return video_start
        if end is None or step_ms <= int(end):
            into = max(0.0, (step_ms - start) / 1000.0)
            if into > duration:
                into = duration
            return video_start + into
        next_segment = segments[index + 1] if index + 1 < len(segments) else None
        if next_segment is not None and step_ms < int(next_segment["start"]):
            return float(next_segment["video_start"])
    last = segments[-1]
    return float(last["video_start"]) + float(last["duration"])


def write_markdown(path: Path, rows: list[tuple[str, float]], notes: list[str]) -> None:
    lines = [
        "# Demo timestamps",
        "",
        "Start times are offsets in the concatenated `demo.mp4`.",
        "They come from the step timing log and each segment's duration.",
        "",
        "| Step | Start |",
        "| --- | --- |",
    ]
    for name, offset in rows:
        lines.append(f"| {name} | {_format_clock(offset)} |")
    if notes:
        lines.extend(["", "## Notes", ""])
        lines.extend(f"- {note}" for note in notes)
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def extract_frames(
    video: Path,
    frames_dir: Path,
    rows: list[tuple[str, float]],
) -> None:
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None or not video.is_file():
        return
    frames_dir.mkdir(parents=True, exist_ok=True)
    for index, (name, offset) in enumerate(rows, start=1):
        # A third of a second in, so the frame is the settled screen
        # rather than the tap that opened it. Clamp to the step start
        # when the video is shorter than that.
        when = max(0.0, offset + 0.4)
        dest = frames_dir / f"{index:02d}-{name}.png"
        subprocess.run(
            [
                ffmpeg,
                "-y",
                "-ss",
                f"{when:.3f}",
                "-i",
                str(video),
                "-frames:v",
                "1",
                str(dest),
            ],
            check=False,
            capture_output=True,
        )


def build_rows(
    timing: Path,
    segments_dir: Path,
    overrides: dict[str, float],
) -> tuple[list[tuple[str, float]], list[str]]:
    segments, steps = parse_timing(timing)
    usable = attach_durations(segments, segments_dir, overrides)
    notes: list[str] = []
    if not usable:
        notes.append("No playable segment durations were found.")
    rows = [(name, step_offset(ms, usable)) for ms, name in steps]
    return rows, notes


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timing", type=Path, required=True)
    parser.add_argument("--segments-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--video", type=Path)
    parser.add_argument("--frames-dir", type=Path)
    parser.add_argument(
        "--duration",
        action="append",
        default=[],
        help="Override a segment duration as N=seconds (tests).",
    )
    args = parser.parse_args(argv)
    overrides: dict[str, float] = {}
    for item in args.duration:
        name, _, raw = item.partition("=")
        overrides[name] = float(raw)
    rows, notes = build_rows(args.timing, args.segments_dir, overrides)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    write_markdown(args.output, rows, notes)
    if args.video and args.frames_dir:
        extract_frames(args.video, args.frames_dir, rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
