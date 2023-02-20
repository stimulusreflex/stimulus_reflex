import CableReady from 'cable_ready'

import Log from './log'

import { reflexes } from './reflexes'
import { dispatchLifecycleEvent } from './lifecycle'

const beforeDOMUpdate = event => {
  const { stimulusReflex } = event.detail || {}
  if (!stimulusReflex) return
  const reflex = reflexes[stimulusReflex.id]

  reflex.pendingOperations--

  if (reflex.pendingOperations > 0) return

  // TODO: remove in v4 - always resolve late
  if (!stimulusReflex.resolveLate)
    setTimeout(() =>
      reflex.promise.resolve({
        element: reflex.element,
        event,
        data: reflex.data,
        payload: reflex.payload,
        id: reflex.id,
        toString: () => ''
      })
    )
  // END TODO: remove

  setTimeout(() => dispatchLifecycleEvent(reflex, 'success'))
}

const afterDOMUpdate = event => {
  const { stimulusReflex } = event.detail || {}
  if (!stimulusReflex) return
  const reflex = reflexes[stimulusReflex.id]

  reflex.completedOperations++
  reflex.selector = event.detail.selector
  reflex.morph = event.detail.stimulusReflex.morph
  reflex.operation = event.type
    .split(':')[1]
    .split('-')
    .slice(1)
    .join('_')

  Log.success(reflex)

  if (reflex.completedOperations < reflex.totalOperations) return

  // TODO: v4 always resolve late (remove if)
  // TODO: v4 simplify to {reflex, toString}
  if (stimulusReflex.resolveLate)
    setTimeout(() =>
      reflex.promise.resolve({
        element: reflex.element,
        event,
        data: reflex.data,
        payload: reflex.payload,
        id: reflex.id,
        toString: () => ''
      })
    )

  setTimeout(() => dispatchLifecycleEvent(reflex, 'finalize'))

  if (reflex.piggybackOperations.length)
    CableReady.perform(reflex.piggybackOperations)
}

const routeReflexEvent = event => {
  const { stimulusReflex, name } = event.detail || {}
  const eventType = name.split('-')[2]

  const eventTypes = { nothing, halted, forbidden, error }

  if (!stimulusReflex || !Object.keys(eventTypes).includes(eventType)) return

  const reflex = reflexes[stimulusReflex.id]
  reflex.completedOperations++
  reflex.pendingOperations--
  reflex.selector = event.detail.selector
  reflex.morph = event.detail.stimulusReflex.morph
  reflex.operation = event.type
    .split(':')[1]
    .split('-')
    .slice(1)
    .join('_')
  if (eventType === 'error') reflex.error = event.detail.error

  eventTypes[eventType](reflex, event)

  setTimeout(() => dispatchLifecycleEvent(reflex, eventType))

  if (reflex.piggybackOperations.length)
    CableReady.perform(reflex.piggybackOperations)
}

const nothing = (reflex, event) => {
  Log.success(reflex)

  // TODO: v4 simplify to {reflex, toString}
  setTimeout(() =>
    reflex.promise.resolve({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      id: reflex.id,
      toString: () => ''
    })
  )
}

const halted = (reflex, event) => {
  Log.halted(reflex, event)

  // TODO: v4 simplify to {reflex, toString}
  setTimeout(() =>
    reflex.promise.resolve({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      id: reflex.id,
      toString: () => ''
    })
  )
}

const forbidden = (reflex, event) => {
  Log.forbidden(reflex, event)

  // TODO: v4 simplify to {reflex, toString}
  setTimeout(() =>
    reflex.promise.resolve({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      id: reflex.id,
      toString: () => ''
    })
  )
}

const error = (reflex, event) => {
  Log.error(reflex, event)

  // TODO: v4 simplify to {reflex, toString}
  // TODO: v4 convert to resolve?
  setTimeout(() =>
    reflex.promise.reject({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      id: reflex.id,
      error: reflex.error,
      toString: () => reflex.error
    })
  )
}

export { beforeDOMUpdate, afterDOMUpdate, routeReflexEvent }
