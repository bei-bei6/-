export type FieldKind = 'number' | 'boolean' | 'list'

export interface FieldSpec {
  label: string
  path: string
  unit?: string
  kind?: FieldKind
  step?: string
  hint?: string
  placeholder?: string
}

export interface SectionSpec {
  title: string
  description?: string
  fields: FieldSpec[]
}
