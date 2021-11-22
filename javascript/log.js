import reflexes from './reflexes'
import Debug from './debug'

const request = (
  reflexId,
  target,
  args,
  controller,
  element,
  controllerElement
) => {
  const reflex = reflexes[reflexId]
  if (Debug.disabled || reflex.promise.data.suppressLogging) return
  reflex.timestamp = new Date()
  console.log(`\u2191 stimulus \u2191 ${target}`, {
    reflexId,
    args,
    controller,
    element,
    controllerElement
  })
}

const success = (event, halted) => {
  const { detail } = event || {}
  const { selector, payload } = detail || {}
  const { reflexId, target, morph } = detail.stimulusReflex || {}
  const reflex = reflexes[reflexId]
  if (Debug.disabled || reflex.promise.data.suppressLogging) return
  const progress =
    reflex.totalOperations > 1
      ? ` ${reflex.completedOperations}/${reflex.totalOperations}`
      : ''
  const duration = reflex.timestamp
    ? `in ${new Date() - reflex.timestamp}ms`
    : 'CLONED'
  const operation = event.type
    .split(':')[1]
    .split('-')
    .slice(1)
    .join('_')
  console.log(
    `\u2193 reflex \u2193 ${target} \u2192 ${selector ||
      '\u221E'}${progress} ${duration}`,
    { reflexId, morph, operation, halted, payload }
  )
}

const error = event => {
  const { detail } = event || {}
  const { reflexId, target, payload } = detail.stimulusReflex || {}
  const reflex = reflexes[reflexId]
  if (Debug.disabled || reflex.promise.data.suppressLogging) return
  const duration = reflex.timestamp
    ? `in ${new Date() - reflex.timestamp}ms`
    : 'CLONED'
  console.log(
    `\u2193 reflex \u2193 ${target} ${duration} %cERROR: ${event.detail.body}`,
    'color: #f00;',
    { reflexId, payload }
  )
}

export default { request, success, error }
