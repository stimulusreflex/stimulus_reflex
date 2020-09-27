const logs = {}

function request (
  reflexId,
  target,
  args,
  stimulusControllerIdentifier,
  element
) {
  logs[reflexId] = new Date()
  console.log(`\u2191 stimulus \u2191 ${target}`, {
    reflexId,
    args,
    stimulusControllerIdentifier,
    element
  })
}

function success (event, options = { halted: false }) {
  const { detail } = event || {}
  const { selector } = detail || {}
  const { reflexId, target, morph } = event.detail.stimulusReflex || {}
  const progress = options.completed
    ? ` ${options.completed}/${options.total}`
    : ''

  console.log(`\u2193 reflex \u2193 ${target}${progress}`, {
    reflexId,
    duration: `${new Date() - logs[reflexId]}ms`,
    halted: options.halted,
    morph,
    selector
  })
}

function error (event) {
  const { detail } = event || {}
  const { selector } = detail || {}
  const { reflexId, target, error, morph } = detail.stimulusReflex || {}
  console.error(`\u2193 reflex \u2193 ${target}`, {
    reflexId,
    duration: `${new Date() - logs[reflexId]}ms`,
    error,
    morph,
    payload: event.detail.stimulusReflex,
    selector
  })
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
