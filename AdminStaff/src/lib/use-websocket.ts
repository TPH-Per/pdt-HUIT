import { Client, IMessage } from '@stomp/stompjs'
import { ref, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

const WS_URL = import.meta.env.VITE_WS_URL || 'http://localhost:8081'

export function useWebSocket(destination: string, callback: (message: any) => void) {
  const client = ref<Client | null>(null)
  const connected = ref(false)
  const authStore = useAuthStore()

  const connect = () => {
    if (client.value?.connected) {
      return
    }

    client.value = new Client({
      brokerURL: `${WS_URL}/ws`,
      connectHeaders: {
        Authorization: `Bearer ${authStore.token}`,
      },
      reconnectDelay: 3000,
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,
      debug: (str) => {
        console.log('STOMP:', str)
      },
    })

    client.value.onConnect = () => {
      console.log('WebSocket connected')
      connected.value = true
      
      if (destination) {
        client.value?.subscribe(destination, (message: IMessage) => {
          const body = JSON.parse(message.body)
          callback(body)
        })
      }
    }

    client.value.onStompError = (frame) => {
      console.error('STOMP error:', frame)
      connected.value = false
    }

    client.value.onDisconnect = () => {
      console.log('WebSocket disconnected')
      connected.value = false
    }

    client.value.activate()
  }

  const disconnect = () => {
    if (client.value) {
      client.value.deactivate()
      client.value = null
      connected.value = false
    }
  }

  const sendMessage = (dest: string, body: any) => {
    if (client.value?.connected) {
      client.value.publish({
        destination: dest,
        body: JSON.stringify(body),
      })
    }
  }

  connect()

  onUnmounted(() => {
    disconnect()
  })

  return {
    connected,
    sendMessage,
    disconnect,
    reconnect: connect,
  }
}
