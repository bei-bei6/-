import type { SectionSpec } from '../../components/forms/types'

export const designSections: SectionSpec[] = [
  {
    title: '环境与进口',
    description: '定义入口环境条件与进口恢复参数。',
    fields: [
      { label: '环境温度', path: 'Amb.T', unit: 'K', step: '0.01' },
      { label: '环境压力', path: 'Amb.P', unit: 'Pa', step: '1' },
      { label: '进口流量', path: 'inlet.W', unit: 'kg/s', step: '0.01' },
      { label: '总压恢复系数', path: 'inlet.PR', unit: '-', step: '0.0001' },
    ],
  },
  {
    title: '压气机与燃烧室',
    description: '调整核心气路与燃烧段的关键参数。',
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
    description: '配置高压轴与动力轴的核心设计参数。',
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
