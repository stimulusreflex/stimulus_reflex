import Debug from './debug'

import { reflexes } from './reflex_store'

const request = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  console.log(`\u2191 stimulus \u2191 ${reflex.target}`, {
    reflexId: reflex.reflexId,
    args: reflex.data.args,
    controller: reflex.controller.identifier,
    element: reflex.element,
    controllerElement: reflex.controller.element
  })
}

const success = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  const progress =
    reflex.totalOperations > 1
      ? ` ${reflex.completedOperations}/${reflex.totalOperations}`
      : ''
  const duration = !reflex.cloned
    ? `in ${new Date() - reflex.timestamp}ms`
    : 'CLONED'
  const output = {
    reflexId: reflex.reflexId,
    morph: reflex.morph,
    payload: reflex.payload
  }
  if (reflex.operation !== 'dispatch_event') output.operation = reflex.operation
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} \u2192 ${reflex.selector ||
      '\u221E'}${progress} ${duration}`,
    output
  )
}

const halted = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  const duration = !reflex.cloned
    ? `in ${new Date() - reflex.timestamp}ms`
    : 'CLONED'
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} ${duration} %cHALTED`,
    'color: #ffa500;',
    { reflexId: reflex.reflexId, payload: reflex.payload }
  )
}

const forbidden = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  const duration = !reflex.cloned
    ? `in ${new Date() - reflex.timestamp}ms`
    : 'CLONED'
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} ${duration} %cFORBIDDEN`,
    'color: #BF40BF;',
    { reflexId: reflex.reflexId, payload: reflex.payload }
  )
}

const error = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  const duration = !reflex.cloned
    ? `in ${new Date() - reflex.timestamp}ms`
    : 'CLONED'
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} ${duration} %cERROR: ${reflex.error}`,
    'color: #f00;',
    { reflexId: reflex.reflexId, payload: reflex.payload }
  )
}

export default { request, success, halted, forbidden, error }
