-- RENOU AI: paginación por cursor estable (keyset)
-- Ejecutar en Supabase SQL Editor antes de desplegar la Edge Function.
-- No modifica RLS ni permisos de las tablas originales.
-- Cursor por id (clave primaria textual): evita OFFSET y no tiene techo fijo.

begin;

create or replace function public.renou_ai_get_cases_page(
  p_user_id uuid default null,
  p_limit integer default 50,
  p_after_id text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
declare
  v_is_active_investigator boolean := false;
  v_result jsonb;
begin
  if p_limit is null or p_limit < 1 or p_limit > 50 then
    raise exception 'p_limit debe estar entre 1 y 50'
      using errcode = '22023';
  end if;

  if p_after_id is not null and length(p_after_id) > 128 then
    raise exception 'Cursor inválido'
      using errcode = '22023';
  end if;

  if p_user_id is not null then
    select exists (
      select 1
      from public.investigadores i
      where i.id = p_user_id
        and i.activo is true
    )
    into v_is_active_investigator;

    if not v_is_active_investigator then
      raise exception 'El usuario no es un investigador activo'
        using errcode = '42501';
    end if;
  end if;

  with candidates as (
    select
      a.id,
      jsonb_strip_nulls(jsonb_build_object(
        'id', a.id,
        'tipo', a.tipo,
        'ce', a.ce,
        'ie', a.ie,
        'resultado', a.resultado,
        'fecha', a."C1",
        'hora', a."C2",
        'referencia_temporal', a."C3",
        'ubicacion_textual', a."C4p",
        'ubicacion_detalle', a."C4d",
        'ubicacion_ciudad', a."C4c",
        'latitud', a.lat,
        'longitud', a.lon,
        'D1', a."D1",
        'D2', a."D2",
        'D3', a."D3",
        'D4', a."D4",
        'D5', a."D5",
        'E1', a."E1",
        'E2', a."E2",
        'E3', a."E3",
        'F1', a."F1",
        'F3', a."F3"
      )) as case_data
    from public.avistamientos a
    where (a.publicado is true or v_is_active_investigator is true)
      and (p_after_id is null or a.id > p_after_id)
    order by a.id asc
    limit p_limit + 1
  ),
  page as (
    select id, case_data
    from candidates
    order by id asc
    limit p_limit
  )
  select jsonb_build_object(
    'cases',
      coalesce(
        (select jsonb_agg(page.case_data order by page.id) from page),
        '[]'::jsonb
      ),
    'has_more',
      (select count(*) > p_limit from candidates),
    'next_id',
      (select page.id from page order by page.id desc limit 1)
  )
  into v_result;

  return v_result;
end;
$function$;

revoke all on function public.renou_ai_get_cases_page(uuid, integer, text)
  from public, anon, authenticated;
grant execute on function public.renou_ai_get_cases_page(uuid, integer, text)
  to service_role;

commit;

-- La función anterior con OFFSET queda sin uso por la Edge Function nueva.
-- No se alteran sus permisos ni las políticas RLS preexistentes.
