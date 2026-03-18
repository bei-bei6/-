from __future__ import annotations

import copy
import math
from pathlib import Path
from typing import Any

import numpy as np
import scipy.io as sio
from scipy.io.matlab import mat_struct


def to_python(value: Any) -> Any:
    if isinstance(value, mat_struct):
        return {field: to_python(getattr(value, field)) for field in value._fieldnames}
    if isinstance(value, np.ndarray):
        if value.ndim == 0:
            return to_python(value.item())
        return [to_python(item) for item in value.tolist()]
    if isinstance(value, np.generic):
        return value.item()
    if isinstance(value, (list, tuple)):
        return [to_python(item) for item in value]
    return value


def load_mat(path: Path) -> dict[str, Any]:
    raw = sio.loadmat(str(path), squeeze_me=True, struct_as_record=False)
    return {key: to_python(value) for key, value in raw.items() if not key.startswith("__")}


def to_matlab_compatible(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: to_matlab_compatible(item) for key, item in value.items()}
    if isinstance(value, list):
        return [to_matlab_compatible(item) for item in value]
    if isinstance(value, tuple):
        return [to_matlab_compatible(item) for item in value]
    if isinstance(value, bool):
        return float(value)
    if isinstance(value, int):
        return float(value)
    if isinstance(value, np.generic):
        return value.item()
    return value


