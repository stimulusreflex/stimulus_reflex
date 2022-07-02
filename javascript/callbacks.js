import CableReady from 'cable_ready'

import Log from './log'

import { reflexes } from './reflex_store'
import { dispatchLifecycleEvent } from './lifecycle'

const beforeDOMUpdate = event => {
  const { stimulusReflex } = event.detail || {}
  if (!stimulusReflex) return
  const reflex = reflexes[stimulusReflex.reflexId]

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
        reflexId: reflex.reflexId,
        toString: () => ''
      })
    )
  // END TODO: remove

  setTimeout(() => dispatchLifecycleEvent(reflex, 'success'))
}

const afterDOMUpdate = event => {
  const { stimulusReflex } = event.detail || {}
  if (!stimulusReflex) return
  const reflex = reflexes[stimulusReflex.reflexId]

  reflex.completedOperations++

  Log.success(event, false)

  if (reflex.completedOperations < reflex.totalOperations) return

  // TODO: v4 always resolve late (remove if)
  // TODO: v4 simplify to reflex, event, toString
  if (stimulusReflex.resolveLate)
    setTimeout(() =>
      reflex.promise.resolve({
        element: reflex.element,
        event,
        data: reflex.data,
        payload: reflex.payload,
        reflexId: reflex.reflexId,
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

  const reflex = reflexes[stimulusReflex.reflexId]
  reflex.completedOperations++
  reflex.pendingOperations--
  if (eventType === 'error') reflex.error = event.detail.error

  eventTypes[eventType](reflex, event)

  setTimeout(() => dispatchLifecycleEvent(reflex, eventType))

  if (reflex.piggybackOperations.length)
    CableReady.perform(reflex.piggybackOperations)
}

const nothing = (reflex, event) => {
  Log.success(event)

  // TODO: v4 simplify to reflex, event, toString
  setTimeout(() =>
    reflex.promise.resolve({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      reflexId: reflex.reflexId,
      toString: () => ''
    })
  )
}

const halted = (reflex, event) => {
  Log.halted(event)

  // TODO: v4 simplify to reflex, event, toString
  setTimeout(() =>
    reflex.promise.resolve({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      reflexId: reflex.reflexId,
      toString: () => ''
    })
  )
}

const forbidden = (reflex, event) => {
  Log.forbidden(event)

  // TODO: v4 simplify to reflex, event, toString
  setTimeout(() =>
    reflex.promise.resolve({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      reflexId: reflex.reflexId,
      toString: () => ''
    })
  )
}

const error = (reflex, event) => {
  Log.error(event)

  // TODO: v4 simplify to reflex, event, toString
  setTimeout(() =>
    reflex.promise.reject({
      data: reflex.data,
      element: reflex.element,
      event,
      payload: reflex.payload,
      reflexId: reflex.reflexId,
      error: reflex.error,
      toString: () => reflex.error
    })
  )
}

export { beforeDOMUpdate, afterDOMUpdate, routeReflexEvent }
