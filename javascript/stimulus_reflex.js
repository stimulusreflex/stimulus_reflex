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
  const url = location.href
  Object.assign(controller, {
    stimulate () {
      clearTimeout(controller.StimulusReflex.timeout)
      const args = Array.prototype.slice.call(arguments)
      const target = args.shift()
      controller.StimulusReflex.subscription.send({ target, args, url })
    },
    reflex (el) {
      clearTimeout(controller.StimulusReflex.timeout)
      const segments = el.target.dataset.reflex.split('->')
      const name =
        segments.length == 1 ? segments[0].split('#') : segments[1].split('#')
      const target = `${name[0].charAt(0).toUpperCase() +
        name[0].slice(1)}Reflex#${name[1]}`
      let args = []
      for (const arg in el.target.dataset) {
        if (/^reflexValue/.test(arg)) args.push(el.target.value)
        else if (/^reflex.+/.test(arg)) args.push(el.target.dataset[arg])
      }
      controller.StimulusReflex.subscription.send({ target, args, url })
    },
    wire (e) {
      const method =
        e && e.type === 'cable-ready:before-morph'
          ? 'removeEventListener'
          : 'addEventListener'
      const events = {
        a: 'click',
        button: 'click',
        form: 'submit',
        input: 'change',
        select: 'change',
        textarea: 'change'
      }
      document.querySelectorAll('[data-reflex]').forEach(el => {
        const tagName = el.tagName.toLowerCase()
        let event = events[tagName]
        if (/^\w+->\w+#\w+$/.test(el.dataset.reflex)) {
          el[method](el.dataset.reflex.split('->')[0], controller.reflex)
        } else if (event) {
          // https://stimulusjs.org/reference/actions#event-shorthand
          if (tagName === 'input' && el.type === 'submit') event = 'click'
          el[method](event, controller.reflex)
        } else el[method]('click', controller.reflex)
      })
    }
  })

  document.addEventListener('cable-ready:before-morph', controller.wire)
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
