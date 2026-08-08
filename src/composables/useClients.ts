import { computed, type Ref } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { supabase } from '@/lib/supabase'

export interface ClientListItem {
  client_id: string
  full_name: string
  created_at: string
}

export function useClients(trainerId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['clients', trainerId],
    enabled: computed(() => !!trainerId.value),
    queryFn: async (): Promise<ClientListItem[]> => {
      const { data, error } = await supabase
        .from('client_trainer')
        .select('client_id, created_at, profiles!client_trainer_client_id_fkey(full_name)')
        .eq('trainer_id', trainerId.value as string)
        .order('created_at', { ascending: false })

      if (error) throw error

      return (data ?? []).map((row) => ({
        client_id: row.client_id,
        created_at: row.created_at,
        full_name: (row.profiles as unknown as { full_name: string } | null)?.full_name ?? '—',
      }))
    },
  })
}

export function useClientProfile(clientId: Ref<string | undefined>) {
  return useQuery({
    queryKey: ['client-profile', clientId],
    enabled: computed(() => !!clientId.value),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', clientId.value as string)
        .single()
      if (error) throw error
      return data
    },
  })
}
