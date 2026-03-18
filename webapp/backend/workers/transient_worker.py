from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from app.mat_utils import build_transient_payload, deep_merge, load_mat, save_mat  # noqa: E402
from app.paths import PARAMETER_DIR, RESULT_DIR  # noqa: E402


def main() -> None:
    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    payload = json.loads(input_path.read_text(encoding="utf-8"))

    defaults = load_mat(PARAMETER_DIR / "py_main_ds.mat")
    config = deep_merge(defaults, payload["config"])
    save_mat(PARAMETER_DIR / "py_main_ds.mat", config)

    import python_Main_DS  # noqa: E402

    package = python_Main_DS.initialize()
    package.python_Main_DS(nargout=1)

    result = load_mat(RESULT_DIR / "RESULT.mat")
    response = build_transient_payload(result)
    output_path.write_text(json.dumps(response, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
