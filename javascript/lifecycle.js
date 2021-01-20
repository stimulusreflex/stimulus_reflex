import { camelize } from './utils'
import Debug from './debug'

// Invokes a lifecycle method on a StimulusReflex controller.
//
// - stage - the lifecycle stage
//   * before
//   * success
//   * error
//   * halted
//   * after
//   * finalize
//
// - reflexElement - the element that triggered the Reflex (not necessarily the StimulusReflex Controller Element)
//
// - controllerElement - the element holding the StimulusReflex Controller
//
// - reflexId - the UUIDv4 which uniquely identifies the Reflex
//
const invokeLifecycleMethod = (
  stage,
  reflexElement,
  controllerElement,
  reflexId
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
      reflexId
    )
  }

  if (typeof genericLifecycleMethod === 'function') {
    genericLifecycleMethod.call(
      controller,
      reflexElement,
      reflex,
      controllerElement.reflexError[reflexId],
      reflexId
    )
  }

  if (reflexes[reflexId] && stage === reflexes[reflexId].finalStage) {
    Reflect.deleteProperty(controllerElement.reflexController, reflexId)
    Reflect.deleteProperty(controllerElement.reflexData, reflexId)
    Reflect.deleteProperty(controllerElement.reflexError, reflexId)
    Reflect.deleteProperty(reflexes, reflexId)
  }
}

document.addEventListener(
  'stimulus-reflex:before',
  event =>
    invokeLifecycleMethod(
      'before',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId
    ),
  true
)

document.addEventListener(
  'stimulus-reflex:success',
  event => {
    invokeLifecycleMethod(
      'success',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId
    )
    dispatchLifecycleEvent(
      'after',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId
    )
  },
  true
)

document.addEventListener(
  'stimulus-reflex:nothing',
  event => {
    invokeLifecycleMethod(
      'success',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId
    )
    dispatchLifecycleEvent(
      'after',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId
    )
  },
  true
)

document.addEventListener(
  'stimulus-reflex:error',
  event => {
    invokeLifecycleMethod(
      'error',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId
    )
    dispatchLifecycleEvent(
      'after',
      event.detail.element,
      event.detail.controller.element,
      event.detail.reflexId
    )
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
      event.detail.reflexId
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
      event.detail.reflexId
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
      event.detail.reflexId
    ),
  true
)

// Dispatches a lifecycle event on document
//
// - stage - the lifecycle stage
//   * before
//   * success
//   * error
//   * halted
//   * after
//   * finalize
//
// - reflexElement - the element that triggered the Reflex (not necessarily the StimulusReflex Controller Element)
//
// - controllerElement - the element holding the StimulusReflex Controller
//
// - reflexId - the UUIDv4 which uniquely identifies the Reflex
//
export const dispatchLifecycleEvent = (
  stage,
  reflexElement,
  controllerElement,
  reflexId
) => {
  if (!controllerElement) {
    if (Debug.enabled && !reflexes[reflexId].warned) {
      console.warn(
        `StimulusReflex was not able execute callbacks or emit events for "${stage}" or later life-cycle stages for this Reflex. The StimulusReflex Controller Element is no longer present in the DOM. Could you move the StimulusReflex Controller to an element higher in your DOM?`
      )
      reflexes[reflexId].warned = true
    }
    return
  }

  if (
    !controllerElement.reflexController ||
    (controllerElement.reflexController &&
      !controllerElement.reflexController[reflexId])
  ) {
    if (Debug.enabled && !reflexes[reflexId].warned) {
      console.warn(
        `StimulusReflex detected that the StimulusReflex Controller responsible for this Reflex has been replaced with a new instance. Callbacks and events for "${stage}" or later life-cycle stages cannot be executed.`
      )
      reflexes[reflexId].warned = true
    }
    return
  }

  const { target } = controllerElement.reflexData[reflexId] || {}
  const controller = controllerElement.reflexController[reflexId] || {}
  const event = `stimulus-reflex:${stage}`
  const detail = {
    reflex: target,
    controller,
    reflexId,
    element: reflexElement
  }

  controllerElement.dispatchEvent(
    new CustomEvent(event, { bubbles: true, cancelable: false, detail })
  )
  if (window.jQuery) window.jQuery(controllerElement).trigger(event, detail)
}
