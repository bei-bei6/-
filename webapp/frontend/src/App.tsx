import {
  startTransition,
  useDeferredValue,
  useEffect,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from 'react'
import clsx from 'clsx'
import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Scatter,
  ScatterChart,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'

import { fetchDefaults, fetchHealth, runDesignPoint, runSteadyState, runTransient } from './api'
import './App.css'
import type {
  AnyRecord,
  ChartSeries,
  DefaultsResponse,
  DesignPointResponse,
  HealthResponse,
  ScatterTracePoint,
  StationRow,
  SteadyResponse,
  Topology,
  TransientResponse,
} from './types'
import {
  buildMergedChartRows,
  deepClone,
  downloadJson,
  downloadText,
  formatNumber,
  getByPath,
  listToText,
  numberValue,
  parseNumericList,
  parseScheduleCsv,
  readTextFile,
  rowsToCsv,
  setByPath,
} from './utils'

type TabId = 'topology' | 'design' | 'steady' | 'transient' | 'adaptation' | 'project'
type BusyKey = 'bootstrap' | 'design' | 'steady' | 'transient' | null
type FieldKind = 'number' | 'boolean' | 'list'

interface FieldSpec {
  label: string
  path: string
  unit?: string
  kind?: FieldKind
  step?: string
}

interface SectionSpec {
  title: string
  description?: string
  fields: FieldSpec[]
}

const tabs: Array<{ id: TabId; label: string; hint: string }> = [
  { id: 'topology', label: '结构选型', hint: '拓扑' },
  { id: 'design', label: '设计点', hint: '输入 / 结果' },
  { id: 'steady', label: '非设计点', hint: '稳态' },
  { id: 'transient', label: '过渡态', hint: '动态' },
  { id: 'adaptation', label: '模型自适应', hint: '待接入' },
  { id: 'project', label: '项目文件', hint: '管理' },
]

const designSections: SectionSpec[] = [
  {
    title: '环境与进气',
    fields: [
      { label: '环境温度', path: 'Amb.T', unit: 'K', step: '0.01' },
      { label: '环境压力', path: 'Amb.P', unit: 'Pa', step: '1' },
      { label: '进口流量', path: 'inlet.W', unit: 'kg/s', step: '0.01' },
      { label: '总压恢复系数', path: 'inlet.PR', unit: '-', step: '0.0001' },
    ],
  },
  {
    title: '压气机与燃烧室',
    fields: [
      { label: '压气机压比', path: 'HPC.Pr', unit: '-', step: '0.01' },
      { label: '压气机效率', path: 'HPC.Eff', unit: '-', step: '0.0001' },
      { label: '燃烧室出口温度', path: 'Burner.T', unit: 'K', step: '0.01' },
      { label: '燃料低位热值', path: 'Burner.heatvalue', unit: 'J/kg', step: '1' },
      { label: '燃烧室压比', path: 'Burner.PR', unit: '-', step: '0.0001' },
      { label: '燃烧室效率', path: 'Burner.Eff', unit: '-', step: '0.0001' },
    ],
  },
  {
    title: '涡轮与轴系',
    fields: [
      { label: '高压涡轮压比', path: 'HPT.Pr', unit: '-', step: '0.0001' },
      { label: '高压涡轮效率', path: 'HPT.Eff', unit: '-', step: '0.0001' },
      { label: '动力涡轮压比', path: 'PT.Pr', unit: '-', step: '0.0001' },
      { label: '动力涡轮效率', path: 'PT.Eff', unit: '-', step: '0.0001' },
      { label: '高压轴转速', path: 'HPS.speed', unit: 'rpm', step: '1' },
      { label: '动力轴转速', path: 'PTS.speed', unit: 'rpm', step: '1' },
    ],
  },
]

const steadySections: SectionSpec[] = [
  {
    title: '工况目标',
    fields: [
      { label: '目标功率', path: 'Power_output', unit: 'W', step: '1000' },
      { label: '环境温度', path: 'data.T0', unit: 'K', step: '0.01' },
      { label: '环境压力', path: 'data.P0', unit: 'Pa', step: '1' },
      { label: '动力轴转速', path: 'data.PT_Shaft', unit: 'rpm', step: '1' },
      { label: '相对湿度', path: 'data.RH', unit: '-', step: '0.001' },
      { label: '进口总压损失', path: 'data.P_loss_inlet', unit: '-', step: '0.0001' },
    ],
  },
  {
    title: '修正与耦合',
    fields: [
      { label: '燃烧室修正', path: 'data.HGC.Burner', kind: 'boolean' },
      { label: '高压涡轮修正', path: 'data.HGC.HPT', kind: 'boolean' },
      { label: '二次空气耦合', path: 'data.HGC.SAS', kind: 'boolean' },
      { label: '燃烧室修正 x', path: 'data.Combustor.x', unit: '-', step: '0.001' },
      { label: '燃烧室修正 y', path: 'data.Combustor.y', unit: '-', step: '0.001' },
      { label: '蜗壳压损修正', path: 'data.P_loss_volute', unit: '-', step: '0.0001' },
    ],
  },
]

const transientSections: SectionSpec[] = [
  {
    title: '动态边界',
    fields: [
      { label: '环境温度', path: 'data.T0', unit: 'K', step: '0.01' },
      { label: '环境压力', path: 'data.P0', unit: 'Pa', step: '1' },
      { label: '初始动力轴转速', path: 'data.PT_Shaft', unit: 'rpm', step: '1' },
      { label: '仿真时长', path: 'data.time', unit: 's', step: '0.01' },
      { label: '时间步长', path: 'data.deltat', unit: 's', step: '0.001' },
      { label: '负载方式', path: 'data.loadingmethod', unit: '1/3/4', step: '1' },
    ],
  },
  {
    title: '控制器',
    fields: [
      { label: '转速需求', path: 'data.n2_demand', unit: 'rpm', step: '1' },
      { label: '外环 Kp', path: 'data.Kp_out', unit: '-', step: '0.001' },
      { label: '外环 Ki', path: 'data.Ki_out', unit: '-', step: '0.001' },
      { label: '内环 Kp', path: 'data.Kp_in', unit: '-', step: '0.001' },
      { label: '内环 Ki', path: 'data.Ki_in', unit: '-', step: '0.001' },
      { label: '燃油延迟', path: 'data.fuel_delay', unit: 's', step: '0.001' },
    ],
  },
]

const linePalette = ['#0f5b78', '#1d7f6d', '#d67a2d', '#295ea8', '#9554d9']
const statAccents = ['#0f5b78', '#1d7f6d', '#d67a2d', '#295ea8']
const chartTitleMap: Record<string, string> = {
  shaftSpeed: '轴系转速响应',
  thermalState: '热状态变化',
  powerLoad: '功率与负载变化',
}

function App() {
  const [health, setHealth] = useState<HealthResponse | null>(null)
  const [topologies, setTopologies] = useState<Topology[]>([])
  const [defaults, setDefaults] = useState<DefaultsResponse['defaults'] | null>(null)
  const [selectedTopology, setSelectedTopology] = useState('two_spool_sas')
  const [projectName, setProjectName] = useState('gas-turbine-web-project')
  const [activeTab, setActiveTab] = useState<TabId>('topology')
  const [busy, setBusy] = useState<BusyKey>('bootstrap')
  const [error, setError] = useState('')
  const [designConfig, setDesignConfig] = useState<AnyRecord | null>(null)
  const [steadyConfig, setSteadyConfig] = useState<AnyRecord | null>(null)
  const [transientConfig, setTransientConfig] = useState<AnyRecord | null>(null)
  const [designResult, setDesignResult] = useState<DesignPointResponse | null>(null)
  const [steadyResult, setSteadyResult] = useState<SteadyResponse | null>(null)
  const [transientResult, setTransientResult] = useState<TransientResponse | null>(null)
  const [steadyLoadsText, setSteadyLoadsText] = useState('13.2')
  const [steadyRunIndex, setSteadyRunIndex] = useState(0)
  const projectInputRef = useRef<HTMLInputElement | null>(null)
  const scheduleInputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    const bootstrap = async () => {
      setBusy('bootstrap')
      setError('')
      try {
        const [healthResponse, defaultsResponse] = await Promise.all([fetchHealth(), fetchDefaults()])
        startTransition(() => {
          setHealth(healthResponse)
          setTopologies(defaultsResponse.topologies)
          setDefaults(defaultsResponse.defaults)
          setDesignConfig(deepClone(defaultsResponse.defaults.designPoint))
          setSteadyConfig(deepClone(defaultsResponse.defaults.steadyState))
          setTransientConfig(deepClone(defaultsResponse.defaults.transient))
          setSelectedTopology(defaultsResponse.topologies.find((item) => item.available)?.id ?? 'two_spool_sas')
          setSteadyLoadsText(
            (numberValue(defaultsResponse.defaults.steadyState.Power_output, 13_200_000) / 1_000_000).toString(),
          )
        })
      } catch (bootstrapError) {
        setError(bootstrapError instanceof Error ? bootstrapError.message : '初始化失败')
      } finally {
        setBusy(null)
      }
    }
    void bootstrap()
  }, [])

  useEffect(() => {
    setSteadyRunIndex(0)
  }, [steadyResult])

  const activeSteadyRun = useMemo(
    () => (steadyResult ? steadyResult.runs[steadyRunIndex] ?? steadyResult.runs[0] : null),
    [steadyResult, steadyRunIndex],
  )
  const deferredStepTable = useDeferredValue(transientResult?.stepTable ?? [])
  const selectedTopologyMeta = topologies.find((item) => item.id === selectedTopology) ?? null
  const designStations = designResult?.summary.stations ?? []
  const steadyPoints = steadyResult?.batch.points ?? []
  const loadingTable = ((transientConfig && getByPath(transientConfig, 'data.LoadingTable')) ?? {
    time: [],
    Loading: [],
  }) as { time?: number[]; Loading?: number[] }

  const projectSnapshot = useMemo(
    () => ({
      version: '1.1.0',
      projectName,
      selectedTopology,
      config: {
        designPoint: designConfig,
        steadyState: steadyConfig,
        transient: transientConfig,
      },
      results: {
        designPoint: designResult,
        steadyState: steadyResult,
        transient: transientResult,
      },
    }),
    [
      designConfig,
      designResult,
      projectName,
      selectedTopology,
      steadyConfig,
      steadyResult,
      transientConfig,
      transientResult,
    ],
  )

  const patchConfig =
    (setter: Dispatch<SetStateAction<AnyRecord | null>>) => (path: string, value: unknown) =>
      setter((current) => (current ? setByPath(current, path, value) : current))

  const handleRunDesign = async () => {
    if (!designConfig) return
    setBusy('design')
    setError('')
    try {
      const response = await runDesignPoint(designConfig)
      startTransition(() => {
        setDesignResult(response)
        setActiveTab('design')
      })
    } catch (runError) {
      setError(runError instanceof Error ? runError.message : '设计点计算失败')
    } finally {
      setBusy(null)
    }
  }

  const handleRunSteady = async () => {
    if (!steadyConfig) return
    setBusy('steady')
    setError('')
    try {
      const powerOutputs = parseNumericList(steadyLoadsText).map((value) => value * 1_000_000)
      const response = await runSteadyState(steadyConfig, powerOutputs.length ? powerOutputs : undefined)
      startTransition(() => {
        setSteadyResult(response)
        setActiveTab('steady')
      })
    } catch (runError) {
      setError(runError instanceof Error ? runError.message : '非设计点计算失败')
    } finally {
      setBusy(null)
    }
  }

  const handleRunTransient = async () => {
    if (!transientConfig) return
    setBusy('transient')
    setError('')
    try {
      const response = await runTransient(transientConfig)
      startTransition(() => {
        setTransientResult(response)
        setActiveTab('transient')
      })
    } catch (runError) {
      setError(runError instanceof Error ? runError.message : '过渡态计算失败')
    } finally {
      setBusy(null)
    }
  }

  const handleNewProject = () => {
    if (!defaults) return
    setDesignConfig(deepClone(defaults.designPoint))
    setSteadyConfig(deepClone(defaults.steadyState))
    setTransientConfig(deepClone(defaults.transient))
    setDesignResult(null)
    setSteadyResult(null)
    setTransientResult(null)
    setSelectedTopology(topologies.find((item) => item.available)?.id ?? 'two_spool_sas')
    setProjectName('gas-turbine-web-project')
    setSteadyLoadsText((numberValue(defaults.steadyState.Power_output, 13_200_000) / 1_000_000).toString())
  }

  const handleOpenProject = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return
    try {
      const text = await readTextFile(file)
      const payload = JSON.parse(text) as {
        projectName?: string
        selectedTopology?: string
        config?: { designPoint?: AnyRecord; steadyState?: AnyRecord; transient?: AnyRecord }
        results?: { designPoint?: DesignPointResponse | null; steadyState?: SteadyResponse | null; transient?: TransientResponse | null }
      }
      setProjectName(payload.projectName ?? file.name.replace(/\.json$/i, ''))
      setSelectedTopology(payload.selectedTopology ?? selectedTopology)
      if (payload.config?.designPoint) setDesignConfig(payload.config.designPoint)
      if (payload.config?.steadyState) setSteadyConfig(payload.config.steadyState)
      if (payload.config?.transient) setTransientConfig(payload.config.transient)
      setDesignResult(payload.results?.designPoint ?? null)
      setSteadyResult(payload.results?.steadyState ?? null)
      setTransientResult(payload.results?.transient ?? null)
      setActiveTab('project')
    } catch (openError) {
      setError(openError instanceof Error ? openError.message : '项目文件打开失败')
    } finally {
      event.target.value = ''
    }
  }

  const handleImportLoadingTable = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file || !transientConfig) return
    try {
      const text = await readTextFile(file)
      const table = parseScheduleCsv(text, 'Loading')
      setTransientConfig((current) => current ? setByPath(current, 'data.LoadingTable', table as unknown as AnyRecord) : current)
      setActiveTab('transient')
    } catch (importError) {
      setError(importError instanceof Error ? importError.message : '负载表导入失败')
    } finally {
      event.target.value = ''
    }
  }

  const updateLoadingRow = (index: number, key: 'time' | 'Loading', value: number) => {
    setTransientConfig((current) => {
      if (!current) return current
      const existing = getByPath(current, 'data.LoadingTable') as { time?: number[]; Loading?: number[] }
      const times = [...(existing.time ?? [])]
      const loads = [...(existing.Loading ?? [])]
      if (key === 'time') times[index] = value
      else loads[index] = value
      return setByPath(current, 'data.LoadingTable', { time: times, Loading: loads } as unknown as AnyRecord)
    })
  }

  const addLoadingRow = () => {
    setTransientConfig((current) => {
      if (!current) return current
      const existing = getByPath(current, 'data.LoadingTable') as { time?: number[]; Loading?: number[] }
      const times = [...(existing.time ?? [])]
      const loads = [...(existing.Loading ?? [])]
      times.push(times.length ? times[times.length - 1] : 0)
      loads.push(loads.length ? loads[loads.length - 1] : 0)
      return setByPath(current, 'data.LoadingTable', { time: times, Loading: loads } as unknown as AnyRecord)
    })
  }

  const removeLoadingRow = (index: number) => {
    setTransientConfig((current) => {
      if (!current) return current
      const existing = getByPath(current, 'data.LoadingTable') as { time?: number[]; Loading?: number[] }
      const times = [...(existing.time ?? [])]
      const loads = [...(existing.Loading ?? [])]
      times.splice(index, 1)
      loads.splice(index, 1)
      return setByPath(current, 'data.LoadingTable', { time: times, Loading: loads } as unknown as AnyRecord)
    })
  }

  if (!defaults && busy === 'bootstrap') {
    return <div className="app-loading">正在读取默认参数与后端状态...</div>
  }

  return (
    <div className="app-shell">
      <header className="masthead">
        <div className="masthead-copy">
          <p className="eyebrow">仿真控制台</p>
          <h1>总体性能仿真控制台</h1>
        </div>
        <div className="masthead-side">
          <div className="status-cluster">
            <StatusPill active={health?.runtimeInstalled ?? false}>{health?.runtimeInstalled ? 'Runtime Ready' : 'Runtime Missing'}</StatusPill>
            <StatusPill active={selectedTopologyMeta?.available ?? false}>{selectedTopologyMeta?.available ? 'Topology Online' : 'Unavailable'}</StatusPill>
          </div>
          <div className="hero-actions">
            <button className="ghost-button" onClick={handleNewProject} disabled={!defaults || busy !== null}>新建项目</button>
            <button className="ghost-button" onClick={() => projectInputRef.current?.click()} disabled={busy !== null}>打开项目</button>
            <button className="ghost-button" onClick={() => downloadJson(`${projectName}.json`, projectSnapshot)}>保存项目</button>
          </div>
        </div>
      </header>

      <section className="command-deck">
        <div className="command-card command-card--main">
          <div>
            <p className="eyebrow">快速操作</p>
            <h2>{projectName}</h2>
          </div>
          <div className="command-buttons">
            <button className="primary-button" onClick={handleRunDesign} disabled={!designConfig || busy !== null}>{busy === 'design' ? '设计点计算中...' : '运行设计点'}</button>
            <button className="secondary-button" onClick={handleRunSteady} disabled={!steadyConfig || busy !== null}>{busy === 'steady' ? '非设计点计算中...' : '运行非设计点'}</button>
            <button className="secondary-button" onClick={handleRunTransient} disabled={!transientConfig || busy !== null}>{busy === 'transient' ? '过渡态计算中...' : '运行过渡态'}</button>
          </div>
        </div>
        <div className="command-summary-grid">
          <MetricTile label="当前拓扑" value={selectedTopologyMeta?.name ?? '-'} accent={statAccents[0]} />
          <MetricTile label="稳态默认功率" value={`${formatNumber(numberValue(steadyConfig?.Power_output, 0) / 1_000_000, 2)} MW`} accent={statAccents[1]} />
          <MetricTile label="动态时长" value={`${formatNumber(getByPath(transientConfig ?? {}, 'data.time'), 2)} s`} accent={statAccents[2]} />
          <MetricTile label="能力覆盖" value="设计点 / 稳态 / 动态" accent={statAccents[3]} />
        </div>
      </section>

      <nav className="module-tabs" aria-label="主模块">
        {tabs.map((tab) => (
          <button key={tab.id} className={clsx('module-tab', { active: activeTab === tab.id })} onClick={() => setActiveTab(tab.id)}>
            <span>{tab.label}</span>
            <small>{tab.hint}</small>
          </button>
        ))}
      </nav>

      {busy && busy !== 'bootstrap' ? <div className="alert info">计算进行中，请稍候...</div> : null}
      {error ? <div className="alert error">{error}</div> : null}

      {activeTab === 'topology' ? (
        <section className="overview-grid">
          <Panel title="燃机结构选型">
            <div className="topology-gallery">
              {topologies.map((topology) => (
                <button
                  key={topology.id}
                  className={clsx('topology-card', { active: selectedTopology === topology.id, unavailable: !topology.available })}
                  onClick={() => topology.available && setSelectedTopology(topology.id)}
                  disabled={!topology.available}
                >
                  <div className="topology-card__head">
                    <div>
                      <h3>{topology.name}</h3>
                    </div>
                    <StatusPill active={topology.available}>{topology.available ? '已接入' : '待接入'}</StatusPill>
                  </div>
                </button>
              ))}
            </div>
          </Panel>
          <Panel title="系统状态">
            <StatsGrid items={[
              { label: '当前拓扑', value: selectedTopologyMeta?.name ?? '-' },
              { label: '设计点结果', value: designResult ? '已计算' : '未计算' },
              { label: '非设计点结果', value: steadyResult ? '已计算' : '未计算' },
              { label: '过渡态结果', value: transientResult ? '已计算' : '未计算' },
            ]} />
          </Panel>
        </section>
      ) : null}

      {activeTab === 'design' ? (
        <ModuleShell
          title="设计点计算"
          controls={<>
            <InlineInfo label="运行入口" value="python_DESIGN_POINT" />
            {designConfig ? designSections.map((section, index) => <FieldSection key={section.title} config={designConfig} section={section} defaultOpen={index === 0} onChange={patchConfig(setDesignConfig)} />) : null}
          </>}
          results={designResult ? <>
            <StatsGrid items={[
              { label: '功率输出', value: `${formatNumber(designResult.summary.power_output_kw, 2)} kW` },
              { label: '热效率', value: formatNumber(designResult.summary.thermal_efficiency, 6) },
              { label: '高压轴转速', value: `${formatNumber(designResult.summary.ng_rpm, 2)} rpm` },
              { label: '动力轴转速', value: `${formatNumber(designResult.summary.np_rpm, 2)} rpm` },
            ]} />
            <Panel title="站位结果表"><StationTable rows={designStations} /></Panel>
            <Panel title="设计点产物"><details className="fold-card"><summary>查看 dp 与 scale</summary><pre>{JSON.stringify({ dp: designResult.dp, scale: designResult.scale }, null, 2)}</pre></details></Panel>
            {designResult.logs ? <Panel title="运行日志"><LogBlock text={designResult.logs} /></Panel> : null}
          </> : <EmptyState title="还没有设计点结果" text="先在左侧调整参数，再运行设计点计算。" />}
        />
      ) : null}

      {activeTab === 'steady' ? (
        <ModuleShell
          title="非设计点计算"
          controls={<>
            <InlineInput label="功率点列表" hint="输入 MW，例如 8, 10, 12, 13.2" value={steadyLoadsText} onChange={setSteadyLoadsText} />
            {steadyConfig ? steadySections.map((section, index) => <FieldSection key={section.title} config={steadyConfig} section={section} defaultOpen={index === 0} onChange={patchConfig(setSteadyConfig)} />) : null}
          </>}
          results={steadyResult ? <>
            <StatsGrid items={[
              { label: '工况点数', value: steadyResult.runs.length.toString() },
              { label: '最大输出功率', value: `${formatNumber(Math.max(...steadyPoints.map((item) => item.output_power_kw)), 2)} kW` },
              { label: '最高热效率', value: formatNumber(Math.max(...steadyPoints.map((item) => item.thermal_efficiency)), 6) },
              { label: '导出状态', value: 'CSV 可导出' },
            ]} />
            <div className="chart-layout chart-layout--steady">
              <LinePanel title="负载响应总览" rows={steadyPoints as unknown as Array<Record<string, number>>} xKey="input_load_mw" lines={[{ key: 'output_power_kw', name: '输出功率', color: linePalette[0] }, { key: 'thermal_efficiency', name: '热效率', color: linePalette[1] }]} featured />
              <LinePanel title="压比变化" rows={steadyPoints as unknown as Array<Record<string, number>>} xKey="input_load_mw" lines={[{ key: 'hpc_pr', name: 'HPC PR', color: linePalette[0] }, { key: 'hpt_pr', name: 'HPT PR', color: linePalette[2] }, { key: 'pt_pr', name: 'PT PR', color: linePalette[3] }]} />
              <ScatterPanel title="HPC 共同工作线" data={steadyResult.batch.workingLines.HPC} color={linePalette[0]} />
              <ScatterPanel title="HPT 共同工作线" data={steadyResult.batch.workingLines.HPT} color={linePalette[2]} />
              <ScatterPanel title="PT 共同工作线" data={steadyResult.batch.workingLines.PT} color={linePalette[3]} />
            </div>
            <Panel title="工况明细">
              <div className="detail-toolbar">
                <div className="select-group">
                  <label htmlFor="steady-run-select">当前工况</label>
                  <select id="steady-run-select" value={steadyRunIndex} onChange={(event) => setSteadyRunIndex(Number(event.target.value))}>
                    {steadyResult.runs.map((run, index) => <option key={run.inputPowerOutputW} value={index}>{formatNumber(run.inputPowerOutputW / 1_000_000, 2)} MW</option>)}
                  </select>
                </div>
                <button className="ghost-button" onClick={() => downloadText(`${projectName}-steady-points.csv`, rowsToCsv(steadyResult.batch.points as unknown as Array<Record<string, unknown>>), 'text/csv;charset=utf-8')}>导出批量结果 CSV</button>
              </div>
              {activeSteadyRun ? <>
                <StatsGrid items={[
                  { label: '输出功率', value: `${formatNumber(activeSteadyRun.summary.power_output_kw, 2)} kW` },
                  { label: '热效率', value: formatNumber(activeSteadyRun.summary.thermal_efficiency, 6) },
                  { label: 'Ng', value: `${formatNumber(activeSteadyRun.summary.ng_rpm, 2)} rpm` },
                  { label: '燃油流量', value: `${formatNumber(activeSteadyRun.summary.fuel_flow_kg_s, 4)} kg/s` },
                ]} />
                <StationTable rows={activeSteadyRun.stations} />
                <ObjectCards title="部件性能卡片" data={activeSteadyRun.componentPerformance} />
              </> : null}
            </Panel>
            {activeSteadyRun?.logs ? <Panel title="运行日志"><LogBlock text={activeSteadyRun.logs} /></Panel> : null}
          </> : <EmptyState title="还没有非设计点结果" text="先设置负载点列表，再运行非设计点计算。" />}
        />
      ) : null}

      {activeTab === 'transient' ? (
        <ModuleShell
          title="过渡态计算"
          controls={<>
            <Panel title="控制规律表">
              <div className="detail-toolbar detail-toolbar--stack">
                <button className="ghost-button" onClick={addLoadingRow}>添加行</button>
                <button className="ghost-button" onClick={() => scheduleInputRef.current?.click()}>导入 CSV</button>
                <button className="ghost-button" onClick={() => {
                  const rows = (loadingTable.time ?? []).map((time, index) => ({ time, Loading: loadingTable.Loading?.[index] ?? 0 }))
                  downloadText(`${projectName}-loading-table.csv`, rowsToCsv(rows), 'text/csv;charset=utf-8')
                }}>导出 CSV</button>
              </div>
              <div className="table-wrap"><table className="data-table"><thead><tr><th>时间 / s</th><th>负载 / MW</th><th>操作</th></tr></thead><tbody>
                {(loadingTable.time ?? []).map((time, index) => (
                  <tr key={`${time}-${index}`}>
                    <td><input className="table-input" type="number" step="0.01" value={time} onChange={(event) => updateLoadingRow(index, 'time', Number(event.target.value))} /></td>
                    <td><input className="table-input" type="number" step="0.01" value={loadingTable.Loading?.[index] ?? 0} onChange={(event) => updateLoadingRow(index, 'Loading', Number(event.target.value))} /></td>
                    <td><button className="table-button" onClick={() => removeLoadingRow(index)}>删除</button></td>
                  </tr>
                ))}
              </tbody></table></div>
            </Panel>
            {transientConfig ? transientSections.map((section, index) => <FieldSection key={section.title} config={transientConfig} section={section} defaultOpen={index === 0} onChange={patchConfig(setTransientConfig)} />) : null}
          </>}
          results={transientResult ? <>
            <StatsGrid items={[
              { label: '仿真时长', value: `${formatNumber(transientResult.summary.duration_s, 2)} s` },
              { label: '末时刻功率', value: `${formatNumber(transientResult.summary.final_power_kw, 2)} kW` },
              { label: '末时刻负载', value: `${formatNumber(transientResult.summary.final_load_kw, 2)} kW` },
              { label: '末时刻 T45', value: `${formatNumber(transientResult.summary.final_t45_k, 2)} K` },
            ]} />
            <div className="chart-layout chart-layout--transient">
              {Object.entries(transientResult.charts).map(([key, series], index) => <SeriesPanel key={key} title={chartTitleMap[key] ?? key} series={series} featured={index === 0} />)}
              <ScatterPanel title="HPC 运行轨迹" data={transientResult.mapTraces.HPC} color={linePalette[0]} xLabel="Wc" yLabel="PR" />
              <ScatterPanel title="HPT 运行轨迹" data={transientResult.mapTraces.HPT} color={linePalette[2]} xLabel="Wc" yLabel="PR" />
              <ScatterPanel title="PT 运行轨迹" data={transientResult.mapTraces.PT} color={linePalette[3]} xLabel="Wc" yLabel="PR" />
            </div>
            <Panel title="逐时刻结果预览">
              <div className="detail-toolbar">
                <span>当前预览前 60 行</span>
                <button className="ghost-button" onClick={() => downloadText(`${projectName}-transient-steps.csv`, rowsToCsv(transientResult.stepTable as unknown as Array<Record<string, unknown>>), 'text/csv;charset=utf-8')}>导出完整 CSV</button>
              </div>
              <KeyTable rows={deferredStepTable.slice(0, 60) as unknown as Array<Record<string, unknown>>} />
            </Panel>
            {transientResult.logs ? <Panel title="运行日志"><LogBlock text={transientResult.logs} /></Panel> : null}
          </> : <EmptyState title="还没有过渡态结果" text="先维护控制规律和控制参数，再运行过渡态计算。" />}
        />
      ) : null}

      {activeTab === 'adaptation' ? (
        <section className="overview-grid">
          <Panel title="模型自适应">
            <EmptyState title="模块待接入" text="当前后端未提供该模块的运行接口。" />
          </Panel>
          <Panel title="接入状态">
            <StatsGrid items={[
              { label: '前端位置', value: '已预留' },
              { label: '运行接口', value: '未接入' },
              { label: '数据导入', value: '待开发' },
              { label: '结果输出', value: '待开发' },
            ]} />
          </Panel>
        </section>
      ) : null}

      {activeTab === 'project' ? (
        <section className="overview-grid">
          <Panel title="项目文件管理">
            <div className="project-stack">
              <InlineInput label="项目名称" hint="本地保存时会作为文件名" value={projectName} onChange={setProjectName} />
              <div className="button-row">
                <button className="ghost-button" onClick={handleNewProject}>新建</button>
                <button className="ghost-button" onClick={() => projectInputRef.current?.click()}>打开</button>
                <button className="ghost-button" onClick={() => downloadJson(`${projectName}.json`, projectSnapshot)}>保存</button>
                <button className="ghost-button" onClick={() => downloadJson(`${projectName}-copy.json`, projectSnapshot)}>另存为</button>
              </div>
            </div>
            <StatsGrid items={[
              { label: '设计点结果', value: designResult ? '已写入项目' : '暂无' },
              { label: '非设计点结果', value: steadyResult ? '已写入项目' : '暂无' },
              { label: '过渡态结果', value: transientResult ? '已写入项目' : '暂无' },
              { label: '当前拓扑', value: selectedTopologyMeta?.name ?? '-' },
            ]} />
          </Panel>
          <Panel title="数据导出">
            <div className="button-row">
              <button className="ghost-button" disabled={!designResult} onClick={() => designResult && downloadText(`${projectName}-design-stations.csv`, rowsToCsv(designStations as unknown as Array<Record<string, unknown>>), 'text/csv;charset=utf-8')}>导出设计点站位表</button>
              <button className="ghost-button" disabled={!steadyResult} onClick={() => steadyResult && downloadText(`${projectName}-steady-points.csv`, rowsToCsv(steadyResult.batch.points as unknown as Array<Record<string, unknown>>), 'text/csv;charset=utf-8')}>导出非设计点结果</button>
              <button className="ghost-button" disabled={!transientResult} onClick={() => transientResult && downloadText(`${projectName}-transient-steps.csv`, rowsToCsv(transientResult.stepTable as unknown as Array<Record<string, unknown>>), 'text/csv;charset=utf-8')}>导出过渡态结果</button>
              <button className="ghost-button" disabled={!transientConfig} onClick={() => {
                const rows = (loadingTable.time ?? []).map((time, index) => ({ time, Loading: loadingTable.Loading?.[index] ?? 0 }))
                downloadText(`${projectName}-loading-table.csv`, rowsToCsv(rows), 'text/csv;charset=utf-8')
              }}>导出负载模板</button>
            </div>
            <details className="fold-card"><summary>查看当前项目 JSON 快照</summary><pre>{JSON.stringify(projectSnapshot, null, 2)}</pre></details>
          </Panel>
        </section>
      ) : null}

      <input ref={projectInputRef} type="file" accept=".json" hidden onChange={handleOpenProject} />
      <input ref={scheduleInputRef} type="file" accept=".csv,.txt" hidden onChange={handleImportLoadingTable} />
    </div>
  )
}

