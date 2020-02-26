import { createConsumer } from '@rails/actioncable'

let consumer

function isConsumer (object) {
  try {
    return (
      object.constructor.name === 'Consumer' &&
      object.connect &&
      object.disconnect &&
      object.send
    )
  } catch {
    return false
  }
}

function findConsumer (a) {
  let hit
  if (isConsumer(a)) hit = a
  if (!consumer && a) hit = Object.values(a).find(b => isConsumer(b))
  if (!consumer && a) {
    Object.values(a).forEach(b => {
      if (b) hit = hit || Object.values(b).find(c => isConsumer(c))
    })
  }
  return hit
}

export function getConsumer () {
  return (consumer = consumer || findConsumer(window) || createConsumer())
}
