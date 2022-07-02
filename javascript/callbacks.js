import CableReady from 'cable_ready'

import Log from './log'

import { reflexes } from './reflex_store'
import { dispatchLifecycleEvent } from './lifecycle'
import { XPathToElement } from './utils'

const beforeDOMUpdate = event => {
  const { stimulusReflex, payload } = event.detail || {}
  if (!stimulusReflex) return
  const { reflexId, xpathElement, xpathController } = stimulusReflex
  const controllerElement = XPathToElement(xpathController)
  const reflexElement = XPathToElement(xpathElement)
  const reflex = reflexes[reflexId]
  const { promise } = reflex

  reflex.pendingOperations--

  if (reflex.pendingOperations > 0) return

  // TODO: v4 always resolve late
  if (!stimulusReflex.resolveLate)
    setTimeout(() =>
      promise.resolve({
        element: reflex.element,
        event,
        data: reflex.data,
        payload,
        reflexId,
        toString: () => ''
      })
    )

  setTimeout(() => dispatchLifecycleEvent(reflex, 'success'))
}

const afterDOMUpdate = event => {
  const { stimulusReflex, payload } = event.detail || {}
  if (!stimulusReflex) return
  const { reflexId, xpathElement, xpathController } = stimulusReflex
  const controllerElement = XPathToElement(xpathController)
  const reflexElement = XPathToElement(xpathElement)
  const reflex = reflexes[reflexId]
  const { promise } = reflex

  reflex.completedOperations++

  Log.success(event, false)

  if (reflex.completedOperations < reflex.totalOperations) return

  // TODO: v4 always resolve late
  if (stimulusReflex.resolveLate)
    setTimeout(() =>
      promise.resolve({
        element: reflex.element,
        event,
        data: reflex.data,
        payload,
        reflexId,
        toString: () => ''
      })
    )

  setTimeout(() => dispatchLifecycleEvent(reflex, 'finalize'))

  if (reflex.piggybackOperations.length)
    CableReady.perform(reflex.piggybackOperations)
}

const routeReflexEvent = event => {
  const { stimulusReflex, payload, name, body } = event.detail || {}
  const eventType = name.split('-')[2]

  const eventTypes = {
    nothing: nothing,
    halted: halted,
    forbidden: forbidden,
    error: error
  }

  if (!stimulusReflex || !Object.keys(eventTypes).includes(eventType)) return

  const { reflexId, xpathElement, xpathController } = stimulusReflex
  const reflexElement = XPathToElement(xpathElement)
  const controllerElement = XPathToElement(xpathController)
  const reflex = reflexes[reflexId]
  const { promise } = reflex

  if (controllerElement) {
    controllerElement.reflexError = controllerElement.reflexError || {}
    if (eventType === 'error') controllerElement.reflexError[reflexId] = body
  }

  eventTypes[eventType](event, payload, promise, reflex, reflexElement)

  setTimeout(() => dispatchLifecycleEvent(reflex, eventType))

  if (reflex.piggybackOperations.length)
    CableReady.perform(reflex.piggybackOperations)
}

const nothing = (event, payload, promise, reflex, reflexElement) => {
  Log.success(event)

  setTimeout(() =>
    promise.resolve({
      data: promise.data,
      element: reflexElement,
      event,
      payload,
      reflexId: promise.reflexId,
      toString: () => ''
    })
  )
}

const halted = (event, payload, promise, reflex, reflexElement) => {
  Log.halted(event)

  setTimeout(() =>
    promise.resolve({
      data: promise.data,
      element: reflexElement,
      event,
      payload,
      reflexId: promise.data.reflexId,
      toString: () => ''
    })
  )
}

const forbidden = (event, payload, promise, reflex, reflexElement) => {
  Log.forbidden(event)

  setTimeout(() =>
    promise.resolve({
      data: promise.data,
      element: reflexElement,
      event,
      payload,
      reflexId: promise.data.reflexId,
      toString: () => ''
    })
  )
}

const error = (event, payload, promise, reflex, reflexElement) => {
  Log.error(event)

  setTimeout(() =>
    promise.reject({
      data: promise.data,
      element: reflexElement,
      event,
      payload,
      reflexId: promise.data.reflexId,
      error: event.detail.body,
      toString: () => event.detail.body
    })
  )
}

export { beforeDOMUpdate, afterDOMUpdate, routeReflexEvent }
