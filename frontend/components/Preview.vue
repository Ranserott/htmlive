<template>
  <div class="preview-section" :class="{ collapsed: !isExpanded }">
    <div class="preview-header">
      <span class="preview-title">
        <span>👁️</span>
        <span v-if="isExpanded">Vista Previa</span>
      </span>
      <div class="preview-actions">
        <button 
          v-if="isExpanded"
          class="preview-refresh" 
          @click="refreshPreview" 
          title="Refrescar"
        >
          🔄
        </button>
        <button 
          class="preview-toggle" 
          @click="togglePreview" 
          :title="isExpanded ? 'Ocultar' : 'Mostrar'"
        >
          {{ isExpanded ? '→' : '👁️' }}
        </button>
      </div>
    </div>
    
    <div v-if="isExpanded" class="preview-container">
      <iframe
        ref="iframeRef"
        class="preview-frame"
        :srcdoc="srcdoc"
        sandbox="allow-scripts"
        @load="onIframeLoad"
      ></iframe>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  content: {
    type: String,
    default: ''
  }
})

const iframeRef = ref(null)
const iframeLoaded = ref(false)
const isExpanded = ref(true)

// Generar srcdoc con el contenido
const srcdoc = computed(() => {
  if (!props.content) {
    return `<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      font-family: Arial, sans-serif;
      background: #f5f5f5;
      color: #999;
    }
  </style>
</head>
<body>
  <p>Selecciona un archivo para ver la vista previa</p>
</body>
</html>`
  }
  return props.content
})

const refreshPreview = () => {
  if (iframeRef.value) {
    iframeLoaded.value = false
    // Recargar el iframe
    const currentSrcdoc = iframeRef.value.srcdoc
    iframeRef.value.srcdoc = ''
    nextTick(() => {
      iframeRef.value.srcdoc = currentSrcdoc
    })
  }
}

const togglePreview = () => {
  isExpanded.value = !isExpanded.value
}

const onIframeLoad = () => {
  iframeLoaded.value = true
}

// Watch para cambios en el contenido - la actualización es automática via srcdoc
watch(() => props.content, (newContent, oldContent) => {
  if (newContent !== oldContent) {
    // El iframe se actualizará automáticamente porque srcdoc es reactivo
    iframeLoaded.value = false
  }
})
</script>

<style scoped>
.preview-section {
  width: 45%;
  min-width: 300px;
  display: flex;
  flex-direction: column;
  border-left: 1px solid #0f3460;
  transition: all 0.3s ease;
}

.preview-section.collapsed {
  width: 50px;
  min-width: 50px;
  border-left: 1px solid #0f3460;
}

.preview-header {
  height: 40px;
  background: #16213e;
  border-bottom: 1px solid #0f3460;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 10px;
}

.preview-title {
  font-size: 0.85rem;
  color: #888;
  display: flex;
  align-items: center;
  gap: 8px;
}

.preview-actions {
  display: flex;
  align-items: center;
  gap: 5px;
}

.preview-refresh {
  background: transparent;
  border: none;
  color: #888;
  cursor: pointer;
  font-size: 0.85rem;
  padding: 4px 6px;
  border-radius: 4px;
  transition: all 0.2s;
}

.preview-refresh:hover {
  background: #0f3460;
  color: #fff;
}

.preview-toggle {
  background: #0f3460;
  border: none;
  color: #888;
  cursor: pointer;
  font-size: 0.9rem;
  padding: 4px 8px;
  border-radius: 4px;
  transition: all 0.2s;
  font-weight: bold;
}

.preview-toggle:hover {
  background: #e94560;
  color: white;
}

.preview-container {
  flex: 1;
  background: white;
  overflow: hidden;
}

.preview-frame {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
