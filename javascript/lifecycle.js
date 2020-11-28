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
      element.reflexError,
      reflexId
    )
  }

  if (typeof genericLifecycleMethod === 'function') {
    genericLifecycleMethod.call(
      controller,
      element,
      reflex,
      element.reflexError,
      reflexId
    )
  }

  if (reflexes[reflexId] && stage === reflexes[reflexId].finalStage) {
    delete element.reflexController[reflexId]
    delete element.reflexData[reflexId]
    delete element.reflexError
    delete reflexes[reflexId]
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
    if (Debug.enabled) console.warn(`StimulusReflex was not able execute the "${stage}" lifecycle method on the element which triggered the reflex because the element is not present anymore.`)
    return
  }

  const reflexData = element.reflexData || {}
  const reflexController = element.reflexController || {}
  const oldElement = element

  if (!document.body.contains(element)) {
    const attrs = extractElementAttributes(element)
    element = findElement(attrs)

    if (Debug.enabled) console.warn(`StimulusReflex detected that the element which triggered the reflex was replaced with a morph operartion. This is not recommended! Make sure you don't replace the element with a morph operartion if you rely on all lifecycle methods to be executed.`)
  }

  if (!element) {
    if (Debug.enabled) console.warn(`StimulusReflex was not able execute the "${stage}" lifecycle method on the element which triggered the reflex because the element is not present anymore. Was looking for element: `, oldElement)
    return
  }

  element.reflexData = reflexData
  element.reflexController = reflexController

  const { target } = element.reflexData[reflexId] || {}
  const { controller } = element.reflexController[reflexId] || {}

  element.dispatchEvent(
    new CustomEvent(`stimulus-reflex:${stage}`, {
      bubbles: true,
      cancelable: false,
      detail: {
        reflex: target,
        controller,
        reflexId
      }
    })
  )
}
