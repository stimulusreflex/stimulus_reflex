import ActionCable from 'actioncable'
import CableReady from 'cable_ready'

const app = window.App || {}
app.StimulusReflex = app.StimulusReflex || {}
app.StimulusReflex.consumer =
  app.StimulusReflex.consumer || ActionCable.createConsumer()
app.StimulusReflex.subscriptions = app.StimulusReflex.subscriptions || {}

const createSubscription = controller => {
  const { channel, room } = controller.StimulusReflex
  const id = `${channel}${room}`
  const renderDelay = controller.StimulusReflex.renderDelay || 25
  const subscription =
    app.StimulusReflex.subscriptions[id] ||
    app.StimulusReflex.consumer.subscriptions.create(
      { channel, room },
      {
        received: data => {
          if (data.cableReady) {
            clearTimeout(controller.StimulusReflex.timeout)
            controller.StimulusReflex.timeout = setTimeout(() => {
              CableReady.perform(data.operations)
            }, renderDelay)
          }
        }
      }
    )

  app.StimulusReflex.subscriptions[id] = subscription
  controller.StimulusReflex.subscription = subscription
}

const extend = controller => {
  Object.assign(controller, {
    stimulate () {
      clearTimeout(controller.StimulusReflex.timeout)
      const args = Array.prototype.slice.call(arguments)
      const target = args.shift()
      const url = location.href
      controller.StimulusReflex.subscription.send({ target, args, url })
    },
    reflex (el) {
      clearTimeout(controller.StimulusReflex.timeout)
      const name = el.target.dataset.reflex.split('#')
      const target = `${name[0].charAt(0).toUpperCase() +
        name[0].slice(1)}Reflex#${name[1]}`
      let args = []
      for (const arg in el.target.dataset) {
        if (/^reflexArg/.test(arg)) args.push(el.target.dataset[arg])
      }
      const url = location.href
      controller.StimulusReflex.subscription.send({ target, args, url })
    },
    wire () {
      document
        .querySelectorAll('[data-reflex]')
        .forEach(el => el.addEventListener('click', controller.reflex))
    },
    unwire () {
      document
        .querySelectorAll('[data-reflex]')
        .forEach(el => el.removeEventListener('click', controller.reflex))
    }
  })

  document.addEventListener('cable-ready:before-morph', controller.unwire)
  document.addEventListener('cable-ready:after-morph', controller.wire)

  controller.wire()
}

export default {
  //
  // Registers a Stimulus controller and extends it with StimulusReflex behavior
  // The room can be specified via a data attribute on the Stimulus controller element i.e. data-room="12345"
  //
  // controller - the Stimulus controller
  // options - optional configuration
  //   * renderDelay - amount of time to delay before mutating the DOM (adds latency but reduces jitter)
  //
  register: (controller, options = {}) => {
    const channel = 'StimulusReflex::Channel'
    const room = controller.element.dataset.room || ''
    controller.StimulusReflex = { ...options, channel, room }
    createSubscription(controller)
    extend(controller)
  }
}
