import { io } from 'socket.io-client'
import { ref, readonly } from 'vue'

export const useSocket = () => {
  const socket = ref(null)
  const connected = ref(false)
  const connectionError = ref(null)
  
  // Estado compartido - reactive para que los componentes vean los cambios
  const files = ref({})
  const roomId = ref('')
  const role = ref('student')

  const connect = (newRoomId, newRole) => {
    const config = useRuntimeConfig()
    const socketUrl = config.public.socketUrl
    
    roomId.value = newRoomId
    role.value = newRole

    return new Promise((resolve, reject) => {
      socket.value = io(socketUrl, {
        query: { roomId: newRoomId, role: newRole },
        transports: ['websocket', 'polling'],
        reconnection: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 1000
      })

      socket.value.on('connect', () => {
        console.log('✅ Conectado al servidor WebSocket')
        connected.value = true
        connectionError.value = null
        resolve(socket.value)
      })

      socket.value.on('connect_error', (error) => {
        console.error('❌ Error de conexión:', error)
        connectionError.value = error.message
        reject(error)
      })

      socket.value.on('disconnect', (reason) => {
        console.log('⚠️ Desconectado:', reason)
        connected.value = false
      })
      
      // Escuchar eventos del servidor para actualizar el estado compartido
      socket.value.on('initial-state', (data) => {
        console.log('📥 Estado inicial recibido:', data)
        if (data.files) {
          files.value = { ...data.files }
        }
      })
      
      socket.value.on('code-update', (data) => {
        console.log('📥 Código actualizado:', data)
        if (data.filename && data.content !== undefined) {
          files.value[data.filename] = data.content
        }
      })
      
      socket.value.on('file-created', (data) => {
        console.log('📥 Archivo creado:', data)
        if (data.filename && data.content !== undefined) {
          files.value[data.filename] = data.content
        }
      })
      
      socket.value.on('file-deleted', (data) => {
        console.log('📥 Archivo eliminado:', data)
        if (data.filename) {
          const newFiles = { ...files.value }
          delete newFiles[data.filename]
          files.value = newFiles
        }
      })
    })
  }

  const disconnect = () => {
    if (socket.value) {
      socket.value.disconnect()
      socket.value = null
      connected.value = false
    }
  }

  const on = (event, callback) => {
    if (socket.value) {
      socket.value.on(event, callback)
    }
  }

  const off = (event, callback) => {
    if (socket.value) {
      socket.value.off(event, callback)
    }
  }

  const emit = (event, data) => {
    if (socket.value && connected.value) {
      socket.value.emit(event, data)
    }
  }
  
  const updateFile = (filename, content) => {
    emit('code-change', { filename, content })
  }

  return {
    socket: readonly(socket),
    connected: readonly(connected),
    connectionError: readonly(connectionError),
    files: readonly(files),
    roomId: readonly(roomId),
    role: readonly(role),
    connect,
    disconnect,
    on,
    off,
    emit,
    updateFile
  }
}
