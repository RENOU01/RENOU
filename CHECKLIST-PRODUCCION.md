# ✅ Checklist Pre-Producción RENOU

Migración de Netlify a GitHub Pages completada. Verificar estos puntos antes de ir a producción.

---

## 🔐 Seguridad y Autenticación

- [ ] **Supabase Configurado**
  - [ ] Reemplazar `TU_SUPABASE_URL` con URL real en `index.html` línea 259
  - [ ] Reemplazar `TU_SUPABASE_ANON_KEY` con clave real
  - [ ] Verificar que la base de datos está creada en Supabase
  - [ ] Configurar políticas RLS (Row Level Security) correctamente
  - [ ] Habilitar almacenamiento para archivos (fotos, videos, PDF)
  - [ ] Crear tabla `cases` con estructura correcta

- [ ] **hCaptcha Configurado**
  - [ ] Verificar que `data-sitekey="8e449adc-3700-45fa-b602-596e746c2744"` es válida
  - [ ] Crear cuenta en hCaptcha.com si no existe
  - [ ] Configurar dominio `renou01.github.io` en hCaptcha

- [ ] **Headers de Seguridad**
  - [ ] Archivo `_headers` está correctamente configurado
  - [ ] NOTA: GitHub Pages usa su propios headers - verificar en Network tab del navegador

---

## 🌐 GitHub Pages

- [ ] **Repositorio Configurado**
  - [ ] Ir a Settings > Pages
  - [ ] Source: Deploy from a branch
  - [ ] Branch: `main`
  - [ ] Folder: `/ (root)`
  - [ ] Esperar 1-2 minutos para que se publique

- [ ] **Dominio Personalizado** (opcional)
  - [ ] Si tienes dominio, configurarlo en Settings > Pages > Custom domain
  - [ ] Verificar registros DNS

- [ ] **URL Correctas**
  - [ ] Verificar que `https://renou01.github.io/RENOU/` abre correctamente
  - [ ] Verificar que todas las secciones cargan (Inicio, Mapa, Formulario, Casos, Info, Panel)

---

## 📱 Funcionalidad Frontend

- [ ] **Navegación**
  - [ ] Probar todos los botones de la navegación
  - [ ] Probar menú burger en móvil (< 860px ancho)
  - [ ] Verificar que el logo y título son correctos

- [ ] **Mapa Interactivo**
  - [ ] Leaflet carga correctamente
  - [ ] Se pueden hacer zoom y pan en el mapa
  - [ ] Los marcadores aparecen (una vez que haya datos en BD)
  - [ ] Filtros funcionan

- [ ] **Formulario F-01**
  - [ ] Todos los 9 pasos navegan correctamente
  - [ ] Validación de campos requeridos funciona
  - [ ] Carga de archivos funciona (drag & drop y click)
  - [ ] Botón GPS solicita permisos correctamente
  - [ ] hCaptcha aparece en el último paso
  - [ ] Envío del formulario funciona

- [ ] **Panel de Investigadores**
  - [ ] Login funciona con credenciales Supabase
  - [ ] Logout limpia sesión
  - [ ] Tabla de casos se carga correctamente
  - [ ] Se pueden editar casos (si el usuario es admin)
  - [ ] Log de actividad registra cambios

- [ ] **Base de Datos**
  - [ ] Los reportes se guardan en Supabase
  - [ ] Las fotos/videos se suben al storage
  - [ ] Los datos se sincroniza en tiempo real
  - [ ] Se pueden consultar mediante filtros

---

## 🎨 Optimización y UX

- [ ] **Performance (Lighthouse)**
  - [ ] Hacer test en Google PageSpeed Insights
  - [ ] Performance: > 80
  - [ ] Accessibility: > 90
  - [ ] Best Practices: > 90
  - [ ] SEO: > 90

- [ ] **Compatibilidad Navegadores**
  - [ ] ✅ Chrome/Chromium (latest)
  - [ ] ✅ Firefox (latest)
  - [ ] ✅ Safari (latest)
  - [ ] ✅ Edge (latest)
  - [ ] ✅ Mobile browsers

- [ ] **Responsive Design**
  - [ ] Desktop (1920px, 1440px, 1024px)
  - [ ] Tablet (768px)
  - [ ] Mobile (480px, 375px)
  - [ ] Orientación landscape y portrait

- [ ] **Carga de Recursos**
  - [ ] Supabase JS CDN carga correctamente
  - [ ] Leaflet CSS y JS cargan correctamente
  - [ ] Fuentes Google Fonts cargan correctamente
  - [ ] hCaptcha API carga correctamente

---

## 📊 SEO y Metadatos

- [ ] **Metadatos**
  - [ ] Title: "RENOU — Registro Nacional de OVNIs y UAPs | AUDIP"
  - [ ] Description: "Registrá avistamientos de OVNIs y UAPs..."
  - [ ] Robots: "index, follow"
  - [ ] Viewport correctamente configurado

- [ ] **Sitemap**
  - [ ] `sitemap.xml` contiene todas las rutas principales
  - [ ] Enviado a Google Search Console
  - [ ] Enviado a Bing Webmaster Tools

- [ ] **robots.txt**
  - [ ] `/panel` está excluido (privado)
  - [ ] Referencia al sitemap incluida

---

## 🛠️ Mantenimiento

- [ ] **Monitoreo**
  - [ ] Configurar Google Analytics (opcional)
  - [ ] Configurar alertas de errores
  - [ ] Revisar logs regularmente

- [ ] **Backups**
  - [ ] Exportar datos de Supabase regularmente
  - [ ] Copia de seguridad del repositorio
  - [ ] Documentar procedimientos de recuperación

- [ ] **Documentación**
  - [ ] README.md actualizado
  - [ ] Instrucciones para nuevos desarrolladores
  - [ ] Documentación de API (si es necesario)
  - [ ] Changelog de versiones

---

## 📝 Problemas Conocidos / TODO

| Prioridad | Problema | Estado | Solución |
|-----------|----------|--------|----------|
| 🔴 Alta | Supabase no conecta | ⏳ Pendiente | Agregar variables de entorno |
| 🔴 Alta | Archivo index.html grande | ✅ Funcional | Considerar separar CSS/JS futuros |
| 🟡 Media | sitemap.xml incompleto | ✅ Corregido | Actualizado con 5 rutas |
| 🟢 Baja | Performance imagen hero | ✅ Funcional | Base64 optimizado |
| 🟢 Baja | Mobile burger menu | ✅ Funcional | Testeado en 480px |

---

## 🚀 Lanzamiento Final

Una vez completado el checklist:

1. Hacer último test en navegadores principales
2. Verificar Google Analytics
3. Anunciar en redes sociales
4. Monitorear primeras 24 horas
5. Celebrar 🎉

---

**Última actualización**: 2026-07-01  
**Responsable**: RENOU Team  
**Estado**: 🟡 En revisión (Supabase pendiente)
