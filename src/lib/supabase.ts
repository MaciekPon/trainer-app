import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Brak VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY — skopiuj .env.example do .env.local i uzupełnij wartości.',
  )
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey)
