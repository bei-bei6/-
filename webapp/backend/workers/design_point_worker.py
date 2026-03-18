from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from app.mat_utils import build_designpoint_runtime_mat, load_mat, save_mat  # noqa: E402
from app.paths import PARAMETER_DIR  # noqa: E402


def main() -> None:
    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    payload = json.loads(input_path.read_text(encoding="utf-8"))

    config = payload["config"]
    save_mat(PARAMETER_DIR / "py_designpoint.mat", build_designpoint_runtime_mat(config))

    import python_DESIGN_POINT  # noqa: E402

    package = python_DESIGN_POINT.initialize()
    package.python_DESIGN_POINT(nargout=1)

    response = {
        "summary": {},
        "dp": load_mat(PARAMETER_DIR / "dp.mat")["dp"],
        "scale": load_mat(PARAMETER_DIR / "scale.mat")["scale"],
        "x0": load_mat(PARAMETER_DIR / "x0.mat")["x0"],
        "x0Sheet": load_mat(PARAMETER_DIR / "x0_sheet.mat")["x0_sheet"],
    }
    output_path.write_text(json.dumps(response, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
