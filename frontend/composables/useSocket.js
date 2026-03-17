import { io } from 'socket.io-client'

export const useSocket = () => {
  const socket = ref(null)
  const connected = ref(false)
  const connectionError = ref(null)

  const connect = (roomId, role) => {
    const config = useRuntimeConfig()
    const socketUrl = config.public.socketUrl

    return new Promise((resolve, reject) => {
      socket.value = io(socketUrl, {
        query: { roomId, role },
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

  return {
    socket,
    connected,
    connectionError,
    connect,
    disconnect,
    on,
    off,
    emit
  }
}
