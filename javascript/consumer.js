import { createConsumer } from '@rails/actioncable'

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

export function getConsumer () {
  return findConsumer(window) || createConsumer()
}
