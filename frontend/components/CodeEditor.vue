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
import { EditorView, keymap } from '@codemirror/view'
import { EditorState } from '@codemirror/state'
import { html } from '@codemirror/lang-html'
import { oneDark } from '@codemirror/theme-one-dark'
import { indentWithTab } from '@codemirror/commands'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  activeFile: {
    type: String,
    required: true
  },
  role: {
    type: String,
    required: true
  }
})

const emit = defineEmits(['update:modelValue', 'change'])

const editorRef = ref(null)
let editorView = null
let isUpdating = false

// Configuración del editor según el rol
const createEditorState = (content) => {
  const extensions = [
    html(),
    oneDark,
    keymap.of([indentWithTab]),
    EditorView.theme({
      '&': {
        fontSize: '14px',
        height: '100%'
      },
      '.cm-content': {
        fontFamily: '"Fira Code", "Monaco", "Consolas", monospace'
      },
      '.cm-gutters': {
        backgroundColor: '#16213e',
        borderRight: '1px solid #0f3460'
      }
    }),
    EditorView.updateListener.of((update) => {
      if (update.docChanged && !isUpdating) {
        const newContent = update.state.doc.toString()
        emit('update:modelValue', newContent)
        emit('change', newContent)
      }
    })
  ]

  // Si es estudiante, hacerlo de solo lectura
  if (props.role !== 'teacher') {
    extensions.push(EditorState.readOnly.of(true))
  }

  return EditorState.create({
    doc: content,
    extensions
  })
}

// Inicializar editor
const initEditor = () => {
  if (!editorRef.value) return

  const state = createEditorState(props.modelValue)
  
  editorView = new EditorView({
    state,
    parent: editorRef.value
  })
}

// Actualizar contenido desde fuera
const updateContent = (newContent) => {
  if (!editorView) return
  
  const currentContent = editorView.state.doc.toString()
  if (newContent === currentContent) return

  isUpdating = true
  
  const transaction = editorView.state.update({
    changes: {
      from: 0,
      to: currentContent.length,
      insert: newContent
    }
  })
  
  editorView.dispatch(transaction)
  
  // Resetear flag después de un pequeño delay
  setTimeout(() => {
    isUpdating = false
  }, 10)
}

// Watch para cambios en el contenido desde props
watch(() => props.modelValue, (newValue) => {
  if (newValue !== undefined) {
    updateContent(newValue)
  }
}, { immediate: false })

// Watch para cambios de archivo
watch(() => props.activeFile, () => {
  // El contenido se actualizará vía el v-model del padre
})

onMounted(() => {
  initEditor()
})

onUnmounted(() => {
  if (editorView) {
    editorView.destroy()
    editorView = null
  }
})
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
