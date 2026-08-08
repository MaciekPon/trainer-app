import { computed, type Ref } from 'vue'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database'

type MeasurementInsert = Database['public']['Tables']['measurements']['Insert']

export function useMeasurements(clientId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['measurements', clientId],
    enabled: computed(() => !!clientId.value),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('measurements')
        .select('*')
        .eq('client_id', clientId.value as string)
        .order('measured_at', { ascending: true })
      if (error) throw error
      return data
    },
  })
}

export function useCreateMeasurement(clientId: Ref<string | undefined>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: Omit<MeasurementInsert, 'client_id'>) => {
      const { data, error } = await supabase
        .from('measurements')
        .insert({ ...input, client_id: clientId.value as string })
        .select('*')
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['measurements', clientId.value] })
    },
  })
}

export interface WorkoutSessionWithSets {
  id: string
  client_id: string
  plan_day_id: string | null
  performed_at: string
  notes: string | null
  workout_set_logs: {
    id: string
    exercise_name: string
    set_number: number
    weight: number | null
    reps: number | null
    rpe: number | null
  }[]
}

export function useWorkoutSessions(clientId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['workout-sessions', clientId],
    enabled: computed(() => !!clientId.value),
    queryFn: async (): Promise<WorkoutSessionWithSets[]> => {
      const { data, error } = await supabase
        .from('workout_sessions')
        .select('*, workout_set_logs(*)')
        .eq('client_id', clientId.value as string)
        .order('performed_at', { ascending: true })
      if (error) throw error
      return data as unknown as WorkoutSessionWithSets[]
    },
  })
}

// Objętość treningowa sesji = suma (ciężar * powtórzenia) po wszystkich seriach.
export function sessionVolume(session: WorkoutSessionWithSets): number {
  return session.workout_set_logs.reduce((sum, set) => sum + (set.weight ?? 0) * (set.reps ?? 0), 0)
}

// Trend względem poprzedniej sesji tego samego dnia planu (np. ten sam "Dzień A").
export function useVolumeTrend(sessions: Ref<WorkoutSessionWithSets[] | undefined>) {
  return computed(() => {
    const list = sessions.value ?? []
    return list.map((session, index) => {
      const previousSameDay = [...list]
        .slice(0, index)
        .reverse()
        .find((s) => s.plan_day_id && s.plan_day_id === session.plan_day_id)

      const volume = sessionVolume(session)
      const previousVolume = previousSameDay ? sessionVolume(previousSameDay) : null
      const deltaPct =
        previousVolume && previousVolume > 0 ? ((volume - previousVolume) / previousVolume) * 100 : null

      return { session, volume, deltaPct }
    })
  })
}
