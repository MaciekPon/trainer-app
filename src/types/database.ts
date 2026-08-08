// Ręcznie napisane typy odzwierciedlające migracje w supabase/migrations.
// Docelowo zastąp je wygenerowanymi:
//   npx supabase gen types typescript --project-id <project-ref> > src/types/database.ts

export type Role = 'trainer' | 'client'

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          role: Role
          full_name: string
          created_at: string
        }
        Insert: {
          id: string
          role: Role
          full_name: string
          created_at?: string
        }
        Update: Partial<{
          full_name: string
        }>
        Relationships: []
      }
      invite_links: {
        Row: {
          id: string
          trainer_id: string
          token: string
          used: boolean
          expires_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          trainer_id: string
          token?: string
          used?: boolean
          expires_at?: string | null
          created_at?: string
        }
        Update: Partial<{
          used: boolean
          expires_at: string | null
        }>
        Relationships: []
      }
      client_trainer: {
        Row: {
          trainer_id: string
          client_id: string
          created_at: string
        }
        Insert: {
          trainer_id: string
          client_id: string
          created_at?: string
        }
        Update: Record<string, never>
        Relationships: []
      }
      training_plans: {
        Row: {
          id: string
          client_id: string
          trainer_id: string
          name: string
          created_at: string
        }
        Insert: {
          id?: string
          client_id: string
          trainer_id: string
          name: string
          created_at?: string
        }
        Update: Partial<{
          name: string
        }>
        Relationships: []
      }
      plan_days: {
        Row: {
          id: string
          plan_id: string
          name: string
          position: number
          created_at: string
        }
        Insert: {
          id?: string
          plan_id: string
          name: string
          position?: number
          created_at?: string
        }
        Update: Partial<{
          name: string
          position: number
        }>
        Relationships: []
      }
      plan_exercises: {
        Row: {
          id: string
          plan_day_id: string
          exercise_name: string
          target_sets: number
          target_reps: number
          notes: string | null
          position: number
          created_at: string
        }
        Insert: {
          id?: string
          plan_day_id: string
          exercise_name: string
          target_sets: number
          target_reps: number
          notes?: string | null
          position?: number
          created_at?: string
        }
        Update: Partial<{
          exercise_name: string
          target_sets: number
          target_reps: number
          notes: string | null
          position: number
        }>
        Relationships: []
      }
      workout_sessions: {
        Row: {
          id: string
          client_id: string
          plan_day_id: string | null
          performed_at: string
          notes: string | null
          created_at: string
        }
        Insert: {
          id?: string
          client_id: string
          plan_day_id?: string | null
          performed_at?: string
          notes?: string | null
          created_at?: string
        }
        Update: Partial<{
          plan_day_id: string | null
          performed_at: string
          notes: string | null
        }>
        Relationships: []
      }
      workout_set_logs: {
        Row: {
          id: string
          session_id: string
          plan_exercise_id: string | null
          exercise_name: string
          set_number: number
          weight: number | null
          reps: number | null
          rpe: number | null
          created_at: string
        }
        Insert: {
          id?: string
          session_id: string
          plan_exercise_id?: string | null
          exercise_name: string
          set_number: number
          weight?: number | null
          reps?: number | null
          rpe?: number | null
          created_at?: string
        }
        Update: Partial<{
          exercise_name: string
          set_number: number
          weight: number | null
          reps: number | null
          rpe: number | null
        }>
        Relationships: []
      }
      measurements: {
        Row: {
          id: string
          client_id: string
          waist: number | null
          hips: number | null
          chest: number | null
          arm: number | null
          thigh: number | null
          weight: number | null
          measured_at: string
          created_at: string
        }
        Insert: {
          id?: string
          client_id: string
          waist?: number | null
          hips?: number | null
          chest?: number | null
          arm?: number | null
          thigh?: number | null
          weight?: number | null
          measured_at?: string
          created_at?: string
        }
        Update: Partial<{
          waist: number | null
          hips: number | null
          chest: number | null
          arm: number | null
          thigh: number | null
          weight: number | null
          measured_at: string
        }>
        Relationships: []
      }
      nutrition_targets: {
        Row: {
          id: string
          client_id: string
          calories: number
          protein_g: number | null
          carbs_g: number | null
          fat_g: number | null
          valid_from: string
          created_at: string
        }
        Insert: {
          id?: string
          client_id: string
          calories: number
          protein_g?: number | null
          carbs_g?: number | null
          fat_g?: number | null
          valid_from?: string
          created_at?: string
        }
        Update: Partial<{
          calories: number
          protein_g: number | null
          carbs_g: number | null
          fat_g: number | null
          valid_from: string
        }>
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      validate_invite_token: {
        Args: { p_token: string }
        Returns: { trainer_id: string; is_valid: boolean }[]
      }
      accept_invite: {
        Args: { p_token: string }
        Returns: void
      }
      is_trainer_of: {
        Args: { client_uuid: string }
        Returns: boolean
      }
    }
  }
}
