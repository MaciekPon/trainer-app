-- ============================================
-- 0002: poprawki bezpieczeństwa zaproszeń,
-- ochrona roli profilu, plany dzień/tydzień + logi per seria
-- ============================================

-- ============================================
-- 1) BEZPIECZEŃSTWO ZAPROSZEŃ
-- ============================================

-- usuwamy blanket-select, który ujawniał całą tabelę invite_links
drop policy if exists "każdy może sprawdzić pojedynczy token" on public.invite_links;

-- walidacja tokenu bez ujawniania reszty tabeli
create or replace function public.validate_invite_token(p_token text)
returns table (trainer_id uuid, is_valid boolean)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select il.trainer_id,
         (il.id is not null and not il.used and (il.expires_at is null or il.expires_at > now()))
  from public.invite_links il
  where il.token = p_token;
end;
$$;

grant execute on function public.validate_invite_token(text) to anon, authenticated;

-- akceptacja zaproszenia: waliduje token, tworzy relację client_trainer, oznacza token jako użyty
create or replace function public.accept_invite(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.invite_links%rowtype;
begin
  select * into v_invite
  from public.invite_links
  where token = p_token
  for update;

  if not found then
    raise exception 'Nieprawidłowy link zaproszenia';
  end if;

  if v_invite.used then
    raise exception 'Link zaproszenia został już wykorzystany';
  end if;

  if v_invite.expires_at is not null and v_invite.expires_at <= now() then
    raise exception 'Link zaproszenia wygasł';
  end if;

  insert into public.client_trainer (trainer_id, client_id)
  values (v_invite.trainer_id, auth.uid());

  update public.invite_links set used = true where id = v_invite.id;
end;
$$;

grant execute on function public.accept_invite(text) to authenticated;

-- insert do client_trainer tylko przez trenera (ręczne dodanie) lub przez accept_invite (security definer, omija RLS)
drop policy if exists "wstawianie relacji przez trenera lub siebie samego" on public.client_trainer;

create policy "trener ręcznie dodaje relację"
  on public.client_trainer for insert
  with check (trainer_id = auth.uid());

-- ============================================
-- 2) OCHRONA ROLI PROFILU
-- ============================================
create or replace function public.prevent_role_change()
returns trigger
language plpgsql
as $$
begin
  if new.role <> old.role then
    raise exception 'Zmiana roli profilu jest niedozwolona';
  end if;
  return new;
end;
$$;

create trigger trg_prevent_role_change
  before update on public.profiles
  for each row
  execute function public.prevent_role_change();

-- ============================================
-- 3) PLANY: DNI + ĆWICZENIA
-- ============================================
create table public.plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.training_plans(id) on delete cascade,
  name text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create index idx_plan_days_plan on public.plan_days(plan_id);

alter table public.plan_days enable row level security;

create policy "trener zarządza dniami planów swoich podopiecznych"
  on public.plan_days for all
  using (
    exists (
      select 1 from public.training_plans
      where id = plan_days.plan_id and trainer_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.training_plans
      where id = plan_days.plan_id and trainer_id = auth.uid()
    )
  );

create policy "klient widzi dni swoich planów"
  on public.plan_days for select
  using (
    exists (
      select 1 from public.training_plans
      where id = plan_days.plan_id and client_id = auth.uid()
    )
  );

-- plan_exercises: przepięcie z plan_id na plan_day_id
drop policy if exists "trener zarządza ćwiczeniami w planach swoich podopiecznych" on public.plan_exercises;
drop policy if exists "klient widzi ćwiczenia w swoich planach" on public.plan_exercises;

alter table public.plan_exercises
  add column plan_day_id uuid references public.plan_days(id) on delete cascade;

alter table public.plan_exercises
  drop column plan_id;

alter table public.plan_exercises
  alter column plan_day_id set not null;

alter table public.plan_exercises rename column sets to target_sets;
alter table public.plan_exercises rename column reps to target_reps;

drop index if exists idx_plan_exercises_plan;
create index idx_plan_exercises_plan_day on public.plan_exercises(plan_day_id);

create policy "trener zarządza ćwiczeniami w dniach planów swoich podopiecznych"
  on public.plan_exercises for all
  using (
    exists (
      select 1 from public.plan_days pd
      join public.training_plans tp on tp.id = pd.plan_id
      where pd.id = plan_exercises.plan_day_id and tp.trainer_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.plan_days pd
      join public.training_plans tp on tp.id = pd.plan_id
      where pd.id = plan_exercises.plan_day_id and tp.trainer_id = auth.uid()
    )
  );

create policy "klient widzi ćwiczenia w dniach swoich planów"
  on public.plan_exercises for select
  using (
    exists (
      select 1 from public.plan_days pd
      join public.training_plans tp on tp.id = pd.plan_id
      where pd.id = plan_exercises.plan_day_id and tp.client_id = auth.uid()
    )
  );

-- ============================================
-- 4) LOGI TRENINGOWE: SESJE + SERIE
-- ============================================
drop table public.workout_logs;

create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  plan_day_id uuid references public.plan_days(id) on delete set null,
  performed_at date not null default current_date,
  notes text,
  created_at timestamptz not null default now()
);

create index idx_workout_sessions_client on public.workout_sessions(client_id, performed_at);

alter table public.workout_sessions enable row level security;

create policy "trener widzi sesje swoich podopiecznych"
  on public.workout_sessions for select
  using (public.is_trainer_of(client_id));

create policy "klient zarządza własnymi sesjami"
  on public.workout_sessions for all
  using (client_id = auth.uid())
  with check (client_id = auth.uid());

create table public.workout_set_logs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  plan_exercise_id uuid references public.plan_exercises(id) on delete set null,
  exercise_name text not null,
  set_number int not null,
  weight numeric,
  reps int,
  rpe numeric,
  created_at timestamptz not null default now()
);

create index idx_workout_set_logs_session on public.workout_set_logs(session_id);

alter table public.workout_set_logs enable row level security;

create policy "trener widzi serie swoich podopiecznych"
  on public.workout_set_logs for select
  using (
    exists (
      select 1 from public.workout_sessions ws
      where ws.id = workout_set_logs.session_id and public.is_trainer_of(ws.client_id)
    )
  );

create policy "klient zarządza własnymi seriami"
  on public.workout_set_logs for all
  using (
    exists (
      select 1 from public.workout_sessions ws
      where ws.id = workout_set_logs.session_id and ws.client_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.workout_sessions ws
      where ws.id = workout_set_logs.session_id and ws.client_id = auth.uid()
    )
  );
