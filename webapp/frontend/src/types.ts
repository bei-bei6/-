export type AnyRecord = Record<string, unknown>

export interface Topology {
  id: string
  name: string
  description: string
  available: boolean
}

export interface HealthResponse {
  ok: boolean
  runtimeInstalled: boolean
}

export interface DefaultsResponse {
  topologies: Topology[]
  defaults: {
    designPoint: AnyRecord
    steadyState: AnyRecord
    transient: AnyRecord
  }
}

export interface StationRow {
  station: number
  W: number
  T: number
  P: number
}

export interface DesignPointSummary {
  power_output_kw?: number
  thermal_efficiency?: number
  ng_rpm?: number
  np_rpm?: number
  stations?: StationRow[]
}

export interface DesignPointResponse {
  summary: DesignPointSummary
  dp: AnyRecord
  scale: AnyRecord
  x0: unknown
  x0Sheet: unknown
  logs: string
}

export interface SteadySummary {
  power_output_kw: number
  thermal_efficiency: number
  ng_rpm: number
  np_rpm: number
  fuel_flow_kg_s: number
}

export interface WorkingPoint {
  x: number
  y: number
}

export interface ScatterTracePoint extends WorkingPoint {
  load_mw?: number
  time?: number
}

export interface SteadyRun {
  summary: SteadySummary
  stations: StationRow[]
  workingPoints: {
    HPC: WorkingPoint
    HPT: WorkingPoint
    PT: WorkingPoint
  }
  componentPerformance: {
    HPC: AnyRecord
    Burner: AnyRecord
    HPT: AnyRecord
    PT: AnyRecord
  }
  result: AnyRecord
  logs: string
  inputPowerOutputW: number
}

export interface SteadyBatchPoint {
  input_load_mw: number
  output_power_kw: number
  thermal_efficiency: number
  hpc_pr: number
  hpt_pr: number
  pt_pr: number
}

export interface SteadyResponse {
  mode: 'single' | 'batch'
  runs: SteadyRun[]
  batch: {
    points: SteadyBatchPoint[]
    workingLines: {
      HPC: ScatterTracePoint[]
      HPT: ScatterTracePoint[]
      PT: ScatterTracePoint[]
    }
  }
}

export interface ChartPoint {
  time: number
  value: number
}

export interface ChartSeries {
  name: string
  unit: string
  points: ChartPoint[]
}

export interface StepRow {
  time: number
  np_rpm: number
  ng_rpm: number
  power_kw: number
  load_kw: number
  t45_k: number
}

export interface TransientSummary {
  duration_s: number
  final_power_kw: number
  final_load_kw: number
  final_np_rpm: number
  final_ng_rpm: number
  final_t45_k: number
  final_hpc_pr: number
}

export interface TransientResponse {
  summary: TransientSummary
  charts: Record<string, ChartSeries[]>
  mapTraces: {
    HPC: ScatterTracePoint[]
    HPT: ScatterTracePoint[]
    PT: ScatterTracePoint[]
  }
  stepTable: StepRow[]
  finalState: AnyRecord
  logs: string
}
