from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from fastapi import HTTPException

from .paths import BACKEND_DIR, MATLAB_PROJECT_DIR, RUNTIME_ROOT, WORKERS_DIR


def build_env() -> dict[str, str]:
    env = os.environ.copy()
    runtime_paths = [
        str(RUNTIME_ROOT / "runtime" / "win64"),
        str(RUNTIME_ROOT / "bin" / "win64"),
        str(RUNTIME_ROOT / "extern" / "bin" / "win64"),
    ]
    env["PATH"] = ";".join(runtime_paths + [env.get("PATH", "")])
    env["PYTHONIOENCODING"] = "utf-8"
    return env


def parse_designpoint_stdout(stdout: str) -> dict[str, Any]:
    metrics: dict[str, Any] = {}
    stations: list[dict[str, float]] = []
    station_capture = False
    for raw_line in stdout.splitlines():
        line = raw_line.strip()
        if line.startswith("Power output="):
            match = re.search(r"Power output=\s*([0-9.]+)", line)
            if match:
                metrics["power_output_kw"] = float(match.group(1))
        elif line.startswith("Thermal efficiency="):
            match = re.search(r"Thermal efficiency=\s*([0-9.]+)", line)
            if match:
                metrics["thermal_efficiency"] = float(match.group(1))
        elif line.startswith("Ng="):
            match = re.search(r"Ng=\s*([0-9.]+)", line)
            if match:
                metrics["ng_rpm"] = float(match.group(1))
        elif line.startswith("Np="):
            match = re.search(r"Np=\s*([0-9.]+)", line)
            if match:
                metrics["np_rpm"] = float(match.group(1))
        elif line.startswith("Station"):
            station_capture = True
        elif station_capture and line.startswith("----"):
            station_capture = False
        elif station_capture and re.match(r"^\d+", line):
            parts = re.split(r"\s+", line)
            if len(parts) >= 4:
                stations.append(
                    {
                        "station": float(parts[0]),
                        "W": float(parts[1]),
                        "T": float(parts[2]),
                        "P": float(parts[3]),
                    }
                )
    if stations:
        metrics["stations"] = stations
    return metrics


def run_worker(name: str, payload: dict[str, Any]) -> tuple[dict[str, Any], str]:
    script = WORKERS_DIR / f"{name}_worker.py"
    if not script.exists():
        raise HTTPException(status_code=500, detail=f"Worker not found: {script}")

    with tempfile.TemporaryDirectory(dir=BACKEND_DIR / "data") as temp_dir:
        temp_path = Path(temp_dir)
        input_path = temp_path / "input.json"
        output_path = temp_path / "output.json"
        input_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

        proc = subprocess.run(
            [sys.executable, str(script), str(input_path), str(output_path)],
            cwd=str(MATLAB_PROJECT_DIR),
            env=build_env(),
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=3600,
        )

        logs = "\n".join(part for part in [proc.stdout, proc.stderr] if part).strip()
        if proc.returncode != 0:
            detail = logs[-6000:] if logs else "Worker execution failed."
            raise HTTPException(status_code=500, detail=detail)

        if not output_path.exists():
            raise HTTPException(status_code=500, detail="Worker did not produce output.")

        data = json.loads(output_path.read_text(encoding="utf-8"))
        if name == "design_point":
            data.setdefault("summary", {}).update(parse_designpoint_stdout(proc.stdout))
        data["logs"] = logs[-12000:] if logs else ""
        return data, logs
