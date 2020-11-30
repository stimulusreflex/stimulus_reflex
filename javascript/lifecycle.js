import { camelize } from './utils'
import { findElement, extractElementAttributes } from './attributes'
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
// - element - the element that triggered the reflex (not necessarily the Stimulus controller's element)
//
const invokeLifecycleMethod = (stage, element, reflexId) => {
  if (!element || !element.reflexData[reflexId]) return

  const controller = element.reflexController[reflexId]
  const reflex = element.reflexData[reflexId].target
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
      element,
      reflex,
      element.reflexError[reflexId],
      reflexId
    )
  }

  if (typeof genericLifecycleMethod === 'function') {
    genericLifecycleMethod.call(
      controller,
      element,
      reflex,
      element.reflexError[reflexId],
      reflexId
    )
  }

  if (reflexes[reflexId] && stage === reflexes[reflexId].finalStage) {
    Reflect.deleteProperty(element.reflexController, reflexId)
    Reflect.deleteProperty(element.reflexData, reflexId)
    Reflect.deleteProperty(element.reflexError, reflexId)
    Reflect.deleteProperty(reflexes, reflexId)
  }
}

document.addEventListener(
  'stimulus-reflex:before',
  event => invokeLifecycleMethod('before', event.target, event.detail.reflexId),
  true
)

document.addEventListener(
  'stimulus-reflex:success',
  event => {
    invokeLifecycleMethod('success', event.target, event.detail.reflexId)
    dispatchLifecycleEvent('after', event.target, event.detail.reflexId)
  },
  true
)

document.addEventListener(
  'stimulus-reflex:nothing',
  event => {
    invokeLifecycleMethod('success', event.target, event.detail.reflexId)
    dispatchLifecycleEvent('after', event.target, event.detail.reflexId)
  },
  true
)

document.addEventListener(
  'stimulus-reflex:error',
  event => {
    invokeLifecycleMethod('error', event.target, event.detail.reflexId)
    dispatchLifecycleEvent('after', event.target, event.detail.reflexId)
  },
  true
)

document.addEventListener(
  'stimulus-reflex:halted',
  event => invokeLifecycleMethod('halted', event.target, event.detail.reflexId),
  true
)

document.addEventListener(
  'stimulus-reflex:after',
  event => invokeLifecycleMethod('after', event.target, event.detail.reflexId),
  true
)

document.addEventListener(
  'stimulus-reflex:finalize',
  event =>
    invokeLifecycleMethod('finalize', event.target, event.detail.reflexId),
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
// - element - the element that triggered the reflex (not necessarily the Stimulus controller's element)
//
export const dispatchLifecycleEvent = (stage, element, reflexId) => {
  if (!element) {
    if (Debug.enabled && stage !== 'finalize')
      console.warn(
        `StimulusReflex was not able execute the "${stage}" or later life-cycle methods on the element which triggered the Reflex. The element is no longer present in the DOM. Could you move the Reflex action to an element higher in your DOM?`
      )
    return
  }

  const reflexData = element.reflexData || {}
  const reflexController = element.reflexController || {}
  const reflexError = element.reflexError || {}
  const oldElement = element

  if (!document.body.contains(element)) {
    const attrs = extractElementAttributes(element)
    element = findElement(attrs)

    if (Debug.enabled)
      console.warn(
        `StimulusReflex detected that the element which triggered the Reflex has been replaced by a morph operartion. If you rely on all life-cycle methods to be executed, move the Reflex action to an element higher in your DOM.`
      )
  }

  if (!element) {
    if (Debug.enabled && stage !== 'finalize')
      console.warn(
        `StimulusReflex was not able execute the "${stage}" or later life-cycle methods on the element which triggered the Reflex. The following element is no longer present in the DOM: `,
        oldElement
      )
    return
  }

  element.reflexData = reflexData
  element.reflexController = reflexController
  element.reflexError = reflexError

  const { target } = element.reflexData[reflexId] || {}
  const { controller } = element.reflexController[reflexId] || {}
  const event = `stimulus-reflex:${stage}`
  const detail = { reflex: target, controller, reflexId }

  element.dispatchEvent(
    new CustomEvent(event, { bubbles: true, cancelable: false, detail })
  )
  if (window.jQuery) window.jQuery(element).trigger(event, detail)
}
