<template>
  <div class="room-selector">
    <div class="room-card">
      <h1>🎓 Live Code Classroom</h1>
      <p class="subtitle">Pizarra de código en vivo para clases de programación</p>
      
      <div class="form-group">
        <label for="roomId">ID de la Sala</label>
        <input
          id="roomId"
          v-model="roomId"
          type="text"
          placeholder="ej: clase-html-basico"
          @keyup.enter="joinAsStudent"
        />
        <small class="hint">
          Usa el mismo ID que tu profesor para unirte a la clase
        </small>
      </div>

      <div class="button-group">
        <button class="btn btn-primary btn-large" @click="joinAsStudent">
          👨‍🎓 Entrar como Alumno
        </button>
        <button class="btn btn-secondary btn-large" @click="joinAsTeacher">
          👨‍🏫 Entrar como Profesor
        </button>
      </div>

      <div class="info-section">
        <h3>¿Cómo funciona?</h3>
        <ul>
          <li>📤 El profesor comparte el ID de la sala con los alumnos</li>
          <li>✏️ El profesor puede editar código en tiempo real</li>
          <li>👀 Los alumnos ven los cambios instantáneamente</li>
          <li>💾 No se guarda nada - todo es en memoria</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
const roomId = ref('')
const router = useRouter()

// Cargar última sala usada
onMounted(() => {
  const lastRoom = localStorage.getItem('lastRoomId')
  if (lastRoom) {
    roomId.value = lastRoom
  }
})

const joinAsStudent = () => {
  if (!validateRoom()) return
  navigateToRoom('student')
}

const joinAsTeacher = () => {
  if (!validateRoom()) return
  navigateToRoom('teacher')
}

const validateRoom = () => {
  const id = roomId.value.trim().toLowerCase()
  
  if (!id) {
    alert('Por favor ingresa un ID de sala')
    return false
  }
  
  if (!/^[a-z0-9-]+$/.test(id)) {
    alert('El ID solo puede contener letras minúsculas, números y guiones')
    return false
  }
  
  if (id.length < 3) {
    alert('El ID debe tener al menos 3 caracteres')
    return false
  }
  
  return true
}

const navigateToRoom = (role) => {
  const id = roomId.value.trim().toLowerCase()
  localStorage.setItem('lastRoomId', id)
  
  router.push({
    path: `/class/${id}`,
    query: { role }
  })
}
</script>

<style scoped>
.room-selector {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
}

.room-card {
  background: #16213e;
  border: 1px solid #0f3460;
  border-radius: 12px;
  padding: 40px;
  max-width: 600px;
  width: 100%;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
}

h1 {
  text-align: center;
  margin-bottom: 10px;
  color: #e94560;
  font-size: 1.8rem;
}

.subtitle {
  text-align: center;
  color: #888;
  margin-bottom: 30px;
  font-size: 0.95rem;
}

.form-group {
  margin-bottom: 25px;
}

label {
  display: block;
  margin-bottom: 8px;
  color: #ccc;
  font-size: 0.9rem;
  font-weight: 500;
}

input {
  width: 100%;
  padding: 12px 15px;
  background: #1a1a2e;
  border: 1px solid #0f3460;
  border-radius: 6px;
  color: #eee;
  font-size: 1rem;
  transition: all 0.2s;
}

input:focus {
  outline: none;
  border-color: #e94560;
  box-shadow: 0 0 0 3px rgba(233, 69, 96, 0.1);
}

.hint {
  display: block;
  margin-top: 8px;
  color: #666;
  font-size: 0.8rem;
}

.button-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 30px;
}

.btn-large {
  padding: 14px 24px;
  font-size: 1rem;
  border-radius: 8px;
}

.btn-secondary {
  background: transparent;
  color: #e94560;
  border: 2px solid #e94560;
}

.btn-secondary:hover {
  background: #e94560;
  color: white;
}

.info-section {
  border-top: 1px solid #0f3460;
  padding-top: 25px;
}

.info-section h3 {
  font-size: 1rem;
  margin-bottom: 15px;
  color: #ccc;
}

.info-section ul {
  list-style: none;
}

.info-section li {
  padding: 6px 0;
  color: #888;
  font-size: 0.9rem;
}

.info-section li::before {
  content: '';
  margin-right: 8px;
}
</style>
