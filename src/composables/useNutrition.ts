import { computed, type Ref } from 'vue'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database'

type NutritionTargetInsert = Database['public']['Tables']['nutrition_targets']['Insert']

export function useNutritionTargets(clientId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['nutrition-targets', clientId],
    enabled: computed(() => !!clientId.value),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('nutrition_targets')
        .select('*')
        .eq('client_id', clientId.value as string)
        .order('valid_from', { ascending: false })
      if (error) throw error
      return data
    },
  })
}

export function useCreateNutritionTarget(clientId: Ref<string | undefined>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: Omit<NutritionTargetInsert, 'client_id'>) => {
      const { data, error } = await supabase
        .from('nutrition_targets')
        .insert({ ...input, client_id: clientId.value as string })
        .select('*')
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nutrition-targets', clientId.value] })
    },
  })
}
