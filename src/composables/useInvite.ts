import { useMutation } from '@tanstack/vue-query'
import { supabase } from '@/lib/supabase'
import router from '@/router'

export function useGenerateInviteLink() {
  return useMutation({
    mutationFn: async (trainerId: string) => {
      const { data, error } = await supabase
        .from('invite_links')
        .insert({ trainer_id: trainerId })
        .select('token')
        .single()

      if (error) throw error

      // router.resolve uwzględnia base path (np. /trainer-app/ na GitHub Pages)
      const path = router.resolve({ name: 'accept-invite', query: { token: data.token } }).href
      return new URL(path, window.location.origin).toString()
    },
  })
}
