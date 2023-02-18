import Debug from './debug'

import { camelize } from './utils'
import { reflexes } from './reflexes'

// lifecycle stages
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

// Invokes a lifecycle method on a StimulusReflex controller.
// - reflex - the Reflex object
// - stage - the lifecycle stage
//
const invokeLifecycleMethod = (reflex, stage) => {
  // TODO: v4 reevaluate benefit of naming complexity vs semantic payoff
  const specificLifecycleMethod =
    reflex.controller[
      ['before', 'after', 'finalize'].includes(stage)
        ? `${stage}${camelize(reflex.action)}`
        : `${camelize(reflex.action, false)}${camelize(stage)}`
    ]

  const genericLifecycleMethod =
    reflex.controller[
      ['before', 'after', 'finalize'].includes(stage)
        ? `${stage}Reflex`
        : `reflex${camelize(stage)}`
    ]

  // TODO: v4 just pass reflex into the lifecycle method
  if (typeof specificLifecycleMethod === 'function') {
    specificLifecycleMethod.call(
      reflex.controller,
      reflex.element,
      reflex.target,
      reflex.error,
      reflex.id,
      reflex.payload
    )
  }

  // TODO: v4 just pass reflex into the lifecycle method
  if (typeof genericLifecycleMethod === 'function') {
    genericLifecycleMethod.call(
      reflex.controller,
      reflex.element,
      reflex.target,
      reflex.error,
      reflex.id,
      reflex.payload
    )
  }
}

// Dispatches a lifecycle event on document
// - reflex - the Reflex object
// - stage - the lifecycle stage
//
const dispatchLifecycleEvent = (reflex, stage) => {
  if (!reflex.controller.element.parentElement) {
    if (Debug.enabled && !reflex.warned) {
      console.warn(
        `StimulusReflex was not able execute callbacks or emit events for "${stage}" or later life-cycle stages for this Reflex. The StimulusReflex Controller Element is no longer present in the DOM. Could you move the StimulusReflex Controller to an element higher in your DOM?`
      )
      reflex.warned = true
    }
    return
  }

  reflex.stage = stage
  reflex.lifecycle.push(stage)

  const event = `stimulus-reflex:${stage}`
  const action = `${event}:${reflex.action}`
  // TODO: v4 detail = reflex
  const detail = {
    reflex: reflex.target,
    controller: reflex.controller,
    id: reflex.id,
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

document.addEventListener(
  'stimulus-reflex:before',
  event => invokeLifecycleMethod(reflexes[event.detail.id], 'before'),
  true
)

document.addEventListener(
  'stimulus-reflex:queued',
  event => invokeLifecycleMethod(reflexes[event.detail.id], 'queued'),
  true
)

document.addEventListener(
  'stimulus-reflex:delivered',
  event => invokeLifecycleMethod(reflexes[event.detail.id], 'delivered'),
  true
)

document.addEventListener(
  'stimulus-reflex:success',
  event => {
    const reflex = reflexes[event.detail.id]
    invokeLifecycleMethod(reflex, 'success')
    dispatchLifecycleEvent(reflex, 'after')
  },
  true
)

document.addEventListener(
  'stimulus-reflex:nothing',
  event => dispatchLifecycleEvent(reflexes[event.detail.id], 'success'),
  true
)

document.addEventListener(
  'stimulus-reflex:error',
  event => {
    const reflex = reflexes[event.detail.id]
    invokeLifecycleMethod(reflex, 'error')
    // TODO: v4 remove after events on error; behave like halted and forbidden
    dispatchLifecycleEvent(reflex, 'after')
  },
  true
)

document.addEventListener(
  'stimulus-reflex:halted',
  event => invokeLifecycleMethod(reflexes[event.detail.id], 'halted'),
  true
)

document.addEventListener(
  'stimulus-reflex:forbidden',
  event => invokeLifecycleMethod(reflexes[event.detail.id], 'forbidden'),
  true
)

document.addEventListener(
  'stimulus-reflex:after',
  event => invokeLifecycleMethod(reflexes[event.detail.id], 'after'),
  true
)

document.addEventListener(
  'stimulus-reflex:finalize',
  event => invokeLifecycleMethod(reflexes[event.detail.id], 'finalize'),
  true
)

export { dispatchLifecycleEvent }
