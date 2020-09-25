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

function success (response, options = { halted: false }) {
  const { event } = response
  const { detail } = event || {}
  const { selector } = detail || {}
  const { reflexId, target, broadcaster } = event.detail.stimulusReflex || {}

  console.log(`\u2193 reflex \u2193 ${target}`, {
    reflexId,
    duration: `${new Date() - logs[reflexId]}ms`,
    halted: options.halted,
    broadcaster,
    selector
  })
}

function error (response) {
  const { event } = response || {}
  const { detail } = event || {}
  const { selector } = detail || {}
  const { reflexId, target, error, broadcaster } = detail.stimulusReflex || {}
  console.error(`\u2193 reflex \u2193 ${target}`, {
    reflexId,
    duration: `${new Date() - logs[reflexId]}ms`,
    error,
    broadcaster,
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
