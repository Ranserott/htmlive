# 🎓 Live Code Classroom

Pizarra de código en vivo para clases de programación. El profesor comparte código HTML en tiempo real y los alumnos lo ven instantáneamente.

## ✨ Características

- 🔄 **Sincronización en tiempo real** con WebSockets (Socket.IO)
- 👨‍🏫 **Roles**: Profesor (edita) y Alumnos (solo lectura)
- 📁 **Múltiples archivos**: Gestión de archivos HTML
- 👁️ **Vista previa**: Renderizado en iframe
- 🎨 **Editor CodeMirror**: Con resaltado de sintaxis
- 💾 **Sin base de datos**: Todo en memoria
- 🐳 **Dockerizado**: Listo para deploy

## 🚀 Inicio Rápido

### Opción 1: Con Docker Compose (Recomendado)

```bash
# Clonar el repositorio
cd livecode

# Copiar configuración de ejemplo
cp .env.example .env

# Iniciar con Docker Compose
docker-compose up -d

# Ver logs
docker-compose logs -f
```

La aplicación estará disponible en:
- Frontend: http://localhost:3000
- Backend: http://localhost:3001

### Opción 2: Desarrollo Local

#### Backend
```bash
cd backend
npm install
npm run dev
```

#### Frontend
```bash
cd frontend
npm install
npm run dev
```

## 📖 Uso

### Para Profesores

1. Ve a http://localhost:3000
2. Ingresa un ID de sala (ej: `clase-html-basico`)
3. Haz clic en "👨‍🏫 Entrar como Profesor"
4. Comparte el ID de la sala con tus alumnos
5. ¡Comienza a escribir código! Los cambios se sincronizarán automáticamente

### Para Alumnos

1. Ve a http://localhost:3000
2. Ingresa el mismo ID de sala que te compartió el profesor
3. Haz clic en "👨‍🎓 Entrar como Alumno"
4. ¡Observa el código en tiempo real mientras el profesor escribe!

## 🏗️ Estructura del Proyecto

```
livecode/
├── backend/                 # Servidor Node.js + Socket.IO
│   ├── server.js           # Servidor principal
│   ├── package.json
│   ├── Dockerfile
│   └── README.md
├── frontend/               # Aplicación Nuxt 3
│   ├── components/         # Componentes Vue
│   │   ├── Navbar.vue
│   │   ├── Sidebar.vue
│   │   ├── CodeEditor.vue
│   │   └── Preview.vue
│   ├── composables/        # Composables
│   │   ├── useSocket.js
│   │   └── useDebounce.js
│   ├── pages/              # Rutas
│   │   ├── index.vue
│   │   └── class/
│   │       └── [roomId].vue
│   ├── layouts/
│   │   └── default.vue
│   ├── assets/
│   │   └── css/
│   │       └── main.css
│   ├── app.vue
│   ├── nuxt.config.ts
│   ├── package.json
│   ├── Dockerfile
│   └── README.md
├── docker-compose.yml
├── .env.example
└── README.md
```

## 🚀 Deploy en Dokploy

### 1. Preparar el Repositorio

Asegúrate de tener tu código en un repositorio de Git (GitHub, GitLab, etc.):

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/tuusuario/livecode.git
git push -u origin main
```

### 2. Crear Proyecto en Dokploy

1. Ve a tu panel de Dokploy
2. Crea un nuevo proyecto
3. Selecciona "Web Service"

### 3. Configurar Backend

1. **Nombre**: `livecode-backend`
2. **Repositorio**: URL de tu repo
3. **Rama**: `main`
4. **Dockerfile Path**: `backend/Dockerfile`
5. **Puerto**: `3001`

**Variables de Entorno:**
```
NODE_ENV=production
PORT=3001
FRONTEND_URL=https://tudominio.com
```

### 4. Configurar Frontend

1. **Nombre**: `livecode-frontend`
2. **Repositorio**: URL de tu repo
3. **Rama**: `main`
4. **Dockerfile Path**: `frontend/Dockerfile`
5. **Puerto**: `3000`

**Variables de Entorno:**
```
NODE_ENV=production
NUXT_PUBLIC_SOCKET_URL=https://api.tudominio.com
```

### 5. Configurar Dominios

En Dokploy, configura los dominios:

- **Frontend**: `https://tudominio.com`
- **Backend**: `https://api.tudominio.com` (o subdominio)

### 6. Deploy

1. Haz clic en "Deploy" para ambos servicios
2. Verifica que el backend esté corriendo: `https://api.tudominio.com/health`
3. Accede al frontend: `https://tudominio.com`

## 🔧 Variables de Entorno

### Backend

| Variable | Descripción | Default |
|----------|-------------|---------|
| `PORT` | Puerto del servidor | `3001` |
| `FRONTEND_URL` | URL del frontend (CORS) | `http://localhost:3000` |
| `NODE_ENV` | Entorno de ejecución | `development` |

### Frontend

| Variable | Descripción | Default |
|----------|-------------|---------|
| `NUXT_PUBLIC_SOCKET_URL` | URL del servidor WebSocket | `http://localhost:3001` |

## 📝 Logs

### Ver logs con Docker Compose

```bash
# Todos los servicios
docker-compose logs -f

# Solo backend
docker-compose logs -f backend

# Solo frontend
docker-compose logs -f frontend
```

### Ver logs en Dokploy

Ve a la pestaña "Logs" en cada servicio dentro del panel de Dokploy.

## 🐛 Troubleshooting

### Error de conexión WebSocket

1. Verifica que el backend esté corriendo
2. Revisa la variable `NUXT_PUBLIC_SOCKET_URL` en el frontend
3. Asegúrate de que los CORS estén configurados correctamente

### Los cambios no se sincronizan

1. Verifica que el profesor tenga el rol correcto (`?role=teacher`)
2. Revisa la consola del navegador en busca de errores
3. Verifica la conexión WebSocket en la pestaña Network

### Error "El archivo ya existe"

No puedes crear dos archivos con el mismo nombre. Elimina el archivo existente primero.

## 📄 Licencia

MIT License - Libre para uso personal y comercial.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commitea tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📧 Soporte

Si tienes problemas o preguntas:

1. Revisa la sección de Troubleshooting arriba
2. Crea un issue en el repositorio
3. Contacta al mantenedor del proyecto

---

**¡Disfruta enseñando y aprendiendo código en tiempo real! 🚀**
