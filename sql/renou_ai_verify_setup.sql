-- RENOU AI: verificación posterior a ejecutar los dos SQL nuevos
-- Solo consulta existencia, permisos y estado de activación. No lee casos ni datos personales.

select
  to_regprocedure('public.renou_ai_get_cases_page(uuid,integer,text)') is not null
    as paginacion_creada,
  has_function_privilege('anon',
    'public.renou_ai_get_cases_page(uuid,integer,text)', 'EXECUTE')
    as paginacion_anon,
  has_function_privilege('authenticated',
    'public.renou_ai_get_cases_page(uuid,integer,text)', 'EXECUTE')
    as paginacion_authenticated,
  has_function_privilege('service_role',
    'public.renou_ai_get_cases_page(uuid,integer,text)', 'EXECUTE')
    as paginacion_service_role;

select
  to_regprocedure('public.renou_ai_consume_rate_limit(text,integer)') is not null
    as rate_limit_creado,
  has_function_privilege('anon',
    'public.renou_ai_consume_rate_limit(text,integer)', 'EXECUTE')
    as rate_limit_anon,
  has_function_privilege('authenticated',
    'public.renou_ai_consume_rate_limit(text,integer)', 'EXECUTE')
    as rate_limit_authenticated,
  has_function_privilege('service_role',
    'public.renou_ai_consume_rate_limit(text,integer)', 'EXECUTE')
    as rate_limit_service_role;

select
  c.relrowsecurity as rls_habilitado,
  has_table_privilege('anon','public.renou_ai_rate_limits','SELECT') as tabla_anon_select,
  has_table_privilege('authenticated','public.renou_ai_rate_limits','SELECT') as tabla_authenticated_select,
  has_table_privilege('service_role','public.renou_ai_rate_limits','SELECT') as tabla_service_role_select
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public' and c.relname='renou_ai_rate_limits';

select enabled_public, enabled_research
from public.renou_ai_config
where id=1;

-- Valores esperados:
-- paginacion_creada=true; paginacion_anon=false; paginacion_authenticated=false;
-- paginacion_service_role=true.
-- rate_limit_creado=true; rate_limit_anon=false; rate_limit_authenticated=false;
-- rate_limit_service_role=true.
-- rls_habilitado=true; tabla_anon_select=false; tabla_authenticated_select=false;
-- tabla_service_role_select=true.
-- enabled_public=false y enabled_research=false.
