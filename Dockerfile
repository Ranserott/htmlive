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

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# -----------------------------------------------------------------------------
# Stage 2: Frontend Dependencies
# -----------------------------------------------------------------------------
FROM node:20-alpine AS frontend-deps

WORKDIR /app/frontend

# Copy package files
COPY frontend/package*.json ./

# Install all dependencies (including dev for build)
RUN npm ci && \
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

# Create startup script
RUN cat > /app/start.sh << 'EOF'
#!/bin/sh
set -e

echo "🚀 Starting Live Code Classroom..."

# Function to check if a port is available
check_port() {
    local port=$1
    local name=$2
    if ! nc -z localhost $port 2>/dev/null; then
        echo "  ✓ Port $port ($name) is available"
        return 0
    else
        echo "  ✗ Port $port ($name) is already in use"
        return 1
    fi
}

# Check required commands
echo "📋 Checking requirements..."
if ! command -v node >/dev/null 2>&1; then
    echo "  ✗ Node.js is not installed"
    exit 1
fi
echo "  ✓ Node.js is available"

# Start Backend
echo "🔧 Starting Backend on port 3001..."
cd /app/backend
node server.js &
BACKEND_PID=$!
echo "  ✓ Backend started with PID: $BACKEND_PID"

# Wait a moment for backend to start
sleep 2

# Check if backend is running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "  ✗ Backend failed to start"
    exit 1
fi

# Start Frontend
echo "🎨 Starting Frontend on port 3000..."
cd /app/frontend
node .output/server/index.mjs &
FRONTEND_PID=$!
echo "  ✓ Frontend started with PID: $FRONTEND_PID"

# Wait a moment for frontend to start
sleep 2

# Check if frontend is running
if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    echo "  ✗ Frontend failed to start"
    # Kill backend if frontend failed
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo ""
echo "✅ Live Code Classroom is running!"
echo "   Backend:  http://localhost:3001"
echo "   Frontend: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Wait for any process to exit
wait -n

# Exit with the status of the first process that exited
EXIT_CODE=$?

# Kill all remaining processes
kill $BACKEND_PID $FRONTEND_PID 2>/dev/null

exit $EXIT_CODE
EOF

# Make script executable
RUN chmod +x /app/start.sh

# Change ownership
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
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD sh -c 'curl -f http://localhost:3001/health && curl -f http://localhost:3000/api/health' || exit 1

# -----------------------------------------------------------------------------
# Start Application
# -----------------------------------------------------------------------------
# Use dumb-init to handle signals properly (PID 1)
ENTRYPOINT ["dumb-init", "--"]

# Run the startup script
CMD ["/app/start.sh"]
