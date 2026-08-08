-- ============================================
-- 0003: automatyczne tworzenie profilu przy rejestracji
-- ============================================
--
-- Wcześniej profil był wstawiany ręcznie z frontendu zaraz po auth.signUp(),
-- co wymagało, żeby auth.uid() był już dostępny w tym samym requeście (RLS).
-- Jeśli w projekcie włączone jest potwierdzanie e-maila, sesja nie wraca
-- od razu i insert odpada na RLS ("new row violates row-level security
-- policy for table profiles").
--
-- Rozwiązanie: trigger na auth.users, który tworzy profil po stronie bazy
-- (security definer, więc RLS nie ma tu znaczenia) na podstawie metadanych
-- przekazanych w signUp({ options: { data: { role, full_name } } }).

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'role', 'client'),
    coalesce(new.raw_user_meta_data->>'full_name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_auth_user();

-- insert z frontendu nie jest już potrzebny — profil powstaje przez trigger
drop policy if exists "mogę stworzyć własny profil" on public.profiles;
