-- Sinkly backend v1 — deliberately tiny.
--
-- Everything else (plan, schedule, locks, progress) lives on the phone.
-- Supabase only holds:
--   1. feedback               → ideas people send from the app (max 5 / day / phone)
--   2. verification_attempts  → a counter so one phone can't check more than
--                               15 sink photos per rolling 24 h (no photos, no results)
-- Identity = Supabase anonymous sign-in (no email, no screen). `auth.uid()` is the "device".

-- ─────────────────────────────────────────────────────────────────────────
-- 1. feedback
-- ─────────────────────────────────────────────────────────────────────────
create table public.feedback (
  id            uuid primary key default gen_random_uuid(),
  -- Id generated on the phone: re-sending the same idea (flaky network) can't duplicate it.
  client_id     text not null unique check (char_length(client_id) between 1 and 64),
  device_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  category      text not null check (category in ('new_feature', 'ui_enhancement', 'bug_report', 'app_lock_options')),
  message       text not null check (char_length(btrim(message)) between 10 and 2000),
  language_code text check (char_length(language_code) <= 10),
  app_version   text check (char_length(app_version) <= 20),
  platform      text check (platform in ('ios', 'android')),
  -- Only you change this (Supabase dashboard): new → reviewed → planned → done.
  status        text not null default 'new' check (status in ('new', 'reviewed', 'planned', 'done')),
  created_at    timestamptz not null default now()
);

create index feedback_device_created_idx on public.feedback (device_id, created_at desc);

alter table public.feedback enable row level security;

-- A phone may add ideas for itself and nothing else: no reading, editing or deleting.
revoke all on public.feedback from anon, authenticated;
grant insert (client_id, category, message, language_code, app_version, platform) on public.feedback to authenticated;

create policy "phones insert their own feedback"
  on public.feedback for insert to authenticated
  with check (device_id = auth.uid() and status = 'new');

-- Max 5 ideas per rolling 24 h per phone.
create function public.enforce_feedback_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform pg_advisory_xact_lock(hashtextextended(new.device_id::text, 1));
  if (select count(*) from public.feedback
       where device_id = new.device_id and created_at > now() - interval '24 hours') >= 5 then
    raise exception 'feedback_limit_reached' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger feedback_limit_before_insert
  before insert on public.feedback
  for each row execute function public.enforce_feedback_limit();

-- ─────────────────────────────────────────────────────────────────────────
-- 2. verification_attempts (counter only)
-- ─────────────────────────────────────────────────────────────────────────
create table public.verification_attempts (
  id         uuid primary key default gen_random_uuid(),
  device_id  uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index verification_attempts_device_idx on public.verification_attempts (device_id, created_at desc);
create index verification_attempts_created_idx on public.verification_attempts (created_at);

-- No policies and no grants: only the Edge Function (service role) touches it.
alter table public.verification_attempts enable row level security;
revoke all on public.verification_attempts from anon, authenticated;

-- Atomically checks both limits and books one attempt.
--   status 'ok'           → attempt_id is the booked row
--   status 'device_limit' → this phone used its p_device_limit checks in the last 24 h
--   status 'global_limit' → the whole app hit its daily safety ceiling (protects your wallet)
create function public.reserve_verification(p_device uuid, p_device_limit int, p_global_limit int)
returns table (status text, attempt_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  -- One booking at a time per phone, so parallel requests can't slip past the limit.
  perform pg_advisory_xact_lock(hashtextextended(p_device::text, 2));

  if (select count(*) from public.verification_attempts
       where device_id = p_device and created_at > now() - interval '24 hours') >= p_device_limit then
    return query select 'device_limit'::text, null::uuid;
    return;
  end if;

  if (select count(*) from public.verification_attempts
       where created_at > now() - interval '24 hours') >= p_global_limit then
    return query select 'global_limit'::text, null::uuid;
    return;
  end if;

  insert into public.verification_attempts (device_id) values (p_device) returning id into v_id;

  -- Housekeeping without a cron job: now and then drop rows no limit can ever look at again.
  if random() < 0.02 then
    delete from public.verification_attempts where created_at < now() - interval '3 days';
  end if;

  return query select 'ok'::text, v_id;
end;
$$;

revoke all on function public.reserve_verification(uuid, int, int) from public, anon, authenticated;
grant execute on function public.reserve_verification(uuid, int, int) to service_role;
