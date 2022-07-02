import Debug from './debug'

import { camelize } from './utils'
import { reflexes } from './reflex_store'

// Invokes a lifecycle method on a StimulusReflex controller.
// - reflex - the Reflex object
//
// - stage - the lifecycle stage
//   * created (at initialization)
//   * before
//   * delivered
//   * queued
//   * success
//   * error
//   * halted
//   * forbidden
//   * after
//   * finalize
//
// - reflexElement - the element that triggered the Reflex (not necessarily the StimulusReflex Controller Element)
// - controllerElement - the element holding the StimulusReflex Controller
// - reflexId - the UUIDv4 which uniquely identifies the Reflex
// - payload - the optional "return value" from the Reflex method
//
const invokeLifecycleMethod = (
  stage,
  reflexElement,
  controllerElement,
  reflexId,
  payload
) => {
  if (!controllerElement || !controllerElement.reflexData[reflexId]) return

  const controller = controllerElement.reflexController[reflexId]
  const reflex = controllerElement.reflexData[reflexId].target
  const reflexMethodName = reflex.split('#')[1]

  const specificLifecycleMethodName = ['before', 'after', 'finalize'].includes(
    stage
  )
    ? `${stage}${camelize(reflexMethodName)}`
    : `${camelize(reflexMethodName, false)}${camelize(stage)}`
  const specificLifecycleMethod = controller[specificLifecycleMethodName]

  const genericLifecycleMethodName = ['before', 'after', 'finalize'].includes(
    stage
  )
    ? `${stage}Reflex`
    : `reflex${camelize(stage)}`
  const genericLifecycleMethod = controller[genericLifecycleMethodName]

  if (typeof specificLifecycleMethod === 'function') {
    specificLifecycleMethod.call(
      controller,
      reflexElement,
      reflex,
      controllerElement.reflexError[reflexId],
      reflexId,
      payload
    )
  }

  if (typeof genericLifecycleMethod === 'function') {
    genericLifecycleMethod.call(
      controller,
      reflexElement,
      reflex,
      controllerElement.reflexError[reflexId],
      reflexId,
      payload
    )
  }
}

document.addEventListener(
  'stimulus-reflex:before',
  event =>
    invokeLifecycleMethod(
      'before',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    ),
  true
)

document.addEventListener(
  'stimulus-reflex:queued',
  event =>
    invokeLifecycleMethod(
      'queued',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    ),
  true
)

document.addEventListener(
  'stimulus-reflex:delivered',
  event =>
    invokeLifecycleMethod(
      'delivered',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    ),
  true
)

document.addEventListener(
  'stimulus-reflex:success',
  event => {
    const reflex = reflexes[event.detail.reflexId]
    invokeLifecycleMethod(
      'success',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    )
    dispatchLifecycleEvent(reflex, 'after')
  },
  true
)

document.addEventListener(
  'stimulus-reflex:nothing',
  event => {
    const reflex = reflexes[event.detail.reflexId]
    dispatchLifecycleEvent(reflex, 'success')
  },
  true
)

document.addEventListener(
  'stimulus-reflex:error',
  event => {
    const reflex = reflexes[event.detail.reflexId]
    invokeLifecycleMethod(
      'error',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    )
    dispatchLifecycleEvent(reflex, 'after')
  },
  true
)

document.addEventListener(
  'stimulus-reflex:halted',
  event =>
    invokeLifecycleMethod(
      'halted',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    ),
  true
)

document.addEventListener(
  'stimulus-reflex:forbidden',
  event =>
    invokeLifecycleMethod(
      'forbidden',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    ),
  true
)

document.addEventListener(
  'stimulus-reflex:after',
  event =>
    invokeLifecycleMethod(
      'after',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    ),
  true
)

document.addEventListener(
  'stimulus-reflex:finalize',
  event =>
    invokeLifecycleMethod(
      'finalize',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId,
      event.detail.payload
    ),
  true
)

// Dispatches a lifecycle event on document
// - reflex - the Reflex object
//
// - stage - the lifecycle stage
//   * created (at initialization)
//   * before
//   * delivered
//   * queued
//   * success
//   * error
//   * halted
//   * forbidden
//   * after
//   * finalize
//
const dispatchLifecycleEvent = (reflex, stage) => {
  if (!reflex.controller) {
    if (Debug.enabled && !reflex.warned) {
      console.warn(
        `StimulusReflex was not able execute callbacks or emit events for "${stage}" or later life-cycle stages for this Reflex. The StimulusReflex Controller Element is no longer present in the DOM. Could you move the StimulusReflex Controller to an element higher in your DOM?`
      )
      reflex.warned = true
    }
    return
  }

  reflex.stage = stage

  // if (
  //   !controllerElement.reflexController ||
  //   (controllerElement.reflexController &&
  //     !controllerElement.reflexController[reflexId])
  // ) {
  //   if (Debug.enabled && !reflex.warned) {
  //     console.warn(
  //       `StimulusReflex detected that the StimulusReflex Controller responsible for this Reflex has been replaced with a new instance. Callbacks and events for "${stage}" or later life-cycle stages cannot be executed.`
  //     )
  //     reflexes[reflexId].warned = true
  //   }
  //   return
  // }

  const event = `stimulus-reflex:${stage}`
  const action = `${event}:${reflex.data.target.split('#')[1]}`
  const detail = {
    reflex: reflex.data.target,
    controller: reflex.controller,
    reflexId: reflex.reflexId,
    element: reflex.element,
    payload: reflex.payload
  }
  const options = { bubbles: true, cancelable: false, detail }

  reflex.controller.element.dispatchEvent(new CustomEvent(event, options))
  reflex.controller.element.dispatchEvent(new CustomEvent(action, options))

  if (window.jQuery) {
    window.jQuery(reflex.controller.element).trigger(event, detail)
    window.jQuery(reflex.controller.element).trigger(action, detail)
  }
}

export { dispatchLifecycleEvent }
