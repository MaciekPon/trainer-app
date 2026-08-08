-- ============================================
-- Dane przykładowe: plan 3-dniowy (4 ćwiczenia/dzień) + kilka sesji
-- treningowych i pomiarów, żeby zobaczyć działające wykresy postępów.
--
-- Uruchom w Supabase SQL Editor (działa jako postgres, więc RLS nie
-- przeszkadza). PRZED URUCHOMIENIEM podmień e-maile poniżej na
-- prawdziwe adresy trenera i klienta użyte przy rejestracji.
--
-- Uwaga: skrypt NIE jest idempotentny — uruchomiony drugi raz doda
-- kolejny, zdublowany plan. To jednorazowy seed do podglądu, nie
-- migracja.
-- ============================================

do $$
declare
  v_trainer_email text := 'TRENER@PRZYKLAD.PL';   -- <-- podmień
  v_client_email  text := 'KLIENT@PRZYKLAD.PL';    -- <-- podmień

  v_trainer_id uuid;
  v_client_id uuid;
  v_plan_id uuid;
  v_day_a uuid;
  v_day_b uuid;
  v_day_c uuid;
  v_session_id uuid;
begin
  -- Szukamy po istniejącej relacji client_trainer, a nie po profiles.role —
  -- to pole bywa błędnie ustawione, jeśli konto powstało przez zły link
  -- podczas testów (np. trener zarejestrowany przez /accept-invite).
  select ct.trainer_id, ct.client_id into v_trainer_id, v_client_id
  from public.client_trainer ct
  join auth.users ut on ut.id = ct.trainer_id
  join auth.users uc on uc.id = ct.client_id
  where lower(ut.email) = lower(v_trainer_email) and lower(uc.email) = lower(v_client_email);

  if v_trainer_id is null or v_client_id is null then
    raise exception 'Nie znaleziono relacji trener-klient dla podanych e-maili (sprawdź, czy klient jest już przypisany do trenera w tabeli client_trainer)';
  end if;

  -- Plan + 3 dni + 4 ćwiczenia na dzień
  insert into public.training_plans (client_id, trainer_id, name)
  values (v_client_id, v_trainer_id, 'Przykładowy plan — 3 dni')
  returning id into v_plan_id;

  insert into public.plan_days (plan_id, name, position)
  values (v_plan_id, 'Dzień A — Klatka i triceps', 0) returning id into v_day_a;
  insert into public.plan_days (plan_id, name, position)
  values (v_plan_id, 'Dzień B — Plecy i biceps', 1) returning id into v_day_b;
  insert into public.plan_days (plan_id, name, position)
  values (v_plan_id, 'Dzień C — Nogi', 2) returning id into v_day_c;

  insert into public.plan_exercises (plan_day_id, exercise_name, target_sets, target_reps, position) values
    (v_day_a, 'Wyciskanie sztangi na ławce płaskiej', 4, 8, 0),
    (v_day_a, 'Wyciskanie hantli na ławce skos dodatni', 3, 10, 1),
    (v_day_a, 'Rozpiętki na maszynie', 3, 12, 2),
    (v_day_a, 'Prostowanie ramion na wyciągu górnym', 3, 12, 3);

  insert into public.plan_exercises (plan_day_id, exercise_name, target_sets, target_reps, position) values
    (v_day_b, 'Podciąganie na drążku', 4, 8, 0),
    (v_day_b, 'Wiosłowanie sztangą', 4, 10, 1),
    (v_day_b, 'Ściąganie drążka wyciągu górnego', 3, 12, 2),
    (v_day_b, 'Uginanie ramion ze sztangą', 3, 12, 3);

  insert into public.plan_exercises (plan_day_id, exercise_name, target_sets, target_reps, position) values
    (v_day_c, 'Przysiad ze sztangą', 4, 6, 0),
    (v_day_c, 'Martwy ciąg rumuński', 3, 10, 1),
    (v_day_c, 'Wypychanie nogami na suwnicy', 3, 12, 2),
    (v_day_c, 'Uginanie nóg leżąc', 3, 12, 3);

  -- 3 sesje "Dzień A" w ostatnich dwóch tygodniach, z rosnącym ciężarem,
  -- żeby wykres objętości treningowej pokazał realny trend.
  insert into public.workout_sessions (client_id, plan_day_id, performed_at)
  values (v_client_id, v_day_a, current_date - interval '14 days') returning id into v_session_id;
  insert into public.workout_set_logs (session_id, exercise_name, set_number, weight, reps) values
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 1, 60, 8),
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 2, 60, 8),
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 3, 60, 7),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 1, 22, 10),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 2, 22, 10),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 3, 22, 9);

  insert into public.workout_sessions (client_id, plan_day_id, performed_at)
  values (v_client_id, v_day_a, current_date - interval '7 days') returning id into v_session_id;
  insert into public.workout_set_logs (session_id, exercise_name, set_number, weight, reps) values
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 1, 62.5, 8),
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 2, 62.5, 8),
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 3, 62.5, 8),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 1, 24, 10),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 2, 24, 10),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 3, 24, 10);

  insert into public.workout_sessions (client_id, plan_day_id, performed_at)
  values (v_client_id, v_day_a, current_date) returning id into v_session_id;
  insert into public.workout_set_logs (session_id, exercise_name, set_number, weight, reps) values
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 1, 65, 8),
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 2, 65, 8),
    (v_session_id, 'Wyciskanie sztangi na ławce płaskiej', 3, 65, 8),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 1, 24, 11),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 2, 24, 11),
    (v_session_id, 'Wyciskanie hantli na ławce skos dodatni', 3, 24, 10);

  -- Pomiary pokazujące trend (waga/obwody w dół w czasie)
  insert into public.measurements (client_id, weight, waist, hips, chest, measured_at) values
    (v_client_id, 82,   92,   101,   104,   current_date - interval '14 days'),
    (v_client_id, 81.2, 90.5, 100.5, 104.5, current_date - interval '7 days'),
    (v_client_id, 80.4, 89,   100,   105,   current_date);

  raise notice 'Gotowe. plan_id=%, dzien_a=%, dzien_b=%, dzien_c=%', v_plan_id, v_day_a, v_day_b, v_day_c;
end $$;
