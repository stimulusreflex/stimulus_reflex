import { Controller } from 'stimulus'
import CableReady from 'cable_ready'
import { defaultSchema } from './schema'
import { getConsumer } from './consumer'
import { dispatchLifecycleEvent } from './lifecycle'
import { allReflexControllers } from './controllers'
import {
  attributeValue,
  attributeValues,
  extractElementAttributes,
  findElement,
  isTextInput
} from './attributes'

// A reference to the Stimulus application registered with: StimulusReflex.initialize
//
let stimulusApplication

// A reference to the ActionCable consumer registered with: StimulusReflex.initialize or getConsumer
//
let actionCableConsumer

// Initializes implicit data-reflex-permanent for text inputs.
//
const initializeImplicitReflexPermanent = event => {
  const element = event.target
  if (!isTextInput(element)) return
  element.reflexPermanent = element.hasAttribute(
    stimulusApplication.schema.reflexPermanentAttribute
  )
  element.setAttribute(stimulusApplication.schema.reflexPermanentAttribute, '')
}

// Resets implicit data-reflex-permanent for text inputs.
//
const resetImplicitReflexPermanent = event => {
  const element = event.target
  if (!isTextInput(element)) return
  if (element.reflexPermanent !== undefined && !element.reflexPermanent) {
    element.removeAttribute(stimulusApplication.schema.reflexPermanentAttribute)
  }
}

// Subscribes a StimulusReflex controller to an ActionCable channel.
//
// controller - the StimulusReflex controller to subscribe
//
const createSubscription = controller => {
  actionCableConsumer = actionCableConsumer || getConsumer()
  const { channel } = controller.StimulusReflex
  const identifier = JSON.stringify({ channel })

  controller.StimulusReflex.subscription =
    actionCableConsumer.subscriptions.findAll(identifier)[0] ||
    actionCableConsumer.subscriptions.create(channel, {
      received: data => {
        if (!data.cableReady) return
        if (!data.operations.morph || !data.operations.morph.length) return
        const urls = [
          ...new Set(data.operations.morph.map(m => m.stimulusReflex.url))
        ]
        if (urls.length !== 1 || urls[0] !== location.href) return
        CableReady.perform(data.operations)
      }
    })
}

// Extends a regular Stimulus controller with StimulusReflex behavior.
//
// Methods added to the Stimulus controller:
// - stimulate
// - __perform
//
const extendStimulusController = controller => {
  Object.assign(controller, {
    // Invokes a server side reflex method.
    //
    // - target - the reflex target (full name of the server side reflex) i.e. 'ReflexClassName#method'
    // - element - [optional] the element that triggered the reflex, defaults to this.element
    // - *args - remaining arguments are forwarded to the server side reflex method
    //
    stimulate () {
      const url = location.href
      const args = Array.from(arguments)
      const target = args.shift()
      const element =
        args[0] && args[0].nodeType === Node.ELEMENT_NODE
          ? args.shift()
          : this.element
      if (
        element.type === 'number' &&
        element.validity &&
        element.validity.badInput
      ) {
        return
      }
      const attrs = extractElementAttributes(element)
      const selectors = getReflexRoots(element)
      const data = {
        target,
        args,
        url,
        attrs,
        selectors,
        permanent_attribute_name:
          stimulusApplication.schema.reflexPermanentAttribute
      }

      // lifecycle setup
      element.reflexController = controller
      element.reflexData = data

      dispatchLifecycleEvent('before', element)
      controller.StimulusReflex.subscription.send(data)
    },

    // Wraps the call to stimulate for any data-reflex elements.
    // This is internal and should not be invoked directly.
    __perform (event) {
      event.preventDefault()
      event.stopPropagation()

      let element = event.target
      let reflex

      while (element && !reflex) {
        reflex = element.getAttribute(
          stimulusApplication.schema.reflexAttribute
        )
        if (!reflex || !reflex.trim().length) element = element.parentElement
      }

      attributeValues(reflex).forEach(reflex =>
        this.stimulate(reflex.split('->')[1], element)
      )
    }
  })
}

// Registers a Stimulus controller and extends it with StimulusReflex behavior
//
// controller - the Stimulus controller
// options - [optional] configuration
//
const register = (controller, options = {}) => {
  const channel = 'StimulusReflex::Channel'
  controller.StimulusReflex = { ...options, channel }
  extendStimulusController(controller)
  createSubscription(controller)
}

// Default StimulusReflexController that is implicitly wired up as data-controller for any DOM elements
// that have configured data-reflex. Note that this default can be overridden when initializing the application.
// i.e. StimulusReflex.initialize(myStimulusApplication, MyCustomDefaultController);
//
class StimulusReflexController extends Controller {
  constructor (...args) {
    super(...args)
    register(this)
  }
}