function ModuleShell(props: { title: string; controls: ReactNode; results: ReactNode }) {
  return (
    <section className="module-shell">
      <aside className="module-controls">
        <Panel title={props.title}>
          <div className="control-stack">{props.controls}</div>
        </Panel>
      </aside>
      <div className="module-results">{props.results}</div>
    </section>
  )
}

function Panel(props: { title: string; description?: string; children: ReactNode }) {
  return (
    <section className="panel">
      <div className="panel-header">
        <div>
          <h3>{props.title}</h3>
          {props.description ? <p>{props.description}</p> : null}
        </div>
      </div>
      {props.children}
    </section>
  )
}

function StatusPill(props: { active: boolean; children: ReactNode }) {
  return <span className={clsx('status-pill', { active: props.active })}>{props.children}</span>
}

function MetricTile(props: { label: string; value: string; accent: string }) {
  return (
    <div className="metric-tile" style={{ '--accent': props.accent } as CSSProperties}>
      <span>{props.label}</span>
      <strong>{props.value}</strong>
    </div>
  )
}

function StatsGrid(props: { items: Array<{ label: string; value: string }> }) {
  return (
    <div className="stats-grid">
      {props.items.map((item, index) => (
        <div key={item.label} className="stat-card" style={{ '--accent': statAccents[index % statAccents.length] } as CSSProperties}>
          <span>{item.label}</span>
          <strong>{item.value}</strong>
        </div>
      ))}
    </div>
  )
}

