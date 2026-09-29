create schema if not exists private;

create table if not exists public.travel_lah_sync (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  revision bigint not null default 1 check (revision >= 1),
  updated_at timestamptz not null default now()
);

alter table public.travel_lah_sync enable row level security;
revoke all on table public.travel_lah_sync from anon, authenticated;
grant select, insert, update on table public.travel_lah_sync to authenticated;

drop policy if exists travel_lah_sync_select_own on public.travel_lah_sync;
create policy travel_lah_sync_select_own on public.travel_lah_sync
for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists travel_lah_sync_insert_own on public.travel_lah_sync;
create policy travel_lah_sync_insert_own on public.travel_lah_sync
for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists travel_lah_sync_update_own on public.travel_lah_sync;
create policy travel_lah_sync_update_own on public.travel_lah_sync
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create or replace function private.travel_lah_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists travel_lah_sync_set_updated_at on public.travel_lah_sync;
create trigger travel_lah_sync_set_updated_at
before update on public.travel_lah_sync
for each row execute function private.travel_lah_set_updated_at();

notify pgrst, 'reload schema';
