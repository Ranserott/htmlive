<template>
  <aside class="sidebar">
    <div class="sidebar-header">
      <span class="sidebar-title">📁 Archivos</span>
      <button 
        v-if="role === 'teacher'" 
        class="btn btn-primary btn-sm"
        @click="showNewFileDialog = true"
        :disabled="!connected"
      >
        + Nuevo
      </button>
    </div>
    
    <div class="file-list">
      <div
        v-for="filename in sortedFiles"
        :key="filename"
        class="file-item"
        :class="{ active: filename === activeFile }"
        @click="selectFile(filename)"
      >
        <span class="file-name">
          <span class="file-icon">📄</span>
          {{ filename }}
        </span>
        <button
          v-if="role === 'teacher' && Object.keys(files).length > 1"
          class="btn-icon"
          @click.stop="deleteFile(filename)"
          :disabled="!connected"
          title="Eliminar archivo"
        >
          🗑️
        </button>
      </div>
    </div>

    <!-- Modal para nuevo archivo -->
    <div v-if="showNewFileDialog" class="modal-overlay" @click.self="showNewFileDialog = false">
      <div class="modal">
        <h3 class="modal-title">Nuevo archivo HTML</h3>
        <input
          ref="newFileInput"
          v-model="newFilename"
          type="text"
          class="modal-input"
          placeholder="ej: pagina2.html"
          @keyup.enter="createFile"
          @keyup.esc="showNewFileDialog = false"
        />
        <div class="modal-actions">
          <button class="btn" @click="showNewFileDialog = false">Cancelar</button>
          <button class="btn btn-primary" @click="createFile" :disabled="!isValidFilename">
            Crear
          </button>
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup>
const props = defineProps({
  files: {
    type: Object,
    required: true
  },
  activeFile: {
    type: String,
    required: true
  },
  role: {
    type: String,
    required: true
  },
  connected: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits([
  'select-file',
  'create-file',
  'delete-file'
])

const showNewFileDialog = ref(false)
const newFilename = ref('')
const newFileInput = ref(null)

const sortedFiles = computed(() => {
  return Object.keys(props.files).sort()
})

const isValidFilename = computed(() => {
  const filename = newFilename.value.trim()
  if (!filename) return false
  if (!filename.endsWith('.html')) return false
  if (props.files[filename]) return false
  return /^[a-zA-Z0-9_-]+\.html$/.test(filename)
})

watch(showNewFileDialog, (val) => {
  if (val) {
    newFilename.value = ''
    nextTick(() => {
      newFileInput.value?.focus()
    })
  }
})

const selectFile = (filename) => {
  if (filename === props.activeFile) return
  emit('select-file', filename)
}

const createFile = () => {
  if (!isValidFilename.value) return
  emit('create-file', newFilename.value.trim())
  showNewFileDialog.value = false
}

const deleteFile = (filename) => {
  if (confirm(`¿Eliminar "${filename}"?`)) {
    emit('delete-file', filename)
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: #16213e;
  border: 1px solid #0f3460;
  border-radius: 8px;
  padding: 24px;
  width: 90%;
  max-width: 400px;
}

.modal-title {
  font-size: 1.1rem;
  margin-bottom: 16px;
  color: #eee;
}

.modal-input {
  width: 100%;
  padding: 10px 12px;
  background: #1a1a2e;
  border: 1px solid #0f3460;
  border-radius: 4px;
  color: #eee;
  font-size: 0.9rem;
  margin-bottom: 16px;
}

.modal-input:focus {
  outline: none;
  border-color: #e94560;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>
