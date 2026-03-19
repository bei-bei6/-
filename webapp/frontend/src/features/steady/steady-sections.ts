import type { SectionSpec } from '../../components/forms/types'

export const steadySections: SectionSpec[] = [
  {
    title: '工况目标',
    description: '定义本次稳态求解的边界条件和目标功率。',
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
    description: '控制修正开关和附加损失项。',
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
