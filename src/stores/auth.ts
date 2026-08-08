import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database'

type Profile = Database['public']['Tables']['profiles']['Row']

export const useAuthStore = defineStore('auth', () => {
  const session = ref<Session | null>(null)
  const profile = ref<Profile | null>(null)
  const initialized = ref(false)

  async function loadProfile(userId: string) {
    const { data, error } = await supabase.from('profiles').select('*').eq('id', userId).maybeSingle()
    if (error) throw error
    profile.value = data
  }

  async function init() {
    if (initialized.value) return
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    if (session.value) {
      await loadProfile(session.value.user.id)
    }
    supabase.auth.onAuthStateChange(async (_event, newSession) => {
      session.value = newSession
      profile.value = newSession ? await fetchProfileSafe(newSession.user.id) : null
    })
    initialized.value = true
  }

  async function fetchProfileSafe(userId: string) {
    const { data } = await supabase.from('profiles').select('*').eq('id', userId).maybeSingle()
    return data
  }

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  // Profil (rola + imię i nazwisko) jest tworzony po stronie bazy przez trigger
  // na auth.users (zob. supabase/migrations/0003_profile_on_signup_trigger.sql)
  // na podstawie metadanych przekazanych tutaj — działa niezależnie od tego,
  // czy sesja wraca od razu, czy dopiero po potwierdzeniu e-maila.
  async function signUpTrainer(email: string, password: string, fullName: string) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { role: 'trainer', full_name: fullName } },
    })
    if (error) throw error
    if (!data.user) throw new Error('Rejestracja nie powiodła się')

    session.value = data.session
    if (data.session) {
      await loadProfile(data.user.id)
    }
  }

  async function signOut() {
    await supabase.auth.signOut()
    session.value = null
    profile.value = null
  }

  return { session, profile, initialized, init, signIn, signUpTrainer, signOut }
})
