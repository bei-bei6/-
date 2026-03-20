import type { SectionSpec } from '../../components/forms/types'

export const transientSections: SectionSpec[] = [
  {
    title: '动态边界',
    description: '设置仿真时域、入口条件与加载方式。',
    fields: [
      { label: '环境温度', path: 'data.T0', unit: 'K', step: '0.01' },
      { label: '环境压力', path: 'data.P0', unit: 'Pa', step: '1' },
      { label: '初始动力轴转速', path: 'data.PT_Shaft', unit: 'rpm', step: '1' },
      { label: '仿真时长', path: 'data.time', unit: 's', step: '0.01' },
      { label: '时间步长', path: 'data.deltat', unit: 's', step: '0.001' },
      { label: '负载方式', path: 'data.loadingmethod', unit: '1 / 3 / 4', step: '1' },
    ],
  },
  {
    title: '控制器',
    description: '定义需求转速和双环 PI 控制参数。',
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
