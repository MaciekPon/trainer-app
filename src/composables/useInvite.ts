import { useMutation } from '@tanstack/vue-query'
import { supabase } from '@/lib/supabase'

export function useGenerateInviteLink() {
  return useMutation({
    mutationFn: async (trainerId: string) => {
      const { data, error } = await supabase
        .from('invite_links')
        .insert({ trainer_id: trainerId })
        .select('token')
        .single()

      if (error) throw error

      const url = new URL('/accept-invite', window.location.origin)
      url.searchParams.set('token', data.token)
      return url.toString()
    },
  })
}
