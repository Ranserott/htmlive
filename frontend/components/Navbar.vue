<template>
  <nav class="navbar">
    <div class="navbar-left">
      <span class="navbar-title">🎓 livecodeprofe</span>
      <span class="navbar-room">Room: {{ roomId }}</span>
    </div>
    <div class="navbar-right">
      <span class="role-badge" :class="role === 'teacher' ? 'role-teacher' : 'role-student'">
        {{ role === 'teacher' ? '👨‍🏫 Profesor' : '👨‍🎓 Alumno' }}
      </span>
      <span v-if="connected" class="connection-status connected">●</span>
      <span v-else class="connection-status disconnected">●</span>
    </div>
  </nav>
</template>

<script setup>
const props = defineProps({
  roomId: {
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
</script>

<style scoped>
.navbar-right {
  display: flex;
  align-items: center;
  gap: 15px;
}

.connection-status {
  font-size: 0.7rem;
  animation: pulse 2s infinite;
}

.connection-status.connected {
  color: #4ade80;
}

.connection-status.disconnected {
  color: #ef4444;
  animation: none;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
</style>
