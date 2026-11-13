-- RENOU AI: límite horario persistente para Edge Function.
-- Solo guarda un hash SHA-256; no guarda IP ni pregunta.
-- Los registros inactivos durante más de dos horas se depuran al consumir el límite.

begin;

create table if not exists public.renou_ai_rate_limits (
  key_hash text primary key check (key_hash ~ '^[0-9a-f]{64}$'),
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now()
);

create index if not exists renou_ai_rate_limits_updated_at_idx
  on public.renou_ai_rate_limits (updated_at);

alter table public.renou_ai_rate_limits enable row level security;
revoke all on table public.renou_ai_rate_limits from public, anon, authenticated;
grant all on table public.renou_ai_rate_limits to service_role;

create or replace function public.renou_ai_consume_rate_limit(
  p_key_hash text,
  p_limit integer
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_count integer;
  v_window timestamptz;
begin
  if p_key_hash is null or p_key_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Identificador de límite inválido' using errcode = '22023';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 10000 then
    raise exception 'Límite fuera de rango' using errcode = '22023';
  end if;

  insert into public.renou_ai_rate_limits(key_hash, window_started_at, request_count, updated_at)
  values (p_key_hash, now(), 1, now())
  on conflict (key_hash) do update
    set window_started_at = case
          when public.renou_ai_rate_limits.window_started_at <= now() - interval '1 hour'
            then now()
          else public.renou_ai_rate_limits.window_started_at
        end,
        request_count = case
          when public.renou_ai_rate_limits.window_started_at <= now() - interval '1 hour'
            then 1
          else public.renou_ai_rate_limits.request_count + 1
        end,
        updated_at = now()
  returning request_count, window_started_at
  into v_count, v_window;

  -- Depuración oportunista: conserva margen suficiente para la ventana horaria.
  -- El índice evita recorrer toda la tabla cuando existan muchos registros.
  with stale_keys as (
    select key_hash
    from public.renou_ai_rate_limits
    where updated_at < now() - interval '2 hours'
    order by updated_at
    limit 500
    for update skip locked
  )
  delete from public.renou_ai_rate_limits r
  using stale_keys s
  where r.key_hash = s.key_hash;

  return jsonb_build_object(
    'allowed', v_count <= p_limit,
    'remaining', greatest(p_limit - v_count, 0),
    'window_started_at', v_window
  );
end;
$function$;

revoke all on function public.renou_ai_consume_rate_limit(text, integer)
  from public, anon, authenticated;
grant execute on function public.renou_ai_consume_rate_limit(text, integer)
  to service_role;

commit;
