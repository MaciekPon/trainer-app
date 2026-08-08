-- ============================================
-- ROZSZERZENIA
-- ============================================
create extension if not exists "pgcrypto";

-- ============================================
-- TABELE
-- ============================================

-- Profile użytkowników (trener lub podopieczny)
-- id jest tym samym co auth.users.id
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('trainer', 'client')),
  full_name text not null,
  created_at timestamptz not null default now()
);

-- Linki zaproszeń generowane przez trenera
create table public.invite_links (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique default encode(gen_random_bytes(16), 'hex'),
  used boolean not null default false,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

-- Relacja trener <-> podopieczny
create table public.client_trainer (
  trainer_id uuid not null references public.profiles(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (trainer_id, client_id)
);

-- Plany treningowe
create table public.training_plans (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  trainer_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

-- Ćwiczenia w planie
create table public.plan_exercises (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.training_plans(id) on delete cascade,
  exercise_name text not null,
  sets int not null,
  reps int not null,
  notes text,
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- Logi treningowe (rzeczywiste wykonanie przez podopiecznego)
create table public.workout_logs (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  plan_exercise_id uuid references public.plan_exercises(id) on delete set null,
  exercise_name text not null,
  weight numeric,
  sets int,
  reps int,
  logged_at date not null default current_date,
  created_at timestamptz not null default now()
);

-- Pomiary obwodów ciała
create table public.measurements (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  waist numeric,
  hips numeric,
  chest numeric,
  arm numeric,
  thigh numeric,
  weight numeric,
  measured_at date not null default current_date,
  created_at timestamptz not null default now()
);

-- Cele kaloryczne
create table public.nutrition_targets (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  calories int not null,
  protein_g int,
  carbs_g int,
  fat_g int,
  valid_from date not null default current_date,
  created_at timestamptz not null default now()
);

-- ============================================
-- INDEKSY
-- ============================================
create index idx_invite_links_token on public.invite_links(token);
create index idx_invite_links_trainer on public.invite_links(trainer_id);
create index idx_client_trainer_trainer on public.client_trainer(trainer_id);
create index idx_client_trainer_client on public.client_trainer(client_id);
create index idx_training_plans_client on public.training_plans(client_id);
create index idx_plan_exercises_plan on public.plan_exercises(plan_id);
create index idx_workout_logs_client on public.workout_logs(client_id, logged_at);
create index idx_measurements_client on public.measurements(client_id, measured_at);
create index idx_nutrition_targets_client on public.nutrition_targets(client_id, valid_from);

-- ============================================
-- FUNKCJA POMOCNICZA: czy jestem trenerem danego klienta
-- ============================================
create or replace function public.is_trainer_of(client_uuid uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.client_trainer
    where trainer_id = auth.uid() and client_id = client_uuid
  );
$$;

-- ============================================
-- RLS: włączenie
-- ============================================
alter table public.profiles enable row level security;
alter table public.invite_links enable row level security;
alter table public.client_trainer enable row level security;
alter table public.training_plans enable row level security;
alter table public.plan_exercises enable row level security;
alter table public.workout_logs enable row level security;
alter table public.measurements enable row level security;
alter table public.nutrition_targets enable row level security;

-- ============================================
-- RLS: PROFILES
-- ============================================
create policy "widzę własny profil"
  on public.profiles for select
  using (id = auth.uid());

create policy "trener widzi profile swoich podopiecznych"
  on public.profiles for select
  using (public.is_trainer_of(id));

create policy "mogę stworzyć własny profil"
  on public.profiles for insert
  with check (id = auth.uid());

create policy "mogę edytować własny profil"
  on public.profiles for update
  using (id = auth.uid());

-- ============================================
-- RLS: INVITE_LINKS
-- ============================================
create policy "trener zarządza własnymi linkami"
  on public.invite_links for all
  using (trainer_id = auth.uid())
  with check (trainer_id = auth.uid());

-- publiczny odczyt tokenu (do walidacji linku przy rejestracji, bez ujawniania listy)
create policy "każdy może sprawdzić pojedynczy token"
  on public.invite_links for select
  using (true);

-- ============================================
-- RLS: CLIENT_TRAINER
-- ============================================
create policy "trener widzi swoje relacje"
  on public.client_trainer for select
  using (trainer_id = auth.uid());

create policy "klient widzi swoje relacje"
  on public.client_trainer for select
  using (client_id = auth.uid());

create policy "wstawianie relacji przez trenera lub siebie samego"
  on public.client_trainer for insert
  with check (trainer_id = auth.uid() or client_id = auth.uid());

-- ============================================
-- RLS: TRAINING_PLANS
-- ============================================
create policy "trener zarządza planami swoich podopiecznych"
  on public.training_plans for all
  using (trainer_id = auth.uid())
  with check (trainer_id = auth.uid());

create policy "klient widzi swoje plany"
  on public.training_plans for select
  using (client_id = auth.uid());

-- ============================================
-- RLS: PLAN_EXERCISES
-- ============================================
create policy "trener zarządza ćwiczeniami w planach swoich podopiecznych"
  on public.plan_exercises for all
  using (
    exists (
      select 1 from public.training_plans
      where id = plan_exercises.plan_id and trainer_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.training_plans
      where id = plan_exercises.plan_id and trainer_id = auth.uid()
    )
  );

create policy "klient widzi ćwiczenia w swoich planach"
  on public.plan_exercises for select
  using (
    exists (
      select 1 from public.training_plans
      where id = plan_exercises.plan_id and client_id = auth.uid()
    )
  );

-- ============================================
-- RLS: WORKOUT_LOGS
-- ============================================
create policy "trener widzi logi swoich podopiecznych"
  on public.workout_logs for select
  using (public.is_trainer_of(client_id));

create policy "klient zarządza własnymi logami"
  on public.workout_logs for all
  using (client_id = auth.uid())
  with check (client_id = auth.uid());

-- ============================================
-- RLS: MEASUREMENTS
-- ============================================
create policy "trener zarządza pomiarami swoich podopiecznych"
  on public.measurements for all
  using (public.is_trainer_of(client_id))
  with check (public.is_trainer_of(client_id));

create policy "klient widzi własne pomiary"
  on public.measurements for select
  using (client_id = auth.uid());

-- ============================================
-- RLS: NUTRITION_TARGETS
-- ============================================
create policy "trener zarządza celami kalorycznymi swoich podopiecznych"
  on public.nutrition_targets for all
  using (public.is_trainer_of(client_id))
  with check (public.is_trainer_of(client_id));

create policy "klient widzi własne cele kaloryczne"
  on public.nutrition_targets for select
  using (client_id = auth.uid());
