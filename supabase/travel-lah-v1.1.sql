-- Travel Lah! V1.1 Cloud Sync
-- Run once in Supabase SQL Editor.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.travel_lah_sync (
  sync_id uuid primary key,
  token_hash text not null,
  payload jsonb not null,
  revision bigint not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.travel_lah_sync enable row level security;
revoke all on table public.travel_lah_sync from anon, authenticated;

create or replace function public.travel_lah_load(p_sync_id uuid, p_token text)
returns table(payload jsonb, revision bigint, updated_at timestamptz)
language sql
security definer
set search_path = public, extensions, pg_catalog
as $$
  select s.payload, s.revision, s.updated_at
  from public.travel_lah_sync s
  where s.sync_id = p_sync_id
    and s.token_hash = encode(digest(p_token, 'sha256'), 'hex');
$$;

create or replace function public.travel_lah_save(
  p_sync_id uuid,
  p_token text,
  p_payload jsonb,
  p_base_revision bigint default null
)
returns table(status text, revision bigint, updated_at timestamptz)
language plpgsql
security definer
set search_path = public, extensions, pg_catalog
as $$
declare
  v_hash text := encode(digest(p_token, 'sha256'), 'hex');
  v_row public.travel_lah_sync%rowtype;
begin
  select * into v_row
  from public.travel_lah_sync
  where sync_id = p_sync_id
  for update;

  if not found then
    insert into public.travel_lah_sync(sync_id, token_hash, payload, revision, updated_at)
    values (p_sync_id, v_hash, p_payload, 1, now())
    returning * into v_row;
    return query select 'created'::text, v_row.revision, v_row.updated_at;
    return;
  end if;

  if v_row.token_hash <> v_hash then
    return query select 'denied'::text, v_row.revision, v_row.updated_at;
    return;
  end if;

  if p_base_revision is not null and p_base_revision <> v_row.revision then
    return query select 'conflict'::text, v_row.revision, v_row.updated_at;
    return;
  end if;

  update public.travel_lah_sync
     set payload = p_payload,
         revision = revision + 1,
         updated_at = now()
   where sync_id = p_sync_id
   returning * into v_row;

  return query select 'saved'::text, v_row.revision, v_row.updated_at;
end;
$$;

revoke all on function public.travel_lah_load(uuid, text) from public;
revoke all on function public.travel_lah_save(uuid, text, jsonb, bigint) from public;
grant execute on function public.travel_lah_load(uuid, text) to anon, authenticated;
grant execute on function public.travel_lah_save(uuid, text, jsonb, bigint) to anon, authenticated;
