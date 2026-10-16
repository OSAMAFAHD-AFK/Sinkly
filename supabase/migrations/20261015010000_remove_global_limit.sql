-- No whole-app daily ceiling any more (decision: a viral video must never lock real users out).
-- The only limit left is per phone: p_device_limit checks per rolling 24 h.
-- Also removes the one query that would get slower as the app grows (a count over every phone's rows).

drop function if exists public.reserve_verification(uuid, int, int);

--   status 'ok'           → attempt_id is the booked row
--   status 'device_limit' → this phone used its p_device_limit checks in the last 24 h
create function public.reserve_verification(p_device uuid, p_device_limit int)
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

  insert into public.verification_attempts (device_id) values (p_device) returning id into v_id;

  -- Housekeeping without a cron job: now and then drop rows no limit can ever look at again.
  if random() < 0.02 then
    delete from public.verification_attempts where created_at < now() - interval '3 days';
  end if;

  return query select 'ok'::text, v_id;
end;
$$;

revoke all on function public.reserve_verification(uuid, int) from public, anon, authenticated;
grant execute on function public.reserve_verification(uuid, int) to service_role;
