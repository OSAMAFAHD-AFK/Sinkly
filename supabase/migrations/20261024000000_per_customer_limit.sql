-- Daily limit per SUBSCRIBER, not only per anonymous session.
--
-- Until now the "15 checks a day" limit was counted per anonymous Supabase
-- session (`auth.uid()`). Anyone can open as many anonymous sessions as they
-- like, so one subscription (even a free trial) could spend unlimited Gemini
-- checks by sending the same RevenueCat customer id from many sessions.
--
-- Now every booking also remembers WHO paid: a SHA-256 hash of the RevenueCat
-- customer id (never the id itself), and the daily limit is counted on it too.
--
-- Safe to run more than once. The old two-argument function stays, so an older
-- deployment of the Edge Function keeps working until it is replaced.

alter table public.verification_attempts add column if not exists customer_hash text;

create index if not exists verification_attempts_customer_idx
  on public.verification_attempts (customer_hash, created_at desc)
  where customer_hash is not null;

--   status 'ok'             → attempt_id is the booked row
--   status 'device_limit'   → this phone (anonymous session) used its checks in the last 24 h
--   status 'customer_limit' → this subscriber used their checks in the last 24 h, from any session
-- p_customer may be null (RevenueCat not connected yet): then only the phone limit applies.
create or replace function public.reserve_verification(
  p_device uuid,
  p_device_limit int,
  p_customer text,
  p_customer_limit int
)
returns table (status text, attempt_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  -- One booking at a time per phone and per subscriber, so parallel requests can't slip past a limit.
  -- Always in the same order (phone, then subscriber): no deadlocks.
  perform pg_advisory_xact_lock(hashtextextended(p_device::text, 2));
  if p_customer is not null then
    perform pg_advisory_xact_lock(hashtextextended(p_customer, 3));
  end if;

  if (select count(*) from public.verification_attempts
       where device_id = p_device and created_at > now() - interval '24 hours') >= p_device_limit then
    return query select 'device_limit'::text, null::uuid;
    return;
  end if;

  if p_customer is not null and (select count(*) from public.verification_attempts
       where customer_hash = p_customer and created_at > now() - interval '24 hours') >= p_customer_limit then
    return query select 'customer_limit'::text, null::uuid;
    return;
  end if;

  insert into public.verification_attempts (device_id, customer_hash)
  values (p_device, p_customer)
  returning id into v_id;

  -- Housekeeping without a cron job: now and then drop rows no limit can ever look at again.
  if random() < 0.02 then
    delete from public.verification_attempts where created_at < now() - interval '3 days';
  end if;

  return query select 'ok'::text, v_id;
end;
$$;

revoke all on function public.reserve_verification(uuid, int, text, int) from public, anon, authenticated;
grant execute on function public.reserve_verification(uuid, int, text, int) to service_role;
