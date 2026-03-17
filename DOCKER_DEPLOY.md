# Live Code Classroom - Docker Deployment Guide

## 🚀 Despliegue Rápido con Docker

### Opción 1: Construcción Local

```bash
# Construir la imagen
docker build -t htmlive:latest .

# Ejecutar el contenedor
docker run -d \
  --name htmlive \
  -p 3000:3000 \
  -p 3001:3001 \
  -e NODE_ENV=production \
  htmlive:latest

# Ver logs
docker logs -f htmlive
```

### Opción 2: Docker Compose (Desarrollo)

```bash
# Usar docker-compose para desarrollo
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

---

## 🐳 Configuración en Dokploy (Recomendado)

### Paso 1: Crear Servicio en Dokploy

1. Ve a tu panel de Dokploy
2. Crea un nuevo servicio tipo **"Web Service"**
3. Selecciona **Dockerfile** como tipo de build

### Paso 2: Configurar Build

| Campo | Valor |
|-------|-------|
| **Repository** | `github.com/Ranserott/htmlive` |
| **Branch** | `main` |
| **Build Type** | `Dockerfile` |
| **Dockerfile** | `Dockerfile` (en raíz) |
| **Port** | `3000` (expondrá 3000 y 3001) |

### Paso 3: Variables de Entorno (Opcional)

Si quieres sobreescribir alguna configuración:

```
NODE_ENV=production
PORT=3001
FRONTEND_PORT=3000
```

### Paso 4: Dominio

Configura tu dominio:

1. En la sección **Domains** del servicio
2. Agrega tu dominio: `htmlive.tudominio.com`
3. Selecciona el puerto `3000` (frontend)

**Nota**: El backend estará disponible en el mismo dominio pero con el puerto 3001, o puedes configurar un subdominio separado si lo prefieres.

### Paso 5: Deploy

1. Haz clic en **Deploy**
2. Espera a que el build termine (toma unos minutos la primera vez)
3. Verifica que los health checks pasen
4. ¡Listo! 🎉

---

## 🔍 Verificación del Deployment

### Health Checks

El contenedor expone dos endpoints de health check:

- **Backend**: `http://tu-dominio.com:3001/health`
- **Frontend**: `http://tu-dominio.com/api/health`

### Logs

Para ver los logs del contenedor:

```bash
# Si tienes acceso SSH al VPS
docker logs -f <nombre-del-contenedor>

# O desde el panel de Dokploy
# Ve a la pestaña "Logs" del servicio
```

---

## 🛠️ Troubleshooting

### "Failed to build: Dockerfile not found"

Asegúrate de que el campo **Dockerfile** en Dokploy esté configurado como `Dockerfile` (sin ruta adicional, ya que está en la raíz).

### "Port already in use"

Asegúrate de que no haya otros servicios usando los puertos 3000 y 3001.

### "Cannot connect to backend"

Verifica que la variable `FRONTEND_URL` esté correctamente configurada si estás usando un dominio personalizado.

### El build tarda mucho

El primer build puede tardar varios minutos porque Docker debe descargar las imágenes base e instalar todas las dependencias. Los builds posteriores serán más rápidos gracias al cache de Docker.

---

## 📚 Recursos Adicionales

- [Dokploy Documentation](https://docs.dokploy.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Socket.IO Documentation](https://socket.io/docs/)
- [Nuxt 3 Documentation](https://nuxt.com/docs)

---

**¿Tienes algún problema con el deployment?** Comparte los logs del error y te ayudo a solucionarlo. 🚀
