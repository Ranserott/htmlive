<template>
  <div class="preview-section">
    <div class="preview-header">
      <span class="preview-title">
        <span>👁️</span>
        <span>Vista Previa</span>
      </span>
      <button class="preview-refresh" @click="refreshPreview" title="Refrescar">
        🔄
      </button>
    </div>
    
    <div class="preview-container">
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
