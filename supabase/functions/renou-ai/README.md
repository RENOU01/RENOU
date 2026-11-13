# RENOU AI — Edge Function (fase de pruebas)

## Protección de datos

- No consulta `avistamientos_audip`.
- Lee casos exclusivamente mediante `renou_ai_get_cases_page`, con una lista fija de campos.
- Público: casos publicados.
- Investigador: publicados y no publicados, tras validar JWT y cuenta activa.
- Nunca acepta `user_id`, rol, alcance ni permisos desde el cuerpo de la petición.
- No devuelve expedientes al navegador; devuelve únicamente respuesta y contadores.
- Omite nombres, correos, teléfonos, identidad de personas, dirección aproximada, texto libre y metadatos administrativos.
- La clave Gemini se obtiene de `GEMINI_API_KEY`, como secreto de Supabase.

## Requisitos previos

1. Ejecutar `sql/renou_ai_keyset_pagination.sql`.
2. Ejecutar `sql/renou_ai_rate_limit.sql`.
3. Confirmar que las funciones nuevas solo tienen EXECUTE para `service_role`.
4. Mantener `enabled_public=false` y `enabled_research=false`.
5. Configurar los secretos en Supabase. Las variables `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` son las variables estándar del entorno; añadir `GEMINI_API_KEY` como secreto.

## Despliegue futuro

El archivo `supabase/config.toml` establece `verify_jwt=false` para que visitantes públicos puedan invocar la función sin sesión. Esto no significa que se confíe en el cliente: la función valida cualquier Bearer token recibido y determina el alcance en el servidor. No se debe eliminar esa validación interna.

Cuando se autorice el despliegue, desde la raíz del repositorio y con Supabase CLI vinculado al proyecto correcto:

```bash
supabase functions deploy renou-ai
```

## Historial completo

La nueva RPC usa paginación por cursor sobre el identificador único del caso, sin OFFSET ni techo de 100.000 filas. La Edge Function sigue leyendo páginas hasta terminar el historial autorizado. Tiene un límite preventivo de tiempo: si no logra recorrerlo completo, responde con error y no genera un análisis parcial.

La versión actual todavía carga el historial autorizado en memoria y realiza coincidencia léxica en la Edge Function. Para bases muy grandes, el siguiente paso será mover búsqueda y agregaciones a PostgreSQL para evitar recorrer y cargar todos los expedientes en cada consulta.

## Estado

Este código no despliega nada ni activa Gemini. Las dos opciones de configuración deben permanecer apagadas hasta completar pruebas con casos ficticios, revisión de privacidad, límites y costos.
