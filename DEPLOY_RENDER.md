# Deployment en Render.com

## Paso 1: Preparar repositorio Git

```bash
# Inicializar git (si no está inicializado)
git init

# Agregar archivos
git add .
git commit -m "Preparar deployment en Render.com"

# Subir a GitHub
git remote add origin https://github.com/TU_USUARIO/gnubison.git
git push -u origin master
```

---

## Paso 2: Deploy de la API (Go)

### En Render.com:

1. **Ir a** https://render.com/
2. **Crear cuenta** o iniciar sesión
3. **New → Web Service**
4. **Conectar repositorio** GitHub
5. **Configurar**:
   - Name: `gnubison-api`
   - Region: `Oregon (US West)`
   - Branch: `master`
   - Root Directory: `.` (raíz)
   - Environment: `Go`
   - Build Command: `./build.sh`
   - Start Command: `./server`
   - Plan: `Free`

6. **Environment Variables** (opcional):
   - `PORT`: (automático)

7. **Click "Create Web Service"**

### URL resultante:
```
https://gnubison-api.onrender.com
```

---

## Paso 3: Deploy de la página web (Static Site)

### Opción A: Servir desde la misma API Go

Actualizar `main.go` para servir archivos estáticos:

```go
// Agregar al main()
fs := http.FileServer(http.Dir("./public"))
http.Handle("/", fs)
```

Así la página estará en:
```
https://gnubison-api.onrender.com/
```

### Opción B: Static Site separado en Render

1. **New → Static Site**
2. **Configurar**:
   - Name: `api-hub`
   - Build Command: (vacío)
   - Publish Directory: `public`
3. **Deploy**

URL:
```
https://api-hub.onrender.com
```

---

## Paso 4: Configurar la página web

Editar `public/index.html` línea ~109:

```html
<input type="text" id="bison-url" 
       value="https://TU-APP.onrender.com/api/bison">
```

Reemplaza `TU-APP` con el nombre de tu servicio en Render.

---

## Estructura final

```
Tu App en Render
├── API Backend (Go)
│   URL: https://gnubison-api.onrender.com
│   Endpoints:
│     GET  /health
│     POST /api/bison
│     GET  /              → Página web
│
└── Archivos servidos desde /
    └── index.html → Hub de APIs
```

---

## Prueba local antes de deploy

```bash
# Compilar bridge
make

# Compilar servidor Go
go build -o server main.go

# Ejecutar
PORT=8080 ./server

# Abrir navegador
open http://localhost:8080
```

---

## Custom Domain (opcional)

En Render.com:

1. **Settings → Custom Domain**
2. **Agregar**: `api.tudominio.com`
3. **Configurar DNS**:
   ```
   CNAME  api  →  gnubison-api.onrender.com
   ```

---

## Render.yaml (alternativa automática)

Ya tienes `render.yaml` configurado. Puedes usar:

**Blueprint Deployment**:
1. En Render: **New → Blueprint**
2. Conectar repo
3. Render lee `render.yaml` y despliega automáticamente

---

## Monitoreo

### Logs en Render:
- Dashboard → Tu servicio → Logs

### Health check:
```bash
curl https://tu-app.onrender.com/health
```

### Desde la página web:
- El círculo verde/rojo indica si la API está online
- Se actualiza cada 30 segundos

---

## Costos

**Plan Free**:
- ✅ Suficiente para pruebas
- ⚠️ Se duerme después de 15 min de inactividad
- ⚠️ Primer request tarda ~30s (cold start)

**Plan Starter ($7/mes)**:
- ✅ Siempre activo
- ✅ Sin cold starts
- ✅ SSL automático

---

## Expandir el Hub

Para agregar más APIs a la página:

1. **Editar `public/index.html`**
2. **Duplicar un `.api-card`**
3. **Cambiar IDs** (`custom1` → `custom3`, etc.)
4. **Actualizar la URL** de la nueva API

Ejemplo:

```html
<div class="api-card">
    <h2>
        Mi Otra API
        <span class="api-status checking" id="status-otra"></span>
    </h2>
    <p>Descripción de tu API.</p>

    <div class="form-group">
        <label>API URL:</label>
        <input type="text" id="otra-url" 
               value="https://otra-api.onrender.com/endpoint">
    </div>

    <div class="form-group">
        <label>JSON Input:</label>
        <textarea id="otra-input"></textarea>
    </div>

    <button onclick="callAPI('otra')" id="btn-otra">
        🚀 Llamar API
    </button>

    <div class="result-container" id="result-otra">
        <h3>Resultado:</h3>
        <div class="result-content" id="result-content-otra"></div>
    </div>
</div>
```

Agregar al script:

```javascript
window.addEventListener('load', () => {
    checkAPIStatus('bison');
    checkAPIStatus('otra');  // ← Agregar
});
```

---

## Troubleshooting

### Error: "bridge executable not found"
- Verificar que `make` se ejecutó correctamente
- Revisar logs de build en Render
- Verificar que `bin/bridge` existe

### Error: CORS
- Verificar que `enableCORS()` está en `main.go`
- Headers ya configurados para `*`

### API lenta
- Plan Free: esperar ~30s en cold start
- Upgrade a Starter para eliminar latencia

### Página no carga
- Verificar que `public/index.html` existe
- Verificar que Go sirve archivos estáticos
- Revisar console del navegador (F12)

---

## Siguientes pasos

1. ✅ Deploy de API en Render
2. ✅ Actualizar URL en `index.html`
3. ✅ Abrir `https://tu-app.onrender.com`
4. 🎯 Agregar más APIs al hub
5. 🎯 Custom domain (opcional)
6. 🎯 Autenticación con API keys (producción)