// Sets up declarative reflex behavior.
// Any elements that define data-reflex will automatcially be wired up with the default StimulusReflexController.
//
const setupDeclarativeReflexes = () => {
  document
    .querySelectorAll(`[${stimulusApplication.schema.reflexAttribute}]`)
    .forEach(element => {
      const controllers = attributeValues(
        element.getAttribute(stimulusApplication.schema.controllerAttribute)
      )
      const reflexes = attributeValues(
        element.getAttribute(stimulusApplication.schema.reflexAttribute)
      )
      const actions = attributeValues(
        element.getAttribute(stimulusApplication.schema.actionAttribute)
      )
      reflexes.forEach(reflex => {
        const controller = allReflexControllers(stimulusApplication, element)[0]
        let action
        if (controller) {
          action = `${reflex.split('->')[0]}->${
            controller.identifier
          }#__perform`
          if (!actions.includes(action)) actions.push(action)
        } else {
          action = `${reflex.split('->')[0]}->stimulus-reflex#__perform`
          if (!controllers.includes('stimulus-reflex')) {
            controllers.push('stimulus-reflex')
          }
          if (!actions.includes(action)) actions.push(action)
        }
      })
      const controllerValue = attributeValue(controllers)
      const actionValue = attributeValue(actions)
      if (controllerValue) {
        element.setAttribute(
          stimulusApplication.schema.controllerAttribute,
          controllerValue
        )
      }
      if (actionValue)
        element.setAttribute(
          stimulusApplication.schema.actionAttribute,
          actionValue
        )
    })
}

// compute the DOM element(s) which will be the morph root
// use the data-reflex-root attribute on the reflex or the controller
// optional value is a CSS selector(s); comma-separated list
// order of preference is data-reflex, data-controller, document body (default)
const getReflexRoots = element => {
  let list = []
  while (list.length === 0 && element) {
    const reflexRoot = element.getAttribute(
      stimulusApplication.schema.reflexRootAttribute
    )
    if (reflexRoot) {
      if (reflexRoot.length === 0 && element.id) reflexRoot = `#${element.id}`
      const selectors = reflexRoot.split(',').filter(s => s.trim().length)
      if (selectors.length === 0) {
        console.error(
          `No value found for ${stimulusApplication.schema.reflexRootAttribute}. Add an #id to the element or provide a value for ${stimulusApplication.schema.reflexRootAttribute}.`,
          element
        )
      }
      list = list.concat(selectors.filter(s => document.querySelector(s)))
    }
    element = element.parentElement
      ? element.parentElement.closest(
          `[${stimulusApplication.schema.reflexRootAttribute}]`
        )
      : null
  }
  return list
}

// Initializes StimulusReflex by registering the default Stimulus controller with the passed Stimulus application.
//
// - application - the Stimulus application
// - options
//   * controller - [optional] the default StimulusReflexController
//   * consumer - [optional] the ActionCable consumer
//
const initialize = (application, options = {}) => {
  const { controller, consumer } = options
  actionCableConsumer = consumer
  stimulusApplication = application
  stimulusApplication.schema = { ...defaultSchema, ...application.schema }
  stimulusApplication.register(
    'stimulus-reflex',
    controller || StimulusReflexController
  )
}

if (!document.stimulusReflexInitialized) {
  document.stimulusReflexInitialized = true
  window.addEventListener('load', () => setTimeout(setupDeclarativeReflexes, 1))
  document.addEventListener('turbolinks:load', () =>
    setTimeout(setupDeclarativeReflexes, 1)
  )
  document.addEventListener('cable-ready:after-morph', () =>
    setTimeout(setupDeclarativeReflexes, 1)
  )
  // Trigger success and after lifecycle methods from before-morph to ensure we can find a reference
  // to the source element in case it gets removed from the DOM via morph.
  // This is safe because the server side reflex completed successfully.
  document.addEventListener('cable-ready:before-morph', event => {
    const { target, attrs, last } = event.detail.stimulusReflex || {}
    if (!last) return
    const element = findElement(attrs)
    dispatchLifecycleEvent('success', element)
  })
  document.addEventListener('stimulus-reflex:500', event => {
    const { target, attrs, error } = event.detail.stimulusReflex || {}
    const element = findElement(attrs)
    element.reflexError = error
    dispatchLifecycleEvent('error', element)
  })
  document.addEventListener('focusin', initializeImplicitReflexPermanent)
  document.addEventListener('focusout', resetImplicitReflexPermanent)
}

export default { initialize, register }
