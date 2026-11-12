-- RENOU AI - auditoría previa de aislamiento de datos
-- Solo lectura. Ejecutar en Supabase > SQL Editor.
-- No devuelve registros de casos ni datos personales; únicamente metadatos del esquema.

-- 1) Columnas exactas de las vistas que podrían contener casos.
select
  table_name,
  ordinal_position,
  column_name,
  data_type,
  udt_name
from information_schema.columns
where table_schema = 'public'
  and table_name in ('avistamientos_publicos', 'avistamientos_audip')
order by table_name, ordinal_position;

-- 2) Definición SQL de las vistas (permite comprobar qué campos proceden de la tabla original).
select
  schemaname,
  viewname,
  definition
from pg_views
where schemaname = 'public'
  and viewname in ('avistamientos_publicos', 'avistamientos_audip')
order by viewname;

-- 3) Tipo, propietario y opciones de seguridad de esos objetos.
select
  c.relname as object_name,
  case c.relkind
    when 'r' then 'table'
    when 'v' then 'view'
    when 'm' then 'materialized view'
    when 'f' then 'foreign table'
    else c.relkind::text
  end as object_type,
  pg_get_userbyid(c.relowner) as owner_name,
  c.reloptions
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('avistamientos', 'avistamientos_publicos', 'avistamientos_audip')
order by c.relname;

-- 4) Permisos efectivos declarados por rol sobre esos objetos.
select
  table_name,
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('avistamientos', 'avistamientos_publicos', 'avistamientos_audip')
order by table_name, grantee, privilege_type;

-- 5) Políticas RLS de las tablas relacionadas con casos.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('avistamientos', 'avistamientos_publicos', 'avistamientos_audip')
order by tablename, policyname;
