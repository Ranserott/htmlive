<template>
  <div v-if="loading" class="loading-overlay">
    <div class="spinner"></div>
    <p class="loading-text">Conectando a la sala...</p>
  </div>

  <template v-else>
    <Navbar 
      :room-id="roomId" 
      :role="role" 
      :connected="connected" 
    />
    
    <div class="main-container">
      <Sidebar
        :files="files"
        :active-file="activeFile"
        :role="role"
        :connected="connected"
        @select-file="handleFileChange"
        @create-file="handleCreateFile"
        @delete-file="handleDeleteFile"
      />
      
      <CodeEditor
        v-model="currentContent"
        :active-file="activeFile"
        :role="role"
        @change="handleCodeChange"
      />
      
      <Preview :content="currentContent" />
    </div>
  </template>
</template>

<script setup>
import { useSocket } from '~/composables/useSocket'
import { useDebounce } from '~/composables/useDebounce'

const route = useRoute()
const router = useRouter()

const roomId = ref(route.params.roomId)
const role = ref(route.query.role || 'student')
const loading = ref(true)

// Estado de la aplicación
const files = ref({})
const activeFile = ref('index.html')
const currentContent = ref('')

// Socket
const { 
  connected, 
  connect, 
  disconnect, 
  on, 
  emit 
} = useSocket()

// Debounce para enviar cambios (300ms)
const debouncedEmit = useDebounce((event, data) => {
  emit(event, data)
}, 300)

// Manejadores de eventos
const handleCodeChange = (content) => {
  if (role.value !== 'teacher') return
  
  // Actualizar localmente inmediatamente
  files.value[activeFile.value] = content
  
  // Emitir con debounce
  debouncedEmit('code-change', {
    filename: activeFile.value,
    content
  })
}

const handleFileChange = (filename) => {
  if (filename === activeFile.value) return
  
  if (role.value === 'teacher') {
    emit('file-change', { filename })
  }
  
  // Actualizar localmente
  activeFile.value = filename
  currentContent.value = files.value[filename] || ''
}

const handleCreateFile = (filename) => {
  if (role.value !== 'teacher') return
  emit('create-file', { filename })
}

const handleDeleteFile = (filename) => {
  if (role.value !== 'teacher') return
  emit('delete-file', { filename })
}

// Eventos del socket
const setupSocketListeners = () => {
  // Estado inicial
  on('initial-state', (data) => {
    console.log('📥 Estado inicial recibido:', data)
    files.value = data.files || {}
    activeFile.value = data.activeFile || 'index.html'
    currentContent.value = files.value[activeFile.value] || ''
    loading.value = false
  })

  // Actualización de código (broadcast)
  on('code-update', (data) => {
    console.log('📥 Código actualizado:', data.filename)
    if (data.filename === activeFile.value) {
      currentContent.value = data.content
    }
    // Actualizar en la lista de archivos
    if (files.value[data.filename] !== undefined) {
      files.value[data.filename] = data.content
    }
  })

  // Cambio de archivo activo
  on('active-file-update', (data) => {
    console.log('📥 Archivo activo cambiado:', data.filename)
    activeFile.value = data.filename
    currentContent.value = data.content
    // Asegurar que el archivo esté en la lista
    if (!files.value[data.filename]) {
      files.value[data.filename] = data.content
    }
  })

  // Nuevo archivo creado
  on('file-created', (data) => {
    console.log('📥 Archivo creado:', data.filename)
    files.value[data.filename] = data.content
    // Si es profesor, cambiar al nuevo archivo
    if (role.value === 'teacher') {
      activeFile.value = data.filename
      currentContent.value = data.content
    }
  })

  // Archivo eliminado
  on('file-deleted', (data) => {
    console.log('📥 Archivo eliminado:', data.filename)
    delete files.value[data.filename]
    
    // Si el archivo eliminado era el activo, cambiar al nuevo
    if (activeFile.value === data.filename) {
      activeFile.value = data.newActiveFile
      currentContent.value = data.newActiveContent
    }
  })

  // Errores
  on('file-error', (data) => {
    console.error('❌ Error:', data.message)
    alert(data.message)
  })

  // Eventos de conexión
  on('connect', () => {
    console.log('✅ Conectado al servidor')
  })

  on('disconnect', () => {
    console.log('⚠️ Desconectado del servidor')
  })

  on('connect_error', (error) => {
    console.error('❌ Error de conexión:', error)
    loading.value = false
    alert('Error al conectar con el servidor. Por favor intenta de nuevo.')
  })
}

// Inicialización
onMounted(async () => {
  console.log('🚀 Iniciando conexión...')
  console.log('Room ID:', roomId.value)
  console.log('Role:', role.value)

  // Validar parámetros
  if (!roomId.value) {
    alert('ID de sala no válido')
    router.push('/')
    return
  }

  // Configurar listeners antes de conectar
  setupSocketListeners()

  try {
    // Conectar al servidor
    await connect(roomId.value, role.value)
  } catch (error) {
    console.error('Error al conectar:', error)
    loading.value = false
  }
})

onUnmounted(() => {
  disconnect()
})
</script>
