-- RENOU AI - acceso aislado a datos de avistamientos
-- Ejecutar en Supabase SQL Editor DESPUÉS de revisar el contenido.
-- No modifica políticas RLS ni permisos de las tablas/vistas existentes.
--
-- Diseño:
--   * p_user_id NULL: solo devuelve casos publicados.
--   * p_user_id informado: exige que corresponda a un investigador activo;
--     devuelve casos publicados y no publicados.
--   * En ambos casos devuelve exclusivamente una lista fija de campos del caso.
--   * La función solo puede ejecutarla service_role. La Edge Function deberá
--     validar el JWT del usuario y decidir qué user_id enviar.
--
-- IMPORTANTE:
--   Descripciones y textos libres pueden contener datos personales escritos
--   accidentalmente. La Edge Function deberá filtrarlos antes de enviar a Gemini.
--   Los enlaces multimedia también deberán validarse y limitarse a archivos
--   públicos autorizados. No enviar a Gemini metadatos EXIF ni datos del bucket
--   que no sean necesarios.

begin;

create or replace function public.renou_ai_get_cases(
  p_user_id uuid default null,
  p_limit integer default 20,
  p_offset integer default 0
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
declare
  v_is_active_investigator boolean := false;
begin
  if p_limit is null or p_limit < 1 or p_limit > 50 then
    raise exception 'p_limit debe estar entre 1 y 50'
      using errcode = '22023';
  end if;

  if p_offset is null or p_offset < 0 or p_offset > 100000 then
    raise exception 'p_offset fuera de rango'
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

  return query
  select jsonb_strip_nulls(jsonb_build_object(
    'id', a.id,
    'tipo', a.tipo,
    'estado', a.estado,
    'ce', a.ce,
    'ie', a.ie,
    'resultado', a.resultado,
    'fecha', a."C1",
    'hora', a."C2",
    'referencia_temporal', a."C3",
    'ubicacion_textual', a."C4p",
    'ubicacion_detalle', a."C4d",
    'ubicacion_ciudad', a."C4c",
    'direccion', a."C4dir",
    'latitud', a.lat,
    'longitud', a.lon,
    'D1', a."D1",
    'D2', a."D2",
    'D3', a."D3",
    'D4', a."D4",
    'D5', a."D5",
    'D5d', a."D5d",
    'E1', a."E1",
    'E2', a."E2",
    'E3', a."E3",
    'F1', a."F1",
    'F2', a."F2",
    'F3', a."F3",
    'descripcion', a.descripcion,
    'informacion_adicional', a.extra,
    'imagenes_y_archivos', a.media_urls,
    'video_publico', a.video_link
  ))
  from public.avistamientos a
  where (a.publicado is true or v_is_active_investigator is true)
  order by a."C1" desc nulls last, a.created_at desc
  limit p_limit
  offset p_offset;
end;
$function$;

-- La función es un canal interno para la Edge Function, no una RPC pública.
revoke all on function public.renou_ai_get_cases(uuid, integer, integer)
  from public, anon, authenticated;
grant execute on function public.renou_ai_get_cases(uuid, integer, integer)
  to service_role;

commit;

-- Pruebas posteriores a ejecutar:
-- 1) Confirmar que anon/authenticated no tienen EXECUTE.
-- 2) Confirmar que service_role sí tiene EXECUTE.
-- 3) La Edge Function debe llamar esta función únicamente después de:
--    a) leer la configuración y verificar enabled_public/enabled_research;
--    b) validar el JWT con Supabase Auth;
--    c) verificar investigador activo para el alcance de investigación.
-- 4) No enviar a Gemini el texto ni los archivos sin aplicar controles de
--    redacción de datos personales y validación de URLs multimedia.
