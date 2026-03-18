from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from app.mat_utils import (  # noqa: E402
    build_station_rows_from_steady,
    deep_merge,
    load_mat,
    save_mat,
    safe_div,
)
from app.paths import PARAMETER_DIR  # noqa: E402


def main() -> None:
    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    payload = json.loads(input_path.read_text(encoding="utf-8"))

    defaults = load_mat(PARAMETER_DIR / "py_main_ss.mat")
    config = deep_merge(defaults, payload["config"])
    save_mat(PARAMETER_DIR / "py_main_ss.mat", config)

    import python_Main_SS  # noqa: E402

    package = python_Main_SS.initialize()
    result = package.python_Main_SS(nargout=1)

    summary = {
        "power_output_kw": float(result["WholeEngine"]["PTData"]["Pwrout"]) / 1000.0,
        "thermal_efficiency": safe_div(
            float(result["WholeEngine"]["PTData"]["Pwrout"]),
            float(result["WholeEngine"]["B_Data"]["heat"]),
        ),
        "ng_rpm": float(result["WholeEngine"]["HP_Shaft"]),
        "np_rpm": float(result["WholeEngine"]["PT_Shaft"]),
        "fuel_flow_kg_s": float(result["WholeEngine"]["B_Data"]["Wf"]),
    }

    response = {
        "summary": summary,
        "stations": build_station_rows_from_steady(result),
        "workingPoints": {
            "HPC": {
                "x": float(result["WholeEngine"]["HPCData"]["Wcin"]),
                "y": float(result["WholeEngine"]["HPCData"]["PR"]),
            },
            "HPT": {
                "x": float(result["WholeEngine"]["HPTData"]["Wc"]),
                "y": float(result["WholeEngine"]["HPTData"]["PR"]),
            },
            "PT": {
                "x": float(result["WholeEngine"]["PTData"]["Wc"]),
                "y": float(result["WholeEngine"]["PTData"]["PR"]),
            },
        },
        "componentPerformance": {
            "HPC": {
                "Eff": result["WholeEngine"]["HPCData"]["Eff"],
                "PR": result["WholeEngine"]["HPCData"]["PR"],
                "SM": result["WholeEngine"]["HPCData"]["SM"],
            },
            "Burner": result["WholeEngine"]["B_Data"],
            "HPT": {
                "Eff": result["WholeEngine"]["HPTData"]["Eff"],
                "PR": result["WholeEngine"]["HPTData"]["PR"],
            },
            "PT": {
                "Eff": result["WholeEngine"]["PTData"]["Eff"],
                "PR": result["WholeEngine"]["PTData"]["PR"],
            },
        },
        "result": result,
    }
    output_path.write_text(json.dumps(response, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
