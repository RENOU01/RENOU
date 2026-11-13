# RENOU AI — Edge Function (fase de pruebas)

## Protección de datos

- No consulta `avistamientos_audip`.
- Lee casos exclusivamente mediante `renou_ai_get_cases_page`, con una lista fija de campos.
- Público: casos publicados.
- Investigador: publicados y no publicados, tras validar JWT y cuenta activa.
- Nunca acepta `user_id`, rol, alcance ni permisos desde el cuerpo de la petición.
- No devuelve expedientes al navegador; devuelve únicamente respuesta y contadores.
- La RPC no selecciona nombres, correos, teléfonos, identidad de personas, dirección aproximada (`C4dir`), detalle libre del sonido (`D5d`) ni metadatos administrativos. Los campos de ubicación incluidos (`C4p`, `C4d`, `C4c`) describen país, departamento y ciudad del caso; son texto aportado en el formulario y deben seguir considerándose datos no confiables, no identidad verificada.
- La clave Gemini se obtiene de `GEMINI_API_KEY`, como secreto de Supabase.
- Antes de enviar a Gemini, país, departamento y ciudad pasan por normalización, límite de longitud y filtros básicos de correo/teléfono. Es una defensa adicional, no una garantía de anonimización; no se envían dirección aproximada ni campos libres excluidos por la RPC.

## Requisitos previos

1. Ejecutar `sql/renou_ai_keyset_pagination.sql`.
2. Ejecutar `sql/renou_ai_rate_limit.sql`.
3. Confirmar que las funciones nuevas solo tienen EXECUTE para `service_role`.
4. Mantener `enabled_public=false` y `enabled_research=false`.
5. Configurar `GEMINI_API_KEY` como secreto de Edge Function. Las variables Supabase estándar deben estar disponibles en el entorno.

## Despliegue futuro

`supabase/config.toml` establece `verify_jwt=false` para permitir visitantes públicos sin sesión. La Edge Function valida internamente cualquier Bearer token y determina el alcance en el servidor. CORS no sustituye autenticación ni control de acceso.

Cuando se autorice el despliegue, desde la raíz del repositorio y con Supabase CLI vinculado al proyecto correcto:

```bash
supabase functions deploy renou-ai
```

## Historial completo y límites de esta fase

La RPC usa paginación por cursor sobre el identificador único del caso, sin OFFSET ni techo fijo de 100.000 filas. La Edge Function recorre todas las páginas y calcula agregaciones por año y tipo; conserva en memoria únicamente los 35 casos con mayor coincidencia, no el historial entero.

Si no puede completar el recorrido dentro del tiempo máximo preventivo, devuelve un error y no genera una respuesta parcial. Aunque la paginación no tiene techo por cantidad de filas, el tiempo de ejecución de Edge Functions sí impone un límite práctico. Antes de habilitarla con un historial grande, se debe medir la duración real y, si es necesario, trasladar búsqueda y agregaciones a PostgreSQL para evitar descargar todos los registros en cada consulta.

La llamada al proveedor Gemini tiene un tiempo máximo de 20 segundos, incluida la lectura de su respuesta. El cuerpo de la solicitud entrante se limita a 8 KiB medidos en bytes.

La función de control horario depura como máximo 500 registros vencidos por consulta, usando un índice por `updated_at`, para evitar un borrado masivo en cada petición.

El límite público usa únicamente `cf-connecting-ip`, encabezado que la plataforma Supabase establece para las solicitudes; si no está presente, utiliza un único grupo compartido. No se confía en `x-real-ip`. La documentación de Supabase identifica `cf-connecting-ip` como encabezado establecido por la plataforma. CORS no evita llamadas desde clientes no navegador y no es una defensa contra abuso.

La coincidencia de casos es léxica inicial, no búsqueda semántica.

## Estado

Este código no despliega nada ni activa Gemini. Las dos opciones de configuración deben permanecer apagadas hasta completar pruebas con casos ficticios, revisión de privacidad, límites y costos.
