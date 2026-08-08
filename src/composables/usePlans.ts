import { computed, type Ref } from 'vue'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database'

type PlanExerciseInsert = Database['public']['Tables']['plan_exercises']['Insert']
type PlanExerciseUpdate = Database['public']['Tables']['plan_exercises']['Update']

export function useTrainingPlans(clientId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['training-plans', clientId],
    enabled: computed(() => !!clientId.value),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('training_plans')
        .select('*')
        .eq('client_id', clientId.value as string)
        .order('created_at', { ascending: false })
      if (error) throw error
      return data
    },
  })
}

export function useTrainingPlan(planId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['training-plan', planId],
    enabled: computed(() => !!planId.value),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('training_plans')
        .select('*')
        .eq('id', planId.value as string)
        .single()
      if (error) throw error
      return data
    },
  })
}

export function useCreateTrainingPlan() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { clientId: string; trainerId: string; name: string }) => {
      const { data, error } = await supabase
        .from('training_plans')
        .insert({ client_id: input.clientId, trainer_id: input.trainerId, name: input.name })
        .select('*')
        .single()
      if (error) throw error
      return data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['training-plans', variables.clientId] })
    },
  })
}

export function usePlanDays(planId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['plan-days', planId],
    enabled: computed(() => !!planId.value),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('plan_days')
        .select('*')
        .eq('plan_id', planId.value as string)
        .order('position', { ascending: true })
      if (error) throw error
      return data
    },
  })
}

export function useCreatePlanDay(planId: Ref<string | undefined>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { name: string; position: number }) => {
      const { data, error } = await supabase
        .from('plan_days')
        .insert({ plan_id: planId.value as string, name: input.name, position: input.position })
        .select('*')
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plan-days', planId.value] })
    },
  })
}

export function useDeletePlanDay(planId: Ref<string | undefined>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (planDayId: string) => {
      const { error } = await supabase.from('plan_days').delete().eq('id', planDayId)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plan-days', planId.value] })
    },
  })
}

export function usePlanExercises(planDayId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['plan-exercises', planDayId],
    enabled: computed(() => !!planDayId.value),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('plan_exercises')
        .select('*')
        .eq('plan_day_id', planDayId.value as string)
        .order('position', { ascending: true })
      if (error) throw error
      return data
    },
  })
}

export function useCreatePlanExercise(planDayId: Ref<string | undefined>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: Omit<PlanExerciseInsert, 'plan_day_id'>) => {
      const { data, error } = await supabase
        .from('plan_exercises')
        .insert({ ...input, plan_day_id: planDayId.value as string })
        .select('*')
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plan-exercises', planDayId.value] })
    },
  })
}

export function useUpdatePlanExercise(planDayId: Ref<string | undefined>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { id: string; changes: PlanExerciseUpdate }) => {
      const { error } = await supabase.from('plan_exercises').update(input.changes).eq('id', input.id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plan-exercises', planDayId.value] })
    },
  })
}

export function useDeletePlanExercise(planDayId: Ref<string | undefined>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (exerciseId: string) => {
      const { error } = await supabase.from('plan_exercises').delete().eq('id', exerciseId)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plan-exercises', planDayId.value] })
    },
  })
}
