import { createConsumer } from '@rails/actioncable'

function connectionOpened () {
  document.body.removeAttribute('data-action-cable-disconnected')
  document.body.setAttribute('data-action-cable-connected', '')
}

function connectionClosed () {
  document.body.removeAttribute('data-action-cable-connected')
  document.body.setAttribute('data-action-cable-disconnected', '')
}

function isConsumer (object) {
  if (object) {
    try {
      return (
        object.constructor.name === 'Consumer' &&
        object.connect &&
        object.disconnect &&
        object.send
      )
    } catch (e) {}
  }
  return false
}

function findConsumer (object, depth = 0) {
  if (!object) return null
  if (depth > 3) return null
  if (isConsumer(object)) return object
  return Object.values(object)
    .map(o => findConsumer(o, depth + 1))
    .find(o => o)
}

export function registerConsumer (consumer) {
  const connection = consumer.connection
  const socket = connection.webSocket
  socket.removeEventListener('open', connectionOpened)
  socket.addEventListener('open', connectionOpened)
  socket.removeEventListener('close', connectionClosed)
  socket.addEventListener('close', connectionClosed)
  socket.removeEventListener('error', connectionClosed)
  socket.addEventListener('error', connectionClosed)
  if (connection.isOpen()) connectionOpened()
}

export function getConsumer () {
  return findConsumer(window) || createConsumer()
}