function InlineInfo(props: { label: string; value: string }) {
  return <div className="inline-info"><span>{props.label}</span><strong>{props.value}</strong></div>
}

function InlineInput(props: { label: string; hint?: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="inline-input">
      <span>{props.label}</span>
      <input value={props.value} onChange={(event) => props.onChange(event.target.value)} />
      {props.hint ? <small>{props.hint}</small> : null}
    </label>
  )
}

function FieldSection(props: { config: AnyRecord; section: SectionSpec; defaultOpen?: boolean; onChange: (path: string, value: unknown) => void }) {
  return (
    <details className="field-section" open={props.defaultOpen}>
      <summary>
        <span>{props.section.title}</span>
        {props.section.description ? <small>{props.section.description}</small> : null}
      </summary>
      <div className="field-grid">
        {props.section.fields.map((field) => {
          const rawValue = getByPath(props.config, field.path)
          const kind = field.kind ?? 'number'
          return (
            <label key={field.path} className="field-card">
              <span className="field-label">{field.label}</span>
              {kind === 'boolean' ? (
                <select value={numberValue(rawValue, 0)} onChange={(event) => props.onChange(field.path, Number(event.target.value))}>
                  <option value={1}>开启</option>
                  <option value={0}>关闭</option>
                </select>
              ) : kind === 'list' ? (
                <input type="text" value={listToText(rawValue)} onChange={(event) => props.onChange(field.path, parseNumericList(event.target.value))} />
              ) : (
                <input type="number" step={field.step ?? '0.001'} value={numberValue(rawValue, 0)} onChange={(event) => props.onChange(field.path, Number(event.target.value))} />
              )}
              <small>{field.unit ?? ' '}</small>
            </label>
          )
        })}
      </div>
    </details>
  )
}

