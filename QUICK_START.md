# 🚀 Quick Start - GNUBison API + Hub

## Resumen

Has creado:
1. ✅ **Servidor API en Go** (`main.go`)
2. ✅ **Página web hub portable** (`public/index.html`)
3. ✅ **Configuración para Render.com** (`render.yaml`)
4. ✅ **Scripts de deployment** (`build.sh`, `start.sh`)

---

## Probar localmente (5 minutos)

```bash
# 1. Compilar y arrancar servidor
./start.sh

# 2. Abrir navegador
# http://localhost:8080

# 3. En otra terminal, probar API
./test_api.sh
```

---

## Deploy en Render.com (10 minutos)

### Paso 1: Subir a GitHub

```bash
git add .
git commit -m "Deploy GNUBison API"
git push origin master
```

### Paso 2: Crear servicio en Render

1. Ir a https://render.com
2. **New → Web Service**
3. Conectar tu repositorio GitHub
4. Configurar:
   - **Build Command**: `./build.sh`
   - **Start Command**: `./server`
   - **Plan**: Free

5. Click **"Create Web Service"**

### Paso 3: Obtener URL

Render te dará una URL como:
```
https://gnubison-api-xyz123.onrender.com
```

### Paso 4: Actualizar la página

Editar `public/index.html` línea 109:

```html
<input type="text" id="bison-url" 
       value="https://TU-URL-AQUI.onrender.com/api/bison">
```

Commit y push:

```bash
git add public/index.html
git commit -m "Actualizar URL de producción"
git push
```

Render re-desplegará automáticamente.

---

## URLs finales

Después del deploy:

| Recurso | URL |
|---------|-----|
| **Página Hub** | `https://tu-app.onrender.com/` |
| **Health Check** | `https://tu-app.onrender.com/health` |
| **API GNUBison** | `https://tu-app.onrender.com/api/bison` |

---

## Agregar más APIs al Hub

La página `public/index.html` ya tiene **3 slots** para APIs:

1. **GNUBison** (configurado)
2. **Custom API #1** (placeholder)
3. **Custom API #2** (placeholder)

Para activar más APIs:

1. Desplegar tu otra API en Render
2. Copiar su URL
3. En la página, pegar la URL en el campo correspondiente
4. Ingresar JSON de prueba
5. Click en "🚀 Llamar API"

**No necesitas código**, solo configurar las URLs en la interfaz web.

---

## Características del Hub

✅ **Portable**: Un solo archivo HTML  
✅ **Multi-API**: Hasta 3 APIs simultáneas (expandible)  
✅ **Live status**: Círculos verde/rojo indican si API está online  
✅ **JSON highlighting**: Resultado formateado  
✅ **Templates**: Botón para cargar ejemplos  
✅ **Keyboard shortcuts**: Ctrl+Enter para enviar  
✅ **CORS**: Ya configurado  

---

## Arquitectura

```
┌─────────────────────────────────────┐
│  Usuario abre navegador             │
│  https://tu-app.onrender.com        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Servidor Go (Render.com)           │
│                                     │
│  GET  /      → index.html (Hub)     │
│  GET  /health → {"status": "ok"}    │
│  POST /api/bison → Llama ./bridge   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Ejecutable C (bin/bridge)          │
│  Evalúa expresiones CSP             │
│  Retorna JSON                       │
└─────────────────────────────────────┘
```

---

## Costos

### Render.com Free Tier:
- ✅ 750 horas/mes gratis
- ✅ SSL automático
- ✅ Deploy automático desde Git
- ⚠️ Se duerme después de 15 min sin uso
- ⚠️ Cold start: ~30 segundos

### Upgrade a Starter ($7/mes):
- ✅ Siempre activo
- ✅ Sin cold starts
- ✅ Más recursos

---

## Siguientes pasos

### Expandir APIs:
1. Desplegar tu segunda API en Render
2. Agregar URL en el Hub
3. Probar desde la interfaz web

### Personalizar Hub:
- Editar `public/index.html`
- Cambiar colores, títulos, descripción
- Agregar más slots de API (duplicar `.api-card`)

### Autenticación:
- Agregar API keys en headers
- Ver `DEPLOY_RENDER.md` sección "Seguridad"

### Custom Domain:
- Conectar tu dominio propio
- Configurar DNS CNAME
- SSL automático por Render

---

## Archivos importantes

| Archivo | Descripción |
|---------|-------------|
| `main.go` | Servidor API Go |
| `public/index.html` | Página hub (portable) |
| `render.yaml` | Config de Render |
| `build.sh` | Script de compilación |
| `start.sh` | Arrancar servidor local |
| `test_api.sh` | Tests de API |
| `DEPLOY_RENDER.md` | Guía completa de deployment |

---

## Troubleshooting

### "Bridge executable not found"
```bash
make clean && make
```

### "Cannot connect to API"
- Verificar que servidor está corriendo
- Verificar URL en `index.html`
- Revisar logs en Render

### Cold start lento
- Es normal en plan Free
- Primera request tarda ~30s
- Upgrade a Starter para eliminar

### CORS error
- Ya está configurado en `main.go`
- Verificar que `enableCORS()` está activo

---

## Demo

1. **Local**: `./start.sh` → http://localhost:8080
2. **Producción**: Después de deploy → https://tu-app.onrender.com

En la página:
- Pegar JSON de ejemplo
- Click "🚀 Evaluar"
- Ver resultado en verde/rojo

---

## Contacto y mejoras

Para agregar:
- Autenticación con tokens
- Rate limiting
- Logs persistentes
- Métricas con Prometheus
- Webhooks

Ver documentación completa en `DEPLOY_RENDER.md`
