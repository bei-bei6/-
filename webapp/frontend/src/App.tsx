import { startTransition, useEffect, useMemo, useRef, useState, type Dispatch, type SetStateAction } from 'react'

import { AppShell } from './app/AppShell'
import { getTabMeta, tabs, type TabId } from './app/tabs'
import { MetricTile } from './components/data-display/MetricTile'
import { StatusPill } from './components/feedback/StatusPill'
import { TopologyScreen } from './features/topology/TopologyScreen'
import { DesignScreen } from './features/design/DesignScreen'
import { SteadyScreen } from './features/steady/SteadyScreen'
import { TransientScreen } from './features/transient/TransientScreen'
import { AdaptationScreen } from './features/adaptation/AdaptationScreen'
import { ProjectScreen } from './features/project/ProjectScreen'
import { fetchDefaults, fetchHealth, runDesignPoint, runSteadyState, runTransient } from './api'
import type {
  AnyRecord,
  DefaultsResponse,
  DesignPointResponse,
  HealthResponse,
  SteadyResponse,
  Topology,
  TransientResponse,
} from './types'
import {
  deepClone,
  downloadJson,
  downloadText,
  formatNumber,
  getByPath,
  numberValue,
  parseNumericList,
  parseScheduleCsv,
  readTextFile,
  rowsToCsv,
  setByPath,
} from './utils'

type BusyKey = 'bootstrap' | 'design' | 'steady' | 'transient' | null

