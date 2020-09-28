const logs = {}

function request (reflexId, target, args, controller, element) {
  logs[reflexId] = new Date()
  console.log(`\u2191 stimulus \u2191 ${target}`, {
    reflexId,
    args,
    controller,
    element
  })
}

function success (event, options) {
  const { detail } = event || {}
  const { selector } = detail || {}
  const { reflexId, target, morph } = event.detail.stimulusReflex || {}
  const progress =
    options.completed && options.total > 1
      ? ` ${options.completed}/${options.total}`
      : ''
  const duration = `${new Date() - logs[reflexId]}ms`
  const operation = event.type
    .split(':')[1]
    .split('-')
    .slice(1)
    .join('_')
  console.log(
    `\u2193 reflex \u2193 ${target} \u2192 ${selector ||
      '\u221E'}${progress} in ${duration}`,
    {
      reflexId,
      morph,
      operation,
      halted: options.halted
    }
  )
}

function error (event) {
  const { detail } = event || {}
  const { reflexId, target } = detail.stimulusReflex || {}
  const duration = `${new Date() - logs[reflexId]}ms`
  console.log(
    `\u2193 reflex \u2193 ${target} in ${duration} %cERROR: ${detail.stimulusReflex.serverMessage.body}`,
    'color: #f00;',
    {
      reflexId,
      payload: event.detail.stimulusReflex
    }
  )
}

export default {
  logs,
  request,
  success,
  error
}
