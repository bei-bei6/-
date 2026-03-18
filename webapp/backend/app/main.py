from __future__ import annotations

from copy import deepcopy
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .mat_utils import deep_merge, load_mat
from .paths import PARAMETER_DIR, RUNTIME_ROOT
from .runner import run_worker

app = FastAPI(title="Gas Turbine Web API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def current_defaults() -> dict[str, Any]:
    return {
        "designPoint": load_mat(PARAMETER_DIR / "py_designpoint.mat")["DP"],
        "steadyState": load_mat(PARAMETER_DIR / "py_main_ss.mat"),
        "transient": load_mat(PARAMETER_DIR / "py_main_ds.mat"),
    }


@app.get("/api/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "runtimeInstalled": RUNTIME_ROOT.exists(),
    }


@app.get("/api/defaults")
def defaults() -> dict[str, Any]:
    return {
        "topologies": [
            {
                "id": "two_spool_sas",
                "name": "双轴燃气轮机 + 二次空气系统",
                "description": "与当前 MATLAB Runtime 后端完全对应的可用拓扑。",
                "available": True,
            },
            {
                "id": "custom_topology",
                "name": "自定义拓扑",
                "description": "需求文档要求支持，但当前后端尚未提供可运行模型。",
                "available": False,
            },
        ],
        "defaults": current_defaults(),
    }


@app.post("/api/design-point/run")
def run_design_point(body: dict[str, Any]) -> dict[str, Any]:
    default_config = current_defaults()["designPoint"]
    config = deep_merge(default_config, body.get("config", body))
    result, _ = run_worker("design_point", {"config": config})
    return result


@app.post("/api/steady/run")
def run_steady(body: dict[str, Any]) -> dict[str, Any]:
    default_config = current_defaults()["steadyState"]
    config = deep_merge(default_config, body.get("config", body))
    requested = body.get("powerOutputs")
    power_outputs = requested if requested else [config["Power_output"]]

    runs: list[dict[str, Any]] = []
    for power in power_outputs:
        scenario = deepcopy(config)
        scenario["Power_output"] = power
        response, _ = run_worker("steady", {"config": scenario})
        response["inputPowerOutputW"] = power
        runs.append(response)

    batch = {
        "points": [
            {
                "input_load_mw": run["inputPowerOutputW"] / 1_000_000.0,
                "output_power_kw": run["summary"]["power_output_kw"],
                "thermal_efficiency": run["summary"]["thermal_efficiency"],
                "hpc_pr": run["componentPerformance"]["HPC"]["PR"],
                "hpt_pr": run["componentPerformance"]["HPT"]["PR"],
                "pt_pr": run["componentPerformance"]["PT"]["PR"],
            }
            for run in runs
        ],
        "workingLines": {
            "HPC": [
                {
                    "load_mw": run["inputPowerOutputW"] / 1_000_000.0,
                    "x": run["workingPoints"]["HPC"]["x"],
                    "y": run["workingPoints"]["HPC"]["y"],
                }
                for run in runs
            ],
            "HPT": [
                {
                    "load_mw": run["inputPowerOutputW"] / 1_000_000.0,
                    "x": run["workingPoints"]["HPT"]["x"],
                    "y": run["workingPoints"]["HPT"]["y"],
                }
                for run in runs
            ],
            "PT": [
                {
                    "load_mw": run["inputPowerOutputW"] / 1_000_000.0,
                    "x": run["workingPoints"]["PT"]["x"],
                    "y": run["workingPoints"]["PT"]["y"],
                }
                for run in runs
            ],
        },
    }

    return {
        "mode": "batch" if len(runs) > 1 else "single",
        "runs": runs,
        "batch": batch,
    }


@app.post("/api/transient/run")
def run_transient(body: dict[str, Any]) -> dict[str, Any]:
    default_config = current_defaults()["transient"]
    config = deep_merge(default_config, body.get("config", body))
    result, _ = run_worker("transient", {"config": config})
    return result
