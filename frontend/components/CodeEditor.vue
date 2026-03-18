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
  // Dynamic imports for CodeMirror 6
  const { EditorView, basicSetup } = await import('@codemirror/basic-setup')
  const { html } = await import('@codemirror/lang-html')
  const { css } = await import('@codemirror/lang-css')
  const { javascript } = await import('@codemirror/lang-javascript')
  const { oneDark } = await import('@codemirror/theme-one-dark')
  
  // Determine language extension
  let langExtension
  switch (props.language) {
    case 'css':
      langExtension = css()
      break
    case 'javascript':
      langExtension = javascript()
      break
    case 'html':
    default:
      langExtension = html()
  }
  
  cmEditor = new EditorView({
    doc: props.modelValue,
    extensions: [
      basicSetup,
      langExtension,
      oneDark,
      EditorView.updateListener.of((update) => {
        if (update.docChanged && !isUpdatingFromExternal) {
          const value = update.state.doc.toString()
          emit('update:modelValue', value)
        }
      }),
      EditorView.theme({
        '&': {
          height: '100%',
          fontSize: '14px'
        },
        '.cm-content': {
          fontFamily: '"Fira Code", "Monaco", "Consolas", monospace'
        },
        '.cm-gutters': {
          backgroundColor: '#16213e',
          borderRight: '1px solid #0f3460'
        }
      })
    ],
    parent: editorRef.value
  })
  
  watch(() => props.modelValue, (newValue) => {
    if (cmEditor && cmEditor.state.doc.toString() !== newValue) {
      isUpdatingFromExternal = true
      const transaction = cmEditor.state.update({
        changes: {
          from: 0,
          to: cmEditor.state.doc.length,
          insert: newValue
        }
      })
      cmEditor.dispatch(transaction)
      setTimeout(() => {
        isUpdatingFromExternal = false
      }, 0)
    }
  }, { flush: 'sync' })
})

onBeforeUnmount(() => {
  if (cmEditor) {
    cmEditor.destroy()
    cmEditor = null
  }
})
</script>

<style scoped>
.editor-section {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #1a1a2e;
}

.editor-tabs {
  display: flex;
  background: #16213e;
  border-bottom: 1px solid #0f3460;
  padding: 0 10px;
}

.editor-tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 15px;
  background: #1a1a2e;
  border: 1px solid #0f3460;
  border-bottom: none;
  color: #eaeaea;
  font-size: 13px;
  cursor: pointer;
}

.editor-tab .icon {
  font-size: 14px;
}

.editor-container {
  flex: 1;
  position: relative;
  overflow: hidden;
}

.editor-readonly {
  position: absolute;
  top: 10px;
  right: 10px;
  background: rgba(255, 193, 7, 0.9);
  color: #000;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: bold;
  z-index: 100;
}

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