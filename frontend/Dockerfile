# Frontend Dockerfile - Live Code Classroom (Nuxt 3)

# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar package.json
COPY package*.json ./

# Instalar dependencias
RUN npm ci

# Copiar código fuente
COPY . .

# Build de la aplicación
RUN npm run build

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Copiar archivos necesarios desde el builder
COPY --from=builder /app/.output ./.output

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nuxt -u 1001

RUN chown -R nuxt:nodejs /app
USER nuxt

# Exponer puerto
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando de inicio
CMD ["node", ".output/server/index.mjs"]
