import Debug from './debug'

const request = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  console.log(`\u2191 stimulus \u2191 ${reflex.target}`, {
    id: reflex.id,
    args: reflex.data.args,
    controller: reflex.controller.identifier,
    element: reflex.element,
    controllerElement: reflex.controller.element
  })
}

const success = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  const output = {
    id: reflex.id,
    morph: reflex.morph,
    payload: reflex.payload
  }
  if (reflex.operation !== 'dispatch_event') output.operation = reflex.operation
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} \u2192 ${reflex.selector ||
      '\u221E'}${progress(reflex)} ${duration(reflex)}`,
    output
  )
}

const halted = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} ${duration(reflex)} %cHALTED`,
    'color: #ffa500;',
    { id: reflex.id, payload: reflex.payload }
  )
}

const forbidden = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} ${duration(reflex)} %cFORBIDDEN`,
    'color: #BF40BF;',
    { id: reflex.id, payload: reflex.payload }
  )
}

const error = reflex => {
  if (Debug.disabled || reflex.data.suppressLogging) return
  console.log(
    `\u2193 reflex \u2193 ${reflex.target} ${duration(reflex)} %cERROR: ${
      reflex.error
    }`,
    'color: #f00;',
    { id: reflex.id, payload: reflex.payload }
  )
}

const duration = reflex => {
  return !reflex.cloned ? `in ${new Date() - reflex.timestamp}ms` : 'CLONED'
}

const progress = reflex => {
  return reflex.totalOperations > 1
    ? ` ${reflex.completedOperations}/${reflex.totalOperations}`
    : ''
}

export default { request, success, halted, forbidden, error }
