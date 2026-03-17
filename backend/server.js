const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    connections: io.engine.clientsCount
  });
});

// Almacenamiento en memoria (sin base de datos)
const classrooms = new Map();

// Logging básico
const log = (message, data = '') => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`, data);
};

io.on('connection', (socket) => {
  const { roomId, role } = socket.handshake.query;
  
  log(`Usuario conectado - Socket: ${socket.id}, Room: ${roomId}, Role: ${role}`);

  if (!roomId) {
    log('Conexión rechazada: roomId no proporcionado');
    socket.disconnect();
    return;
  }

  // Unirse a la sala
  socket.join(roomId);
  socket.roomId = roomId;
  socket.role = role || 'student';

  // Inicializar sala si no existe
  if (!classrooms.has(roomId)) {
    classrooms.set(roomId, {
      activeFile: 'index.html',
      files: {
        'index.html': `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mi Página</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 20px;
      background: #f0f0f0;
    }
    h1 {
      color: #333;
    }
  </style>
</head>
<body>
  <h1>¡Bienvenidos a la clase!</h1>
  <p>Este es el código HTML inicial.</p>
</body>
</html>`
      }
    });
    log(`Sala ${roomId} inicializada`);
  }

  // Enviar estado actual al nuevo usuario
  const roomData = classrooms.get(roomId);
  socket.emit('initial-state', roomData);
  log(`Estado inicial enviado a ${socket.id}`);

  // Notificar a otros que alguien se unió
  socket.to(roomId).emit('user-joined', { 
    socketId: socket.id, 
    role: socket.role 
  });

  // Escuchar cambios de código (solo profesores)
  socket.on('code-change', (data) => {
    if (socket.role !== 'teacher') {
      log(`Intento de edición rechazado - Socket: ${socket.id} no es profesor`);
      return;
    }

    const { filename, content } = data;
    const room = classrooms.get(socket.roomId);
    
    if (!room) return;

    room.files[filename] = content;

    // Broadcast a todos EXCEPTO al emisor
    socket.to(socket.roomId).emit('code-update', {
      filename,
      content
    });

    log(`Código actualizado en ${socket.roomId}/${filename}`);
  });

  // Escuchar cambio de archivo activo (solo profesores)
  socket.on('file-change', (data) => {
    if (socket.role !== 'teacher') return;

    const { filename } = data;
    const room = classrooms.get(socket.roomId);
    
    if (!room || !room.files[filename]) return;

    room.activeFile = filename;

    socket.to(socket.roomId).emit('active-file-update', {
      filename,
      content: room.files[filename]
    });

    log(`Archivo activo cambiado a ${filename} en ${socket.roomId}`);
  });

  // Crear nuevo archivo (solo profesores)
  socket.on('create-file', (data) => {
    if (socket.role !== 'teacher') return;

    const { filename } = data;
    const room = classrooms.get(socket.roomId);
    
    if (!room) return;

    if (room.files[filename]) {
      socket.emit('file-error', { message: 'El archivo ya existe' });
      return;
    }

    room.files[filename] = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${filename}</title>
</head>
<body>
  <h1>${filename}</h1>
</body>
</html>`;

    io.to(socket.roomId).emit('file-created', {
      filename,
      content: room.files[filename]
    });

    log(`Archivo creado: ${filename} en ${socket.roomId}`);
  });

  // Eliminar archivo (solo profesores)
  socket.on('delete-file', (data) => {
    if (socket.role !== 'teacher') return;

    const { filename } = data;
    const room = classrooms.get(socket.roomId);
    
    if (!room || !room.files[filename]) return;

    const fileCount = Object.keys(room.files).length;
    if (fileCount <= 1) {
      socket.emit('file-error', { message: 'Debe haber al menos un archivo' });
      return;
    }

    delete room.files[filename];

    if (room.activeFile === filename) {
      room.activeFile = Object.keys(room.files)[0];
    }

    io.to(socket.roomId).emit('file-deleted', {
      filename,
      newActiveFile: room.activeFile,
      newActiveContent: room.files[room.activeFile]
    });

    log(`Archivo eliminado: ${filename} en ${socket.roomId}`);
  });

  // Manejar desconexión
  socket.on('disconnect', () => {
    log(`Usuario desconectado - Socket: ${socket.id}, Room: ${socket.roomId}`);
    
    socket.to(socket.roomId).emit('user-left', {
      socketId: socket.id,
      role: socket.role
    });
  });
});

const PORT = process.env.PORT || 3001;

server.listen(PORT, () => {
  log(`Servidor WebSocket iniciado en puerto ${PORT}`);
  log(`CORS habilitado para: ${process.env.FRONTEND_URL || 'http://localhost:3000'}`);
});
