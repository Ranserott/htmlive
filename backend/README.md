# Backend - Live Code Classroom

Servidor WebSocket con Socket.IO para sincronización de código en tiempo real.

## Características

- WebSockets con Socket.IO
- Múltiples salas (rooms) independientes
- Roles: teacher (edita) y student (solo lectura)
- Sin base de datos - todo en memoria
- Logs básicos de conexión

## Instalación

```bash
npm install
```

## Desarrollo

```bash
npm run dev
```

## Producción

```bash
npm start
```

## Variables de Entorno

```env
PORT=3001
FRONTEND_URL=http://localhost:3000
```

## Estructura de Datos

```javascript
{
  activeFile: string,        // Archivo actual
  files: {
    [filename]: string       // Contenido de cada archivo
  }
}
```

## Eventos Socket.IO

### Cliente → Servidor

- `code-change`: Profesor actualiza código
- `file-change`: Cambiar archivo activo
- `create-file`: Crear nuevo archivo
- `delete-file`: Eliminar archivo

### Servidor → Cliente

- `initial-state`: Estado inicial al conectar
- `code-update`: Código actualizado (broadcast)
- `active-file-update`: Archivo activo cambiado
- `file-created`: Nuevo archivo creado
- `file-deleted`: Archivo eliminado

## Docker

```bash
docker build -t livecode-backend .
docker run -p 3001:3001 livecode-backend
```
