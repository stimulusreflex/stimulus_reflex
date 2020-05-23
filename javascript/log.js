const logs = {}

function request (
  reflexId,
  target,
  args,
  mode,
  stimulusControllerIdentifier,
  element
) {
  logs[reflexId] = new Date()
  console.log(`\u2B9C ${target}`, {
    reflexId,
    args,
    mode,
    stimulusControllerIdentifier,
    element
  })
}

function success (response, options = { halted: false, launched: false }) {
  const html = {}
  const payloads = {}
  const elements = {}
  const { event, events } = response
  const { reflexId, target, last } = event.detail.stimulusReflex || {}

  if (events) {
    Object.keys(events).map(selector => {
      elements[selector] = events[selector].detail.element
      html[selector] = events[selector].detail.html
      payloads[selector] = events[selector].detail.stimulusReflex
    })
  }

  console.log(`\u2B9E ${target}`, {
    reflexId,
    duration: `${new Date() - logs[reflexId]}ms`,
    halted: options.halted,
    launched: options.launched,
    elements,
    payloads,
    html
  })
  if (last) delete logs[reflexId]
}

function error (response) {
  const { event, element } = response || {}
  const { detail } = event || {}
  const { reflexId, target, error } = detail.stimulusReflex || {}
  console.error(`\u2B9E ${target}`, {
    reflexId,
    duration: `${new Date() - logs[reflexId]}ms`,
    error,
    payload: event.detail.stimulusReflex,
    element
  })
  delete logs[reflexId]
}

export default {
  request,
  success,
  error
}
