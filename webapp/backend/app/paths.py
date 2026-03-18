from __future__ import annotations

from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
WEBAPP_DIR = BACKEND_DIR.parent
ROOT_DIR = WEBAPP_DIR.parent
MATLAB_PROJECT_DIR = next(
    path for path in ROOT_DIR.iterdir() if path.is_dir() and path.name.startswith("MATLAB")
)
PARAMETER_DIR = MATLAB_PROJECT_DIR / "parameter"
RESULT_DIR = MATLAB_PROJECT_DIR / "result"
DATA_DIR = BACKEND_DIR / "data"
WORKERS_DIR = BACKEND_DIR / "workers"
RUNTIME_ROOT = Path(r"C:\Program Files\MATLAB\MATLAB Runtime\R2022b")

