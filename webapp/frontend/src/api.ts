import axios from 'axios'

import type {
  AnyRecord,
  DefaultsResponse,
  DesignPointResponse,
  HealthResponse,
  SteadyResponse,
  TransientResponse,
} from './types'

const client = axios.create({
  baseURL: import.meta.env.VITE_API_BASE ?? '',
  timeout: 3_600_000,
})

function normalizeError(error: unknown): Error {
  if (axios.isAxiosError(error)) {
    const detail = error.response?.data?.detail
    if (typeof detail === 'string' && detail.trim()) {
      return new Error(detail)
    }
    return new Error(error.message)
  }
  return error instanceof Error ? error : new Error('Unknown request error')
}

export async function fetchHealth(): Promise<HealthResponse> {
  try {
    const { data } = await client.get<HealthResponse>('/api/health')
    return data
  } catch (error) {
    throw normalizeError(error)
  }
}

export async function fetchDefaults(): Promise<DefaultsResponse> {
  try {
    const { data } = await client.get<DefaultsResponse>('/api/defaults')
    return data
  } catch (error) {
    throw normalizeError(error)
  }
}

export async function runDesignPoint(config: AnyRecord): Promise<DesignPointResponse> {
  try {
    const { data } = await client.post<DesignPointResponse>('/api/design-point/run', { config })
    return data
  } catch (error) {
    throw normalizeError(error)
  }
}

export async function runSteadyState(
  config: AnyRecord,
  powerOutputs?: number[],
): Promise<SteadyResponse> {
  try {
    const { data } = await client.post<SteadyResponse>('/api/steady/run', {
      config,
      powerOutputs,
    })
    return data
  } catch (error) {
    throw normalizeError(error)
  }
}

export async function runTransient(config: AnyRecord): Promise<TransientResponse> {
  try {
    const { data } = await client.post<TransientResponse>('/api/transient/run', { config })
    return data
  } catch (error) {
    throw normalizeError(error)
  }
}
