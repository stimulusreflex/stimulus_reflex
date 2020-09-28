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

function success (event, options = { halted: false }) {
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
    `\u2193 reflex \u2193 ${target} \u2192 ${selector}${progress} in ${duration}`,
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
  const { selector } = detail || {}
  const { reflexId, target, error, morph } = detail.stimulusReflex || {}
  const duration = `${new Date() - logs[reflexId]}ms`
  console.error(
    `\u2193 reflex \u2193 ${target} \u2192 ${selector} in ${duration}`,
    {
      reflexId,
      error,
      morph,
      payload: event.detail.stimulusReflex
    }
  )
  if (detail.stimulusReflex.serverMessage.body)
    console.error(
      `\u2193 reflex \u2193 ${target}`,
      detail.stimulusReflex.serverMessage.body
    )
  delete logs[reflexId]
}

export default {
  logs,
  request,
  success,
  error
}
