import reflexes from './reflexes'
import { XPathToElement } from './utils'
import { dispatchLifecycleEvent } from './lifecycle'
import Log from './log'
import Debug from './debug'

export const beforeDOMUpdate = event => {
  const { stimulusReflex } = event.detail || {}
  if (!stimulusReflex) return
  const { reflexId, xpathElement, xpathController } = stimulusReflex
  const controllerElement = XPathToElement(xpathController)
  const reflexElement = XPathToElement(xpathElement)
  const reflex = reflexes[reflexId]
  const promise = reflex.promise
  const payload = event.detail.payload

  reflex.pendingOperations--

  if (reflex.pendingOperations > 0) return

  if (!stimulusReflex.resolveLate)
    setTimeout(() =>
      promise.resolve({
        element: reflexElement,
        event,
        data: promise.data,
        payload
      })
    )

  setTimeout(() =>
    dispatchLifecycleEvent(
      'success',
      reflexElement,
      controllerElement,
      reflexId,
      payload
    )
  )
}

export const afterDOMUpdate = event => {
  const { stimulusReflex } = event.detail || {}
  if (!stimulusReflex) return
  const { reflexId, xpathElement, xpathController } = stimulusReflex
  const controllerElement = XPathToElement(xpathController)
  const reflexElement = XPathToElement(xpathElement)
  const reflex = reflexes[reflexId]
  const promise = reflex.promise
  const payload = event.detail.payload

  reflex.completedOperations++

  if (Debug.enabled) Log.success(event)

  if (reflex.completedOperations < reflex.totalOperations) return

  if (stimulusReflex.resolveLate)
    setTimeout(() =>
      promise.resolve({
        element: reflexElement,
        event,
        data: promise.data,
        payload
      })
    )

  setTimeout(() =>
    dispatchLifecycleEvent(
      'finalize',
      reflexElement,
      controllerElement,
      reflexId,
      payload
    )
  )
}

export const serverMessage = event => {
  const { reflexId, serverMessage, xpathController, xpathElement } =
    event.detail.stimulusReflex || {}
  const { subject, body } = serverMessage
  const controllerElement = XPathToElement(xpathController)
  const reflexElement = XPathToElement(xpathElement)
  const promise = reflexes[reflexId].promise
  const subjects = { error: true, halted: true, nothing: true, success: true }
  const payload = event.detail.payload

  if (controllerElement) {
    controllerElement.reflexError = controllerElement.reflexError || {}
    if (subject === 'error') controllerElement.reflexError[reflexId] = body
  }

  promise[subject === 'error' ? 'reject' : 'resolve']({
    data: promise.data,
    element: reflexElement,
    event,
    toString: () => body,
    payload
  })

  reflexes[reflexId].finalStage = subject === 'halted' ? 'halted' : 'after'

  if (Debug.enabled) Log[subject === 'error' ? 'error' : 'success'](event)

  if (subjects[subject])
    dispatchLifecycleEvent(
      subject,
      reflexElement,
      controllerElement,
      reflexId,
      payload
    )
}
