-- RENOU AI: configuración protegida del asistente
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- La configuración se mantiene desactivada por defecto.
-- Las claves API NO se guardan en esta tabla.

begin;

create table if not exists public.renou_ai_config (
  id smallint primary key default 1 check (id = 1),
  enabled_public boolean not null default false,
  enabled_research boolean not null default false,
  provider text not null default 'gemini'
    check (provider in ('gemini','openai','otro')),
  model text not null default 'gemini-2.5-flash',
  public_requests_per_hour integer not null default 20
    check (public_requests_per_hour between 1 and 10000),
  research_requests_per_hour integer not null default 60
    check (research_requests_per_hour between 1 and 10000),
  max_output_tokens integer not null default 1200
    check (max_output_tokens between 64 and 8192),
  temperature numeric(3,2) not null default 0.20
    check (temperature between 0 and 1),
  system_prompt text not null default 'Eres el asistente de RENOU. Trabaja con rigor, distingue datos verificados, testimonios e hipótesis, cita los identificadores de los casos consultados y declara cuando la información sea insuficiente. No inventes datos, no diagnostiques causas sin evidencia y no presentes especulaciones como hechos.',
  updated_at timestamptz not null default now(),
  updated_by uuid
);

alter table public.renou_ai_config enable row level security;
revoke all on table public.renou_ai_config from anon, authenticated;
grant all on table public.renou_ai_config to service_role;

insert into public.renou_ai_config (id)
values (1)
on conflict (id) do nothing;

create or replace function public.renou_ai_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.investigadores i
    where i.id = auth.uid()
      and i.activo is true
      and i.es_admin is true
  );
$$;

create or replace function public.renou_ai_config_get()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_config jsonb;
begin
  if auth.uid() is null or not public.renou_ai_is_admin() then
    raise exception 'Acceso restringido: se requiere una cuenta administradora activa'
      using errcode = '42501';
  end if;

  select to_jsonb(c) - 'id' - 'updated_by'
    into v_config
  from public.renou_ai_config c
  where c.id = 1;

  return coalesce(v_config, '{}'::jsonb);
end;
$$;

create or replace function public.renou_ai_config_save(p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_provider text;
  v_model text;
  v_public_limit integer;
  v_research_limit integer;
  v_tokens integer;
  v_temperature numeric(3,2);
  v_prompt text;
  v_public boolean;
  v_research boolean;
begin
  if auth.uid() is null or not public.renou_ai_is_admin() then
    raise exception 'Acceso restringido: se requiere una cuenta administradora activa'
      using errcode = '42501';
  end if;

  if p_config is null or jsonb_typeof(p_config) <> 'object' then
    raise exception 'Configuración inválida';
  end if;

  v_provider := coalesce(p_config->>'provider','gemini');
  v_model := coalesce(p_config->>'model','');
  v_public_limit := (p_config->>'public_requests_per_hour')::integer;
  v_research_limit := (p_config->>'research_requests_per_hour')::integer;
  v_tokens := (p_config->>'max_output_tokens')::integer;
  v_temperature := (p_config->>'temperature')::numeric;
  v_prompt := coalesce(p_config->>'system_prompt','');
  v_public := coalesce((p_config->>'enabled_public')::boolean,false);
  v_research := coalesce((p_config->>'enabled_research')::boolean,false);

  if v_provider not in ('gemini','openai','otro') then
    raise exception 'Proveedor no permitido';
  end if;
  if length(v_model) > 100 then raise exception 'Nombre de modelo demasiado largo'; end if;
  if v_public_limit not between 1 and 10000 then raise exception 'Límite público fuera de rango'; end if;
  if v_research_limit not between 1 and 10000 then raise exception 'Límite de investigadores fuera de rango'; end if;
  if v_tokens not between 64 and 8192 then raise exception 'Máximo de tokens fuera de rango'; end if;
  if v_temperature not between 0 and 1 then raise exception 'Temperatura fuera de rango'; end if;
  if length(v_prompt) > 12000 then raise exception 'Instrucciones demasiado largas'; end if;

  insert into public.renou_ai_config (
    id, enabled_public, enabled_research, provider, model,
    public_requests_per_hour, research_requests_per_hour,
    max_output_tokens, temperature, system_prompt, updated_at, updated_by
  ) values (
    1, v_public, v_research, v_provider, v_model,
    v_public_limit, v_research_limit, v_tokens, v_temperature,
    v_prompt, now(), auth.uid()
  )
  on conflict (id) do update set
    enabled_public = excluded.enabled_public,
    enabled_research = excluded.enabled_research,
    provider = excluded.provider,
    model = excluded.model,
    public_requests_per_hour = excluded.public_requests_per_hour,
    research_requests_per_hour = excluded.research_requests_per_hour,
    max_output_tokens = excluded.max_output_tokens,
    temperature = excluded.temperature,
    system_prompt = excluded.system_prompt,
    updated_at = now(),
    updated_by = auth.uid();

  return jsonb_build_object('saved', true, 'updated_at', now());
end;
$$;

revoke all on function public.renou_ai_is_admin() from public, anon;
revoke all on function public.renou_ai_config_get() from public, anon;
revoke all on function public.renou_ai_config_save(jsonb) from public, anon;
grant execute on function public.renou_ai_config_get() to authenticated;
grant execute on function public.renou_ai_config_save(jsonb) to authenticated;

commit;
