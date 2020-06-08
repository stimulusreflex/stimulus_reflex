import { camelize } from './utils'

// Invokes a lifecycle method on a StimulusReflex controller.
//
// - stage - the lifecycle stage
//   * before
//   * success
//   * error
//   * halted
//   * after
//
// - element - the element that triggered the reflex (not necessarily the Stimulus controller's element)
//
const invokeLifecycleMethod = (stage, element) => {
  if (!element || !element.reflexData) return
  const controller = element.reflexController
  const reflex = element.reflexData.target
  const reflexMethodName = reflex.split('#')[1]

  const specificLifecycleMethodName = ['before', 'after'].includes(stage)
    ? `${stage}${camelize(reflexMethodName)}`
    : `${camelize(reflexMethodName, false)}${camelize(stage)}`
  const specificLifecycleMethod = controller[specificLifecycleMethodName]

  const genericLifecycleMethodName = ['before', 'after'].includes(stage)
    ? `${stage}Reflex`
    : `reflex${camelize(stage)}`
  const genericLifecycleMethod = controller[genericLifecycleMethodName]

  if (stage === 'before') {
    if (element.hasAttribute('data-reflex-disable')) {
      element.disabled = true
    }

    if (element.hasAttribute('data-reflex-disable-with')) {
      element.disabled = true
      element.dataset.enableWith = element.innerHTML
      element.innerHTML = element.dataset.reflexDisableWith
    }
  }

  if (stage === 'after') {
    if (element.hasAttribute('data-reflex-disable')) {
      element.disabled = false
    }

    if (element.hasAttribute('data-reflex-disable-with')) {
      element.innerHTML = element.dataset.enableWith
      element.removeAttribute('data-enable-with')
      element.disabled = false
    }
  }

  if (typeof specificLifecycleMethod === 'function') {
    setTimeout(() =>
      specificLifecycleMethod.call(
        controller,
        element,
        reflex,
        element.reflexError
      )
    )
  }

  if (typeof genericLifecycleMethod === 'function') {
    setTimeout(() =>
      genericLifecycleMethod.call(
        controller,
        element,
        reflex,
        element.reflexError
      )
    )
  }

  // lifecycle cleanup
  if (stage === 'after') {
    delete element.reflexController
    delete element.reflexData
    delete element.reflexError
  }
}

document.addEventListener(
  'stimulus-reflex:before',
  event => invokeLifecycleMethod('before', event.target),
  true
)

document.addEventListener(
  'stimulus-reflex:success',
  event => {
    invokeLifecycleMethod('success', event.target)
    dispatchLifecycleEvent('after', event.target)
  },
  true
)

document.addEventListener(
  'stimulus-reflex:error',
  event => {
    invokeLifecycleMethod('error', event.target)
    dispatchLifecycleEvent('after', event.target)
  },
  true
)

document.addEventListener(
  'stimulus-reflex:halted',
  event => invokeLifecycleMethod('halted', event.target),
  true
)

document.addEventListener(
  'stimulus-reflex:after',
  event => invokeLifecycleMethod('after', event.target),
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
//
// - element - the element that triggered the reflex (not necessarily the Stimulus controller's element)
//
export const dispatchLifecycleEvent = (stage, element) => {
  if (!element) return
  const { target } = element.reflexData || {}
  element.dispatchEvent(
    new CustomEvent(`stimulus-reflex:${stage}`, {
      bubbles: true,
      cancelable: false,
      detail: {
        reflex: target,
        controller: element.reflexController
      }
    })
  )
}
