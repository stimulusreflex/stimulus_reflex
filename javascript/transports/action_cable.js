import { emitEvent } from '../utils'

let consumer
let params
let subscriptionActive

const connected = () => {
  subscriptionActive = true
  emitEvent('stimulus-reflex:connected')
}

const rejected = () => {
  subscriptionActive = false
  emitEvent('stimulus-reflex:rejected')
  if (Debug.enabled) console.warn('Channel subscription was rejected.')
}

const disconnected = willAttemptReconnect => {
  subscriptionActive = false
  emitEvent('stimulus-reflex:disconnected', willAttemptReconnect)
}

export default {
  consumer,
  params,
  get subscriptionActive () {
    return subscriptionActive
  },
  connected,
  rejected,
  disconnected
}
