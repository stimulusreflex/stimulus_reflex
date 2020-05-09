import { Controller } from 'stimulus'
import CableReady from 'cable_ready'
import { defaultSchema } from './schema'
import { getConsumer } from './consumer'
import { dispatchLifecycleEvent } from './lifecycle'
import { allReflexControllers } from './controllers'
import { uuidv4 } from './utils'
import Log from './log'
import {
  attributeValue,
  attributeValues,
  extractElementAttributes,
  findElement
} from './attributes'

// A reference to the Stimulus application registered with: StimulusReflex.initialize
//
let stimulusApplication

// A reference to the ActionCable consumer registered with: StimulusReflex.initialize or getConsumer
//
let actionCableConsumer

// A dictionary of promise data
//
const promises = {}

// Indicates if we should log calls to stimulate, etc...
//
let debugging = false

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
        if (data.operations.morph && data.operations.morph.length) {
          const urls = Array.from(
            new Set(data.operations.morph.map(m => m.stimulusReflex.url))
          )
          if (urls.length !== 1 || urls[0] !== location.href) return
        }
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
    // Indicates if the ActionCable web socket connection is open.
    // The connection must be open before calling stimulate.
    //
    isActionCableConnectionOpen () {
      return this.StimulusReflex.subscription.consumer.connection.isOpen()
    },

    // Invokes a server side reflex method.
    //
    // - target - the reflex target (full name of the server side reflex) i.e. 'ReflexClassName#method'
    // - element - [optional] the element that triggered the reflex, defaults to this.element
    // - *args - remaining arguments are forwarded to the server side reflex method
    //
    stimulate () {
      const url = location.href
      const args = Array.from(arguments)
      const target = args.shift() || 'StimulusReflex::Reflex#default_reflex'
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
      const reflexId = uuidv4()
      const data = {
        target,
        args,
        url,
        attrs,
        selectors,
        permanent_attribute_name:
          stimulusApplication.schema.reflexPermanentAttribute,
        reflexId: reflexId
      }
      const { subscription } = this.StimulusReflex
      const { connection } = subscription.consumer

      if (!this.isActionCableConnectionOpen())
        throw 'The ActionCable connection is not open! `this.isActionCableConnectionOpen()` must return true before calling `this.stimulate()`'

      // lifecycle setup
      element.reflexController = this
      element.reflexData = data

      dispatchLifecycleEvent('before', element)

      subscription.send(data)

      if (debugging) {
        Log.request(
          reflexId,
          target,
          args,
          this.context.scope.identifier,
          element
        )
      }

      const promise = new Promise((resolve, reject) => {
        promises[reflexId] = {
          resolve,
          reject,
          data,
          events: {}
        }
      })
      if (debugging) promise.catch(() => {}) // noop default catch
      return promise
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
  createSubscription(controller)
  extendStimulusController(controller)
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
const initialize = (application, initializeOptions = {}) => {
  const { controller, consumer, debug } = initializeOptions
  actionCableConsumer = consumer
  stimulusApplication = application
  stimulusApplication.schema = { ...defaultSchema, ...application.schema }
  stimulusApplication.register(
    'stimulus-reflex',
    controller || StimulusReflexController
  )
  debugging = !!debug
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
  document.addEventListener('ajax:complete', () =>
    setTimeout(setupDeclarativeReflexes, 1)
  )
  // Trigger success and after lifecycle methods from before-morph to ensure we can find a reference
  // to the source element in case it gets removed from the DOM via morph.
  // This is safe because the server side reflex completed successfully.
  document.addEventListener('cable-ready:before-morph', event => {
    const { selector, stimulusReflex } = event.detail || {}
    if (!stimulusReflex) return
    const { reflexId, attrs, last } = stimulusReflex
    const element = findElement(attrs)
    const promise = promises[reflexId]

    if (promise) promise.events[selector] = event

    if (!last) return

    const response = {
      element,
      event,
      data: promise && promise.data,
      events: promise && promise.events
    }

    if (promise) {
      delete promises[reflexId]
      promise.resolve(response)
    }

    dispatchLifecycleEvent('success', element)
    if (debugging) Log.success(response)
  })
  document.addEventListener('stimulus-reflex:500', event => {
    const { reflexId, attrs, error } = event.detail.stimulusReflex || {}
    const element = findElement(attrs)
    const promise = promises[reflexId]

    if (element) element.reflexError = error

    const response = {
      data: promise && promise.data,
      element,
      event,
      toString: () => error
    }

    if (promise) {
      delete promises[reflexId]
      promise.reject(response)
    }

    dispatchLifecycleEvent('error', element)
    if (debugging) Log.error(response)
  })
}

export default {
  initialize,
  register,
  setupDeclarativeReflexes,
  get debug () {
    return debugging
  },
  set debug (value) {
    debugging = !!value
  }
}
