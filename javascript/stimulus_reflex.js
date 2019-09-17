import ActionCable from 'actioncable'
import CableReady from 'cable_ready'
import StimulusReflexController from './stimulus_reflex_controller'

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
      const url = window.location.href
      const args = Array.prototype.slice.call(arguments)
      const target = args.shift()
      const attrs = Array.prototype.slice
        .call(this.element.attributes)
        .reduce((memo, attr) => {
          memo[attr.name] = attr.value
          return memo
        }, {})

      let xpath
      let targetController
      if (controller.identifier === 'stimulus-reflex') {
        const controllerName = target.split('Reflex')[0].toLowerCase()
        targetController = controller.application.getControllerForElementAndIdentifier(
          document.querySelector(`[data-controller~="${controllerName}"]`),
          controllerName
        )
      } else {
        targetController = controller.application.getControllerForElementAndIdentifier(
          document.querySelector(
            `[data-controller~="${controller.identifier}"]`
          ),
          controller.identifier
        )
      }
      xpath = getPathTo(targetController.element)
      xpath = xpath.startsWith('//*') ? xpath : '/html/' + xpath

      attrs.value = this.element.value
      attrs.checked = !!this.element.checked
      attrs.selected = !!this.element.selected
      if (this.element.tagName.match(/select/i)) {
        if (this.element.multiple) {
          const checkedOptions = Array.prototype.slice.call(
            this.element.querySelectorAll('option:checked')
          )
          attrs.values = checkedOptions.map(o => o.value)
        } else if (this.element.selectedIndex > -1) {
          attrs.value = this.element.options[this.element.selectedIndex].value
        }
      }

      controller.StimulusReflex.subscription.send({
        target,
        args,
        attrs,
        url,
        xpath
      })
    }
  })
}

// Sets up implicit declarative reflex behavior
const setup = () => {
  document.querySelectorAll('[data-reflex]').forEach(el => {
    if (String(el.dataset.controller).indexOf('stimulus-reflex') >= 0) return
    const controllers = el.dataset.controller
      ? el.dataset.controller.split(' ')
      : []
    const actions = el.dataset.action ? el.dataset.action.split(' ') : []
    controllers.push('stimulus-reflex')
    el.setAttribute('data-controller', controllers.join(' '))
    el.dataset.reflex.split(' ').forEach(reflex => {
      actions.push(`${reflex.split('->')[0]}->stimulus-reflex#perform`)
    })
    el.setAttribute('data-action', actions.join(' '))
  })
}

// Initializes StimulusReflex by registering the default Stimulus controller
// with the passed Stimulus application
const initialize = (application, controller) => {
  application.register(
    'stimulus-reflex',
    controller || StimulusReflexController
  )
}

// Registers a Stimulus controller and extends it with StimulusReflex behavior
// The room can be specified via a data attribute on the Stimulus controller element i.e. data-room="12345"
//
// controller - the Stimulus controller
// options - optional configuration
//   * renderDelay - amount of time to delay before mutating the DOM (adds latency but reduces jitter)
//   * url - the route from which this controller is rendered. defaults to location.href
//
const register = (controller, options = {}) => {
  const channel = 'StimulusReflex::Channel'
  const room = controller.element.dataset.room || ''
  controller.StimulusReflex = { ...options, channel, room }
  createSubscription(controller)
  extend(controller)
}

// construct a valid xPath for an element in the DOM
const getPathTo = element => {
  if (element.id !== '') return "//*[@id='" + element.id + "']"
  if (element === document.body) return 'body'

  let ix = 0
  const siblings = element.parentNode.childNodes

  for (var i = 0; i < siblings.length; i++) {
    const sibling = siblings[i]
    if (sibling === element) {
      return (
        getPathTo(element.parentNode) +
        '/' +
        element.tagName.toLowerCase() +
        '[' +
        (ix + 1) +
        ']'
      )
    }

    if (sibling.nodeType === 1 && sibling.tagName === element.tagName) {
      ix++
    }
  }
}

StimulusReflexController.register = register

if (!document.stimulusReflexInitialized) {
  document.stimulusReflexInitialized = true
  window.addEventListener('load', setup)
  document.addEventListener('turbolinks:load', setup)
  document.addEventListener('cable-ready:after-morph', setup)
}

export default { initialize, register }
