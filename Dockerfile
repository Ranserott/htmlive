# =============================================================================
# Live Code Classroom - Unified Dockerfile
# Backend (Node.js + Socket.IO) + Frontend (Nuxt 3)
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Backend Dependencies
# -----------------------------------------------------------------------------
FROM node:20-alpine AS backend-deps

WORKDIR /app/backend

# Copy package files
COPY backend/package*.json ./

# Install production dependencies (using npm install instead of npm ci)
RUN npm install --production && \
    npm cache clean --force

# -----------------------------------------------------------------------------
# Stage 2: Frontend Dependencies
# -----------------------------------------------------------------------------
FROM node:20-alpine AS frontend-deps

WORKDIR /app/frontend

# Copy package files
COPY frontend/package*.json ./

# Install all dependencies (including dev for build)
RUN npm install && \
    npm cache clean --force

# -----------------------------------------------------------------------------
# Stage 3: Frontend Build
# -----------------------------------------------------------------------------
FROM node:20-alpine AS frontend-build

WORKDIR /app/frontend

# Copy dependencies
COPY --from=frontend-deps /app/frontend/node_modules ./node_modules

# Copy source code
COPY frontend/ ./

# Build Nuxt application
RUN npm run build

# -----------------------------------------------------------------------------
# Stage 4: Production
# -----------------------------------------------------------------------------
FROM node:20-alpine AS production

# Install dumb-init and other utilities
RUN apk add --no-cache \
    dumb-init \
    curl \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# -----------------------------------------------------------------------------
# Copy Backend
# -----------------------------------------------------------------------------
WORKDIR /app/backend

# Copy node_modules
COPY --from=backend-deps --chown=appuser:appgroup /app/backend/node_modules ./node_modules

# Copy application files
COPY --chown=appuser:appgroup backend/server.js ./
COPY --chown=appuser:appgroup backend/package.json ./

# -----------------------------------------------------------------------------
# Copy Frontend
# -----------------------------------------------------------------------------
WORKDIR /app/frontend

# Copy built application
COPY --from=frontend-build --chown=appuser:appgroup /app/frontend/.output ./.output

# -----------------------------------------------------------------------------
# Create Startup Script
# -----------------------------------------------------------------------------
WORKDIR /app

# Create startup script with proper signal handling
RUN cat > /app/start.sh << 'EOF'
#!/bin/sh
set -e

echo "🚀 Starting Live Code Classroom..."
echo ""

# Function to cleanup processes
cleanup() {
    echo ""
    echo "🛑 Shutting down..."
    if [ -n "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
        wait $BACKEND_PID 2>/dev/null || true
    fi
    if [ -n "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
        wait $FRONTEND_PID 2>/dev/null || true
    fi
    echo "✅ All processes stopped"
    exit 0
}

# Set trap for signals
trap cleanup TERM INT

# Function to check if a service is healthy
check_health() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    echo "🏥 Checking $name health..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo "  ✓ $name is healthy"
            return 0
        fi
        echo "  ⏳ Attempt $attempt/$max_attempts..."
        attempt=$((attempt + 1))
        sleep 1
    done
    
    echo "  ✗ $name failed health check"
    return 1
}

# Check required commands
echo "📋 Checking requirements..."
if ! command -v node >/dev/null 2>&1; then
    echo "  ✗ Node.js is not installed"
    exit 1
fi
echo "  ✓ Node.js $(node -v) is available"

# Start Backend
echo ""
echo "🔧 Starting Backend on port 3001..."
cd /app/backend
node server.js &
BACKEND_PID=$!
echo "  ✓ Backend started with PID: $BACKEND_PID"

# Check backend health
if ! check_health "http://localhost:3001/health" "Backend"; then
    echo "  ✗ Backend failed to start properly"
    cleanup
    exit 1
fi

# Start Frontend
echo ""
echo "🎨 Starting Frontend on port 3000..."
cd /app/frontend
node .output/server/index.mjs &
FRONTEND_PID=$!
echo "  ✓ Frontend started with PID: $FRONTEND_PID"

# Check frontend health
if ! check_health "http://localhost:3000/api/health" "Frontend"; then
    echo "  ✗ Frontend failed to start properly"
    cleanup
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ Live Code Classroom is running!                  ║"
echo "║                                                       ║"
echo "║  🌐 Frontend: http://localhost:3000                   ║"
echo "║  🔌 Backend:  http://localhost:3001                 ║"
echo "║                                                       ║"
echo "║  Press Ctrl+C to stop                                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Wait for all background processes
wait -n
EXIT_CODE=$?

# Cleanup
cleanup

exit $EXIT_CODE
EOF

# Make script executable
RUN chmod +x /app/start.sh

# Change ownership of all files
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# -----------------------------------------------------------------------------
# Expose Ports
# -----------------------------------------------------------------------------
# Frontend port
EXPOSE 3000
# Backend port  
EXPOSE 3001

# -----------------------------------------------------------------------------
# Health Checks
# -----------------------------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD sh -c 'curl -f http://localhost:3001/health && curl -f http://localhost:3000/api/health' || exit 1

# -----------------------------------------------------------------------------
# Start Application
# -----------------------------------------------------------------------------
# Use dumb-init to handle signals properly (PID 1)
ENTRYPOINT ["dumb-init", "--"]

# Run the startup script
CMD ["/app/start.sh"]
