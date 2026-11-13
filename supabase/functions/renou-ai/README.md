# RENOU AI — despliegue de Edge Function (fase inicial)

Esta carpeta contiene la función intermediaria entre el sitio RENOU, Supabase y Gemini.

## Protección de datos

- La función no consulta `avistamientos_audip`.
- Lee los casos únicamente mediante `public.renou_ai_get_cases`, que devuelve una lista fija de campos.
- Público: casos publicados. Investigador autenticado y activo: casos publicados y no publicados.
- Nunca acepta `user_id`, rol, alcance ni permisos desde el cuerpo de la petición.
- No devuelve los registros al navegador; solo devuelve la respuesta generada y contadores.
- No envía nombres, correos, teléfonos, identidades, campos administrativos, direcciones aproximadas ni metadatos al proveedor.
- El límite horario usa un hash SHA-256 de la identidad de limitación. No persiste la IP ni la pregunta.
- La función recorre el historial autorizado por páginas y prepara estadísticas globales más una selección de casos coincidentes.

## Requisitos previos en Supabase

1. Ejecutar `sql/renou_ai_rate_limit.sql` en SQL Editor.
2. Confirmar que la función `renou_ai_get_cases(uuid,integer,integer)` existe y solo tiene EXECUTE para `service_role`.
3. Mantener `enabled_public=false` y `enabled_research=false` en `renou_ai_config`.
4. Configurar los secretos de la Edge Function:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_ANON_KEY`
   - `GEMINI_API_KEY`

Supabase normalmente provee las tres primeras variables de entorno. La clave Gemini debe añadirse como secreto y nunca guardarse en GitHub ni en `index.html`.

## Despliegue

Desde la raíz del proyecto, con Supabase CLI vinculado al proyecto correcto:

```bash
supabase functions deploy renou-ai
```

La función valida la sesión de Supabase cuando recibe un Bearer token. Sin token, trata la consulta como pública y aplica únicamente el alcance publicado.

## Estado y limitaciones de esta fase

- Este commit agrega código fuente y SQL; no despliega nada en Supabase.
- Gemini no será llamado mientras los dos interruptores permanezcan apagados.
- La selección de casos relevantes es una búsqueda léxica inicial sobre campos estructurados; no es todavía una búsqueda semántica ni una indexación vectorial.
- La función recorre hasta 100.000 casos. Si el historial excede ese máximo, se detiene y no genera una respuesta parcial.
- Antes de habilitar el servicio, probar con cuentas de prueba y registros ficticios, verificar los resultados de la RPC y revisar consumo/costos del proveedor.
