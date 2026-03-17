# Simple Dockerfile para Live Code Classroom
# Backend + Frontend en un solo contenedor

FROM node:20-alpine

# Instalar herramientas necesarias
RUN apk add --no-cache dumb-init curl

# Crear usuario no-root
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Crear directorio de trabajo
WORKDIR /app

# ============================================
# BACKEND
# ============================================
WORKDIR /app/backend

# Copiar archivos del backend
COPY backend/package*.json ./
COPY backend/server.js ./

# Instalar dependencias del backend
RUN npm install --production && \
    npm cache clean --force

# ============================================
# FRONTEND
# ============================================
WORKDIR /app/frontend

# Copiar archivos del frontend
COPY frontend/package*.json ./
COPY frontend/nuxt.config.ts ./
COPY frontend/app.vue ./
COPY frontend/assets ./assets/
COPY frontend/components ./components/
COPY frontend/composables ./composables/
COPY frontend/layouts ./layouts/
COPY frontend/pages ./pages/
COPY frontend/server ./server/

# Instalar dependencias del frontend
RUN npm install && \
    npm cache clean --force

# Build del frontend
RUN npm run build

# ============================================
# CONFIGURACIÓN FINAL
# ============================================
WORKDIR /app

# Cambiar permisos
RUN chown -R appuser:appgroup /app

# Crear script de inicio
RUN cat > /app/start.sh << 'ENDSCRIPT'
#!/bin/sh
set -e

echo "🚀 Starting Live Code Classroom..."

# Función para limpiar procesos
cleanup() {
    echo ""
    echo "🛑 Shutting down..."
    if [ -n "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ -n "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    echo "✅ Stopped"
    exit 0
}

# Capturar señales
trap cleanup TERM INT

# Iniciar Backend
echo "🔧 Starting Backend on port 3001..."
cd /app/backend
PORT=3001 node server.js &
BACKEND_PID=$!
echo "  ✓ Backend PID: $BACKEND_PID"

# Esperar a que el backend esté listo
echo "  ⏳ Waiting for backend..."
sleep 3

# Verificar que el backend responde
if ! curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo "  ✗ Backend failed to start"
    cleanup
    exit 1
fi
echo "  ✓ Backend is ready"

# Iniciar Frontend
echo ""
echo "🎨 Starting Frontend on port 3000..."
cd /app/frontend
node .output/server/index.mjs &
FRONTEND_PID=$!
echo "  ✓ Frontend PID: $FRONTEND_PID"

# Esperar a que el frontend esté listo
echo "  ⏳ Waiting for frontend..."
sleep 3

# Verificar que el frontend responde
if ! curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "  ✗ Frontend failed to start"
    cleanup
    exit 1
fi
echo "  ✓ Frontend is ready"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Live Code Classroom is running!   ║"
echo "║                                        ║"
echo "║  🌐 Frontend: http://localhost:3000  ║"
echo "║  🔌 Backend:  http://localhost:3001  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Mantener el script corriendo
wait
ENDSCRIPT

# Hacer el script ejecutable
RUN chmod +x /app/start.sh

# Cambiar al usuario no-root
USER appuser

# Exponer puertos
EXPOSE 3000 3001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD sh -c 'curl -f http://localhost:3001/health && curl -f http://localhost:3000/api/health' || exit 1

# Usar dumb-init para manejo de señales
ENTRYPOINT ["dumb-init", "--"]

# Comando de inicio
CMD ["/app/start.sh"]