function StationTable(props: { rows: StationRow[] }) {
  if (!props.rows.length) return <EmptyState title="没有站位表数据" text="当前结果没有返回站位表。" compact />
  return <KeyTable rows={props.rows as unknown as Array<Record<string, unknown>>} />
}

function KeyTable(props: { rows: Array<Record<string, unknown>> }) {
  if (!props.rows.length) return <EmptyState title="没有可显示的数据" text="当前区域没有返回表格数据。" compact />
  const headers = Object.keys(props.rows[0])
  return (
    <div className="table-wrap">
      <table className="data-table">
        <thead><tr>{headers.map((header) => <th key={header}>{header}</th>)}</tr></thead>
        <tbody>{props.rows.map((row, index) => <tr key={index}>{headers.map((header) => <td key={header}>{formatNumber(row[header], 4)}</td>)}</tr>)}</tbody>
      </table>
    </div>
  )
}

function ObjectCards(props: { title: string; data: Record<string, AnyRecord> }) {
  return (
    <Panel title={props.title}>
      <div className="object-grid">
        {Object.entries(props.data).map(([name, value]) => (
          <div key={name} className="object-card">
            <h4>{name}</h4>
            <div className="object-list">
              {flattenRecord(value).map(([key, item]) => (
                <div key={`${name}-${key}`} className="object-row">
                  <span>{key}</span>
                  <strong>{formatComponentValue(item)}</strong>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Panel>
  )
}

function LinePanel(props: { title: string; description?: string; rows: Array<Record<string, number>>; xKey: string; lines: Array<{ key: string; name: string; color: string }>; featured?: boolean }) {
  return (
    <div className={clsx('chart-panel', { featured: props.featured })}>
      <div className="chart-panel__head"><div><h4>{props.title}</h4>{props.description ? <p>{props.description}</p> : null}</div></div>
      <div className="chart-panel__body">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={props.rows}>
            <CartesianGrid strokeDasharray="3 3" stroke="#d4dce2" />
            <XAxis dataKey={props.xKey} stroke="#576b7a" />
            <YAxis stroke="#576b7a" />
            <Tooltip />
            <Legend />
            {props.lines.map((line) => <Line key={line.key} type="monotone" dataKey={line.key} name={line.name} stroke={line.color} strokeWidth={2.4} dot={false} />)}
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

function SeriesPanel(props: { title: string; description?: string; series: ChartSeries[]; featured?: boolean }) {
  const rows = useMemo(() => buildMergedChartRows(props.series), [props.series])
  return (
    <div className={clsx('chart-panel', { featured: props.featured })}>
      <div className="chart-panel__head"><div><h4>{props.title}</h4>{props.description ? <p>{props.description}</p> : null}</div></div>
      <div className="chart-panel__body">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={rows}>
            <CartesianGrid strokeDasharray="3 3" stroke="#d4dce2" />
            <XAxis dataKey="time" stroke="#576b7a" />
            <YAxis stroke="#576b7a" />
            <Tooltip />
            <Legend />
            {props.series.map((item, index) => <Line key={item.name} type="monotone" dataKey={item.name} name={`${item.name} (${item.unit})`} stroke={linePalette[index % linePalette.length]} strokeWidth={2.4} dot={false} />)}
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

function ScatterPanel(props: { title: string; data: ScatterTracePoint[]; color: string; xLabel?: string; yLabel?: string }) {
  return (
    <div className="chart-panel">
      <div className="chart-panel__head"><div><h4>{props.title}</h4><p>{props.xLabel ?? '流量'} / {props.yLabel ?? '压比'}</p></div></div>
      <div className="chart-panel__body">
        <ResponsiveContainer width="100%" height="100%">
          <ScatterChart>
            <CartesianGrid strokeDasharray="3 3" stroke="#d4dce2" />
            <XAxis type="number" dataKey="x" stroke="#576b7a" />
            <YAxis type="number" dataKey="y" stroke="#576b7a" />
            <Tooltip />
            <Scatter data={props.data} fill={props.color} line={{ stroke: props.color, strokeWidth: 2 }} />
          </ScatterChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

function EmptyState(props: { title: string; text: string; compact?: boolean }) {
  return <div className={clsx('empty-state', { compact: props.compact })}><strong>{props.title}</strong><p>{props.text}</p></div>
}

function LogBlock(props: { text: string }) {
  return <details className="fold-card"><summary>展开查看日志</summary><pre>{props.text}</pre></details>
}

function flattenRecord(source: AnyRecord, prefix = ''): Array<[string, unknown]> {
  return Object.entries(source).flatMap(([key, value]) => {
    const nextKey = prefix ? `${prefix}.${key}` : key
    if (value && typeof value === 'object' && !Array.isArray(value)) return flattenRecord(value as AnyRecord, nextKey)
    return [[nextKey, value]]
  })
}

function formatComponentValue(value: unknown): string {
  if (Array.isArray(value)) return value.join(', ')
  if (typeof value === 'number') return formatNumber(value, 4)
  if (typeof value === 'boolean') return value ? 'true' : 'false'
  if (value === null || value === undefined) return '-'
  return String(value)
}

export default App