def save_mat(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sio.savemat(str(path), to_matlab_compatible(data), do_compression=True)


def deep_merge(base: Any, overrides: Any) -> Any:
    if overrides is None:
        return copy.deepcopy(base)
    if isinstance(base, dict) and isinstance(overrides, dict):
        merged = copy.deepcopy(base)
        for key, value in overrides.items():
            if key in merged:
                merged[key] = deep_merge(merged[key], value)
            else:
                merged[key] = copy.deepcopy(value)
        return merged
    return copy.deepcopy(overrides)


def scalar(value: Any) -> float:
    if isinstance(value, list):
        if not value:
            return 0.0
        if len(value) == 1:
            return scalar(value[0])
    return float(value)


def series(items: list[dict[str, Any]], path: list[str]) -> list[float]:
    output: list[float] = []
    for item in items:
        current: Any = item
        for part in path:
            current = current[part]
        output.append(float(current))
    return output


def safe_div(numerator: float, denominator: float) -> float:
    if math.isclose(denominator, 0.0):
        return 0.0
    return numerator / denominator


def build_designpoint_runtime_mat(config: dict[str, Any]) -> dict[str, Any]:
    burner = copy.deepcopy(config["Burner"])
    pt = copy.deepcopy(config["PT"])
    payload = {
        "DP": copy.deepcopy(config),
        "inlet": {
            "T": scalar(config["Amb"].get("T", 288.15)),
            "W": scalar(config["inlet"]["W"]),
            "PR": scalar(config["inlet"]["PR"]),
        },
        "Amb": {"P": scalar(config["Amb"]["P"])},
        "data": {
            "SAS": copy.deepcopy(config["SAS"]),
            "HPCDeflate": copy.deepcopy(config["HPCDeflate"]),
        },
        "HPC": copy.deepcopy(config["HPC"]),
        "Burner": {
            "T": scalar(burner["T"]),
            "PR": scalar(burner["PR"]),
            "Eff": scalar(burner["Eff"]),
        },
        "heatvalue": scalar(burner["heatvalue"]),
        "HPT": copy.deepcopy(config["HPT"]),
        "HPS": copy.deepcopy(config["HPS"]),
        "LPT": {
            "Eff": scalar(pt["Eff"]),
            "DUCTloss": scalar(pt["DUCTloss"]),
            "beta": scalar(pt["beta"]),
            "Ncor_r": scalar(pt["Ncor_r"]),
        },
        "LPS": copy.deepcopy(config["PTS"]),
        "Outlet": {"PR": scalar(config["Volute"]["Ps8_P0"])},
        "Volute": {"PR": scalar(config["Volute"]["P6_Ps8"])},
    }
    return payload


def build_station_rows_from_steady(result: dict[str, Any]) -> list[dict[str, float]]:
    gas = result["GasPth"]
    engine = result["WholeEngine"]
    return [
        {"station": 1, "W": gas["GasOut_Inlet"]["W"], "T": 288.15, "P": 101325.0},
        {
            "station": 2,
            "W": gas["GasOut_Inlet"]["W"],
            "T": gas["GasOut_Inlet"]["Tt"],
            "P": gas["GasOut_Inlet"]["Pt"],
        },
        {
            "station": 3,
            "W": engine["HPCData"]["W_3"],
            "T": gas["GasOut_HPC"]["Tt"],
            "P": gas["GasOut_HPC"]["Pt"],
        },
        {
            "station": 31,
            "W": gas["GasOut_HPC"]["W"],
            "T": gas["GasOut_HPC"]["Tt"],
            "P": gas["GasOut_HPC"]["Pt"],
        },
        {
            "station": 4,
            "W": gas["GasOut_Burner"]["W"],
            "T": gas["GasOut_Burner"]["Tt"],
            "P": gas["GasOut_Burner"]["Pt"],
        },
        {
            "station": 41,
            "W": engine["HPTData"]["W41"],
            "T": engine["HPTData"]["T41"],
            "P": engine["HPTData"]["P41"],
        },
        {
            "station": 43,
            "W": engine["HPTData"]["W43"],
            "T": engine["HPTData"]["T43"],
            "P": engine["HPTData"]["P43"],
        },
        {
            "station": 44,
            "W": gas["GasOut_HPT"]["W"],
            "T": gas["GasOut_HPT"]["Tt"],
            "P": gas["GasOut_HPT"]["Pt"],
        },
        {
            "station": 45,
            "W": engine["PTData"]["W45"],
            "T": engine["PTData"]["T45"],
            "P": engine["PTData"]["P45"],
        },
        {
            "station": 49,
            "W": engine["PTData"]["W49"],
            "T": engine["PTData"]["T49"],
            "P": engine["PTData"]["P49"],
        },
        {
            "station": 5,
            "W": gas["GasOut_PT"]["W"],
            "T": gas["GasOut_PT"]["Tt"],
            "P": gas["GasOut_PT"]["Pt"],
        },
        {
            "station": 6,
            "W": gas["Volute"]["W6"],
            "T": gas["Volute"]["T6"],
            "P": gas["Volute"]["P6"],
        },
        {
            "station": 8,
            "W": gas["Volute"]["W6"],
            "T": gas["Volute"]["T6"],
            "P": gas["Volute"]["P6"],
        },
    ]


def build_transient_payload(result: dict[str, Any]) -> dict[str, Any]:
    time = result["TIME"]["time"]
    whole_engine = result["WholeEngine1"]

    charts = {
        "shaftSpeed": [
            {
                "name": "动力轴转速",
                "unit": "rpm",
                "points": [
                    {"time": t, "value": v}
                    for t, v in zip(time, series(whole_engine, ["PT_Shaft"]))
                ],
            },
            {
                "name": "高压轴转速",
                "unit": "rpm",
                "points": [
                    {"time": t, "value": v}
                    for t, v in zip(time, series(whole_engine, ["HP_Shaft"]))
                ],
            },
        ],
        "thermalState": [
            {
                "name": "动力涡轮喷嘴后温度 T45",
                "unit": "K",
                "points": [
                    {"time": t, "value": v}
                    for t, v in zip(time, series(whole_engine, ["PTData", "T45"]))
                ],
            },
            {
                "name": "燃油流量",
                "unit": "kg/s",
                "points": [
                    {"time": t, "value": v}
                    for t, v in zip(time, series(whole_engine, ["B_Data", "Wf"]))
                ],
            },
        ],
        "powerLoad": [
            {
                "name": "负载功率",
                "unit": "W",
                "points": [
                    {"time": t, "value": v}
                    for t, v in zip(time, series(whole_engine, ["Others", "Load"]))
                ],
            },
            {
                "name": "动力涡轮输出功率",
                "unit": "W",
                "points": [
                    {"time": t, "value": v}
                    for t, v in zip(time, series(whole_engine, ["PTData", "Pwrout"]))
                ],
            },
        ],
    }

    map_traces = {
        "HPC": [
            {
                "time": t,
                "x": point["HPCData"]["Wcin"],
                "y": point["HPCData"]["PR"],
            }
            for t, point in zip(time, whole_engine)
        ],
        "HPT": [
            {
                "time": t,
                "x": point["HPTData"]["Wc"],
                "y": point["HPTData"]["PR"],
            }
            for t, point in zip(time, whole_engine)
        ],
        "PT": [
            {
                "time": t,
                "x": point["PTData"]["Wc"],
                "y": point["PTData"]["PR"],
            }
            for t, point in zip(time, whole_engine)
        ],
    }

    final_state = whole_engine[-1]
    summary = {
        "duration_s": float(time[-1]),
        "final_power_kw": float(final_state["PTData"]["Pwrout"]) / 1000.0,
        "final_load_kw": float(final_state["Others"]["Load"]) / 1000.0,
        "final_np_rpm": float(final_state["PT_Shaft"]),
        "final_ng_rpm": float(final_state["HP_Shaft"]),
        "final_t45_k": float(final_state["PTData"]["T45"]),
        "final_hpc_pr": float(final_state["HPCData"]["PR"]),
    }

    step_table = [
        {
            "time": float(t),
            "np_rpm": float(point["PT_Shaft"]),
            "ng_rpm": float(point["HP_Shaft"]),
            "power_kw": float(point["PTData"]["Pwrout"]) / 1000.0,
            "load_kw": float(point["Others"]["Load"]) / 1000.0,
            "t45_k": float(point["PTData"]["T45"]),
        }
        for t, point in zip(time, whole_engine)
    ]

    return {
        "summary": summary,
        "charts": charts,
        "mapTraces": map_traces,
        "stepTable": step_table,
        "finalState": final_state,
    }
