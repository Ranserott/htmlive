<template>
  <div class="editor-section">
    <div class="editor-tabs">
      <div class="editor-tab">
        <span class="icon">✏️</span>
        <span>{{ activeFile }}</span>
      </div>
    </div>
    
    <div class="editor-container">
      <div v-if="role !== 'teacher'" class="editor-readonly">
        MODO SOLO LECTURA
      </div>
      
      <div ref="editorRef" class="codemirror-wrapper"></div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  language: {
    type: String,
    default: 'html'
  }
})

const emit = defineEmits(['update:modelValue'])

const editorRef = ref(null)
let cmEditor = null
let isUpdatingFromExternal = false
let lastCursorPosition = null

onMounted(async () => {
  const { default: CodeMirror } = await import('codemirror')
  await import('codemirror/lib/codemirror.css')
  await import('codemirror/theme/dracula.css')
  
  // Import language modes
  if (props.language === 'html') await import('codemirror/mode/xml/xml')
  if (props.language === 'css') await import('codemirror/mode/css/css')
  if (props.language === 'javascript') await import('codemirror/mode/javascript/javascript')
  
  cmEditor = CodeMirror(editorRef.value, {
    value: props.modelValue,
    mode: getMode(props.language),
    theme: 'dracula',
    lineNumbers: true,
    lineWrapping: true,
    tabSize: 2,
    indentWithTabs: false,
    autofocus: true
  })
  
  cmEditor.on('change', (instance, changeObj) => {
    // Solo emitir si el cambio viene del usuario (no de actualización externa)
    if (!isUpdatingFromExternal && changeObj.origin !== 'setValue') {
      const value = instance.getValue()
      emit('update:modelValue', value)
    }
  })
  
  // Watch para cambios externos (desde socket)
  watch(() => props.modelValue, (newValue) => {
    if (cmEditor && cmEditor.getValue() !== newValue) {
      // Guardar posición del cursor antes de actualizar
      lastCursorPosition = cmEditor.getCursor()
      
      // Marcar que estamos actualizando desde fuera
      isUpdatingFromExternal = true
      
      // Actualizar el valor
      cmEditor.setValue(newValue)
      
      // Restaurar posición del cursor
      if (lastCursorPosition) {
        cmEditor.setCursor(lastCursorPosition)
      }
      
      // Desmarcar bandera después de un pequeño delay
      setTimeout(() => {
        isUpdatingFromExternal = false
      }, 0)
    }
  }, { flush: 'sync' })
})

onBeforeUnmount(() => {
  if (cmEditor) {
    cmEditor.toTextArea()
    cmEditor = null
  }
})

function getMode(language) {
  switch (language) {
    case 'html': return 'xml'
    case 'css': return 'css'
    case 'javascript': return 'javascript'
    default: return 'xml'
  }
}
</script>

<style scoped>
.codemirror-wrapper {
  height: 100%;
  width: 100%;
}

.codemirror-wrapper :deep(.cm-editor) {
  height: 100% !important;
}

.codemirror-wrapper :deep(.cm-scroller) {
  overflow: auto;
}
</style>