const statAccents = ['#0f5b78', '#1d7f6d', '#d67a2d', '#295ea8']

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

  const selectedTopologyMeta = topologies.find((item) => item.id === selectedTopology) ?? null
  const activeTabMeta = getTabMeta(activeTab)
  const designStations = designResult?.summary.stations ?? []
  const loadingTable = ((transientConfig && getByPath(transientConfig, 'data.LoadingTable')) ?? {
    time: [],
    Loading: [],
  }) as { time?: number[]; Loading?: number[] }

  const projectSnapshot = useMemo(
    () => ({
      version: '2.0.0',
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
      uiState: {
        steadyLoadsText,
      },
    }),
    [
      designConfig,
      designResult,
      projectName,
      selectedTopology,
      steadyConfig,
      steadyLoadsText,
      steadyResult,
      transientConfig,
      transientResult,
    ],
  )

  const loadingRows = useMemo(
    () => (loadingTable.time ?? []).map((time, index) => ({ time, loading: loadingTable.Loading?.[index] ?? 0 })),
    [loadingTable.Loading, loadingTable.time],
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
    setActiveTab('topology')
    setError('')
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
        uiState?: { steadyLoadsText?: string }
      }

      const nextSteadyConfig = payload.config?.steadyState

      setProjectName(payload.projectName ?? file.name.replace(/\.json$/i, ''))
      setSelectedTopology(payload.selectedTopology ?? selectedTopology)
      if (payload.config?.designPoint) setDesignConfig(payload.config.designPoint)
      if (nextSteadyConfig) setSteadyConfig(nextSteadyConfig)
      if (payload.config?.transient) setTransientConfig(payload.config.transient)
      setDesignResult(payload.results?.designPoint ?? null)
      setSteadyResult(payload.results?.steadyState ?? null)
      setTransientResult(payload.results?.transient ?? null)
      setSteadyLoadsText(
        payload.uiState?.steadyLoadsText ??
          ((nextSteadyConfig ? numberValue(nextSteadyConfig.Power_output, 13_200_000) : 13_200_000) / 1_000_000).toString(),
      )
      setActiveTab('project')
      setError('')
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
      setTransientConfig((current) =>
        current ? setByPath(current, 'data.LoadingTable', table as unknown as AnyRecord) : current,
      )
      setActiveTab('transient')
      setError('')
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

  const exportProject = (filename = `${projectName}.json`) => {
    downloadJson(filename, projectSnapshot)
  }

  const exportLoadingTable = () => {
    const rows = loadingRows.map((row) => ({ time: row.time, Loading: row.loading }))
    downloadText(`${projectName}-loading-table.csv`, rowsToCsv(rows), 'text/csv;charset=utf-8')
  }

  const exportSteadyBatch = () => {
    if (!steadyResult) return
    downloadText(
      `${projectName}-steady-points.csv`,
      rowsToCsv(steadyResult.batch.points as unknown as Array<Record<string, unknown>>),
      'text/csv;charset=utf-8',
    )
  }

  const exportTransientSteps = () => {
    if (!transientResult) return
    downloadText(
      `${projectName}-transient-steps.csv`,
      rowsToCsv(transientResult.stepTable as unknown as Array<Record<string, unknown>>),
      'text/csv;charset=utf-8',
    )
  }

  const exportDesignStations = () => {
    if (!designStations.length) return
    downloadText(
      `${projectName}-design-stations.csv`,
      rowsToCsv(designStations as unknown as Array<Record<string, unknown>>),
      'text/csv;charset=utf-8',
    )
  }

  if (!defaults && busy === 'bootstrap') {
    return (
      <div className="app-loading">
        <div className="app-loading__card">
          <p className="eyebrow">系统初始化</p>
          <strong>正在加载系统参数…</strong>
          <span>请稍候。</span>
        </div>
      </div>
    )
  }

  return (
    <>
      <AppShell
        title="总体性能仿真控制台"
        description="用于燃气轮机设计点、非设计点与过渡态计算分析。"
        status={
          <>
            <StatusPill active={health?.runtimeInstalled ?? false} tone={health?.runtimeInstalled ? 'success' : 'warning'}>
              {health?.runtimeInstalled ? '运行环境正常' : '运行环境异常'}
            </StatusPill>
            <StatusPill active={selectedTopologyMeta?.available ?? false} tone={selectedTopologyMeta?.available ? 'success' : 'warning'}>
              {selectedTopologyMeta?.available ? '拓扑可用' : '拓扑不可用'}
            </StatusPill>
          </>
        }
        mastheadActions={
          <>
            <button className="ghost-button" onClick={handleNewProject} disabled={!defaults || busy !== null}>
              新建项目
            </button>
            <button className="ghost-button" onClick={() => projectInputRef.current?.click()} disabled={busy !== null}>
              打开项目
            </button>
            <button className="ghost-button" onClick={() => exportProject()}>
              保存项目
            </button>
          </>
        }
        commandTitle={projectName}
        commandDescription={activeTabMeta.description}
        contextTags={[
          selectedTopologyMeta?.name ?? '未选择拓扑',
          health?.runtimeInstalled ? '运行环境正常' : '运行环境异常',
          activeTabMeta.label,
        ]}
        commandActions={
          <>
            <button className="primary-button" onClick={handleRunDesign} disabled={!designConfig || busy !== null}>
              {busy === 'design' ? '设计点计算中...' : '运行设计点'}
            </button>
            <button className="secondary-button" onClick={handleRunSteady} disabled={!steadyConfig || busy !== null}>
              {busy === 'steady' ? '非设计点计算中...' : '运行非设计点'}
            </button>
            <button className="secondary-button" onClick={handleRunTransient} disabled={!transientConfig || busy !== null}>
              {busy === 'transient' ? '过渡态计算中...' : '运行过渡态'}
            </button>
          </>
        }
        metrics={
          <>
            <MetricTile label="当前拓扑" value={selectedTopologyMeta?.name ?? '-'} accent={statAccents[0]} detail="当前模型" />
            <MetricTile
              label="稳态默认功率"
              value={`${formatNumber(numberValue(steadyConfig?.Power_output, 0) / 1_000_000, 2)} MW`}
              accent={statAccents[1]}
              detail="默认设定"
            />
            <MetricTile
              label="动态时长"
              value={`${formatNumber(getByPath(transientConfig ?? {}, 'data.time'), 2)} s`}
              accent={statAccents[2]}
              detail="当前设定"
            />
            <MetricTile label="计算模式" value="设计点 / 稳态 / 动态" accent={statAccents[3]} detail="当前可用" />
          </>
        }
        tabs={tabs}
        activeTab={activeTab}
        onTabChange={setActiveTab}
        busyMessage={busy && busy !== 'bootstrap' ? '计算进行中，请稍候...' : undefined}
        errorMessage={error || undefined}
      >
        {activeTab === 'topology' ? (
          <TopologyScreen
            topologies={topologies}
            selectedTopology={selectedTopology}
            onSelect={setSelectedTopology}
            runtimeInstalled={health?.runtimeInstalled ?? false}
            designReady={Boolean(designResult)}
            steadyReady={Boolean(steadyResult)}
            transientReady={Boolean(transientResult)}
          />
        ) : null}

        {activeTab === 'design' ? (
          <DesignScreen config={designConfig} result={designResult} onChange={patchConfig(setDesignConfig)} />
        ) : null}

        {activeTab === 'steady' ? (
          <SteadyScreen
            config={steadyConfig}
            loadsText={steadyLoadsText}
            onLoadsChange={setSteadyLoadsText}
            result={steadyResult}
            activeRunIndex={steadyRunIndex}
            onActiveRunChange={setSteadyRunIndex}
            onChange={patchConfig(setSteadyConfig)}
            onExportBatchCsv={exportSteadyBatch}
          />
        ) : null}

        {activeTab === 'transient' ? (
          <TransientScreen
            config={transientConfig}
            result={transientResult}
            loadingRows={loadingRows}
            onChange={patchConfig(setTransientConfig)}
            onAddLoadingRow={addLoadingRow}
            onRemoveLoadingRow={removeLoadingRow}
            onUpdateLoadingRow={updateLoadingRow}
            onImportLoadingTable={() => scheduleInputRef.current?.click()}
            onExportLoadingTable={exportLoadingTable}
            onExportStepTable={exportTransientSteps}
          />
        ) : null}

        {activeTab === 'adaptation' ? <AdaptationScreen /> : null}

        {activeTab === 'project' ? (
          <ProjectScreen
            projectName={projectName}
            topologyName={selectedTopologyMeta?.name ?? '-'}
            projectSnapshot={projectSnapshot}
            designResult={designResult}
            steadyResult={steadyResult}
            transientResult={transientResult}
            onProjectNameChange={setProjectName}
            onNewProject={handleNewProject}
            onOpenProject={() => projectInputRef.current?.click()}
            onSaveProject={() => exportProject()}
            onSaveProjectAs={() => exportProject(`${projectName}-copy.json`)}
            onExportDesignStations={exportDesignStations}
            onExportSteadyPoints={exportSteadyBatch}
            onExportTransientSteps={exportTransientSteps}
            onExportLoadingTable={exportLoadingTable}
          />
        ) : null}
      </AppShell>

      <input ref={projectInputRef} type="file" accept=".json" hidden onChange={handleOpenProject} />
      <input ref={scheduleInputRef} type="file" accept=".csv,.txt" hidden onChange={handleImportLoadingTable} />
    </>
  )
}

export default App
