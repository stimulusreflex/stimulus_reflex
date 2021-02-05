import { Controller } from 'stimulus'
import { defaultSchema } from './schema'
import { getConsumer } from './consumer'
import { dispatchLifecycleEvent } from './lifecycle'
import { allReflexControllers } from './controllers'
import { uuidv4, debounce, emitEvent, serializeForm } from './utils'
import { extractReflexName, elementToXPath } from './utils'
import { performOperations, registerReflex } from './reflexes'
import { beforeDOMUpdate, afterDOMUpdate, serverMessage } from './callbacks'
import {
  attributeValue,
  attributeValues,
  extractElementAttributes,
  extractElementDataset
} from './attributes'
import Log from './log'
import Debug from './debug'
import stimulus from './stimulus'
import isolationMode from './isolation_mode'
import actionCable from './transports/action_cable'

// Subscribes a StimulusReflex controller to an ActionCable channel.
// controller - the StimulusReflex controller to subscribe
//
const createSubscription = controller => {
  actionCable.consumer = actionCable.consumer || getConsumer()
  const { channel } = controller.StimulusReflex
  const subscription = { channel, ...actionCable.params }
  const identifier = JSON.stringify(subscription)

  controller.StimulusReflex.subscription =
    actionCable.consumer.subscriptions.findAll(identifier)[0] ||
    actionCable.consumer.subscriptions.create(subscription, {
      received: performOperations,
      connected: actionCable.connected,
      rejected: actionCable.rejected,
      disconnected: actionCable.disconnected
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
    // - controllerElement - [optional] the element that triggered the reflex, defaults to this.element
    // - options - [optional] an object that contains at least one of attrs, reflexId, selectors, resolveLate, serializeForm
    // - *args - remaining arguments are forwarded to the server side reflex method
    //
    stimulate () {
      const url = location.href
      const args = Array.from(arguments)
      const target = args.shift() || 'StimulusReflex::Reflex#default_reflex'
      const controllerElement = this.element
      const reflexElement =
        args[0] && args[0].nodeType === Node.ELEMENT_NODE
          ? args.shift()
          : controllerElement
      if (
        reflexElement.type === 'number' &&
        reflexElement.validity &&
        reflexElement.validity.badInput
      ) {
        if (Debug.enabled) console.warn('Reflex aborted: invalid numeric input')
        return
      }
      const options = {}
      if (
        args[0] &&
        typeof args[0] === 'object' &&
        Object.keys(args[0]).filter(key =>
          [
            'attrs',
            'selectors',
            'reflexId',
            'resolveLate',
            'serializeForm'
          ].includes(key)
        ).length
      ) {
        const opts = args.shift()
        Object.keys(opts).forEach(o => (options[o] = opts[o]))
      }
      const attrs = options['attrs'] || extractElementAttributes(reflexElement)
      const reflexId = options['reflexId'] || uuidv4()
      let selectors = options['selectors'] || getReflexRoots(reflexElement)
      if (typeof selectors === 'string') selectors = [selectors]
      const resolveLate = options['resolveLate'] || false
      const datasetAttribute = stimulus.app.schema.reflexDatasetAttribute
      const dataset = extractElementDataset(reflexElement, datasetAttribute)
      const xpathController = elementToXPath(controllerElement)
      const xpathElement = elementToXPath(reflexElement)
      const data = {
        target,
        args,
        url,
        attrs,
        dataset,
        selectors,
        reflexId,
        resolveLate,
        xpathController,
        xpathElement,
        reflexController: this.identifier,
        permanentAttributeName: stimulus.app.schema.reflexPermanentAttribute
      }
      const { subscription } = this.StimulusReflex

      if (!this.isActionCableConnectionOpen())
        throw 'The ActionCable connection is not open! `this.isActionCableConnectionOpen()` must return true before calling `this.stimulate()`'

      if (!actionCable.subscriptionActive)
        throw 'The ActionCable channel subscription for StimulusReflex was rejected.'

      // lifecycle setup
      controllerElement.reflexController =
        controllerElement.reflexController || {}
      controllerElement.reflexData = controllerElement.reflexData || {}
      controllerElement.reflexError = controllerElement.reflexError || {}

      controllerElement.reflexController[reflexId] = this
      controllerElement.reflexData[reflexId] = data

      dispatchLifecycleEvent(
        'before',
        reflexElement,
        controllerElement,
        reflexId
      )

      setTimeout(() => {
        const { params } = controllerElement.reflexData[reflexId] || {}
        const formData =
          options['serializeForm'] === false
            ? ''
            : serializeForm(reflexElement.closest('form'), {
                element: reflexElement
              })

        controllerElement.reflexData[reflexId] = {
          ...data,
          params,
          formData
        }

        subscription.send(controllerElement.reflexData[reflexId])
      })

      const promise = registerReflex(data)

      if (Debug.enabled) {
        Log.request(
          reflexId,
          target,
          args,
          this.context.scope.identifier,
          reflexElement,
          controllerElement
        )
      }

      return promise
    },

    // Wraps the call to stimulate for any data-reflex elements.
    // This is internal and should not be invoked directly.
    __perform (event) {
      let element = event.target
      let reflex

      while (element && !reflex) {
        reflex = element.getAttribute(stimulus.app.schema.reflexAttribute)
        if (!reflex || !reflex.trim().length) element = element.parentElement
      }

      const match = attributeValues(reflex).find(
        reflex => reflex.split('->')[0] === event.type
      )

      if (match) {
        event.preventDefault()
        event.stopPropagation()
        this.stimulate(match.split('->')[1], element)
      }
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
// Any elements that define data-reflex will automatically be wired up with the default StimulusReflexController.
//
const setupDeclarativeReflexes = debounce(() => {
  document
    .querySelectorAll(`[${stimulus.app.schema.reflexAttribute}]`)
    .forEach(element => {
      const controllers = attributeValues(
        element.getAttribute(stimulus.app.schema.controllerAttribute)
      )
      const reflexAttributeNames = attributeValues(
        element.getAttribute(stimulus.app.schema.reflexAttribute)
      )
      const actions = attributeValues(
        element.getAttribute(stimulus.app.schema.actionAttribute)
      )
      reflexAttributeNames.forEach(reflexName => {
        const controller = findControllerByReflexName(
          reflexName,
          allReflexControllers(stimulus.app, element)
        )
        let action
        if (controller) {
          action = `${reflexName.split('->')[0]}->${
            controller.identifier
          }#__perform`
          if (!actions.includes(action)) actions.push(action)
        } else {
          action = `${reflexName.split('->')[0]}->stimulus-reflex#__perform`
          if (!controllers.includes('stimulus-reflex')) {
            controllers.push('stimulus-reflex')
          }
          if (!actions.includes(action)) actions.push(action)
        }
      })
      const controllerValue = attributeValue(controllers)
      const actionValue = attributeValue(actions)
      if (
        controllerValue &&
        element.getAttribute(stimulus.app.schema.controllerAttribute) !=
          controllerValue
      ) {
        element.setAttribute(
          stimulus.app.schema.controllerAttribute,
          controllerValue
        )
      }
      if (
        actionValue &&
        element.getAttribute(stimulus.app.schema.actionAttribute) != actionValue
      )
        element.setAttribute(stimulus.app.schema.actionAttribute, actionValue)
    })
  emitEvent('stimulus-reflex:ready')
}, 20)

// Given a reflex string such as 'click->TestReflex#create' and a list of
// controllers. It will find the matching controller based on the controller's
// identifier. e.g. Given these controller identifiers ['foo', 'bar', 'test'],
// it would select the 'test' controller.
const findControllerByReflexName = (reflexName, controllers) => {
  const controller = controllers.find(controller => {
    if (!controller.identifier) return

    return (
      extractReflexName(reflexName).toLowerCase() ===
      controller.identifier.toLowerCase()
    )
  })

  return controller || controllers[0]
}

// compute the DOM element(s) which will be the morph root
// use the data-reflex-root attribute on the reflex or the controller
// optional value is a CSS selector(s); comma-separated list
// order of preference is data-reflex, data-controller, document body (default)
const getReflexRoots = element => {
  let list = []
  while (list.length === 0 && element) {
    const reflexRoot = element.getAttribute(
      stimulus.app.schema.reflexRootAttribute
    )
    if (reflexRoot) {
      if (reflexRoot.length === 0 && element.id) reflexRoot = `#${element.id}`
      const selectors = reflexRoot.split(',').filter(s => s.trim().length)
      if (selectors.length === 0) {
        console.error(
          `No value found for ${stimulus.app.schema.reflexRootAttribute}. Add an #id to the element or provide a value for ${application.schema.reflexRootAttribute}.`,
          element
        )
      }
      list = list.concat(selectors.filter(s => document.querySelector(s)))
    }
    element = element.parentElement
      ? element.parentElement.closest(
          `[${stimulus.app.schema.reflexRootAttribute}]`
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
//   * debug - [false] log all Reflexes to the console
//   * params - [{}] key/value parameters to send during channel subscription
//   * isolate - [false] restrict Reflex playback to the tab which initiated it
//
const initialize = (application, initializeOptions = {}) => {
  const { controller, consumer, debug, params, isolate } = initializeOptions
  actionCable.consumer = consumer
  actionCable.params = params
  isolationMode.set(!!isolate)
  stimulus.app = application
  stimulus.app.schema = { ...defaultSchema, ...application.schema }
  stimulus.app.register(
    'stimulus-reflex',
    controller || StimulusReflexController
  )
  Debug.set(!!debug)
  const observer = new MutationObserver(setupDeclarativeReflexes)
  observer.observe(document.documentElement, {
    attributeFilter: [stimulus.app.schema.reflexAttribute],
    childList: true,
    subtree: true
  })
}

document.addEventListener('stimulus-reflex:server-message', serverMessage)
document.addEventListener('cable-ready:before-inner-html', beforeDOMUpdate)
document.addEventListener('cable-ready:before-morph', beforeDOMUpdate)
document.addEventListener('cable-ready:after-inner-html', afterDOMUpdate)
document.addEventListener('cable-ready:after-morph', afterDOMUpdate)
window.addEventListener('load', setupDeclarativeReflexes)

export default {
  initialize,
  register,
  get debug () {
    return Debug.value
  },
  set debug (value) {
    Debug.set(!!value)
  }
}
