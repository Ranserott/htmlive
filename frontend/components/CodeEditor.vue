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
import CodeMirror from 'codemirror'
import 'codemirror/lib/codemirror.css'
import 'codemirror/theme/dracula.css'
import 'codemirror/mode/xml/xml'
import 'codemirror/mode/css/css'
import 'codemirror/mode/javascript/javascript'
import 'codemirror/mode/htmlmixed/htmlmixed'

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

onMounted(() => {
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
    if (!isUpdatingFromExternal && changeObj.origin !== 'setValue') {
      const value = instance.getValue()
      emit('update:modelValue', value)
    }
  })
  
  watch(() => props.modelValue, (newValue) => {
    if (cmEditor && cmEditor.getValue() !== newValue) {
      lastCursorPosition = cmEditor.getCursor()
      isUpdatingFromExternal = true
      cmEditor.setValue(newValue)
      if (lastCursorPosition) {
        cmEditor.setCursor(lastCursorPosition)
      }
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
    case 'html': return 'htmlmixed'
    case 'css': return 'css'
    case 'javascript': return 'javascript'
    default: return 'htmlmixed'
  }
}
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