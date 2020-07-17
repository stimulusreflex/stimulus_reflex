import { Controller } from 'stimulus'
import CableReady from 'cable_ready'
import serializeForm from 'form-serialize'
import { defaultSchema } from './schema'
import { getConsumer } from './consumer'
import { dispatchLifecycleEvent } from './lifecycle'
import { allReflexControllers } from './controllers'
import { uuidv4, debounce } from './utils'
import Log from './log'
import {
  attributeValue,
  attributeValues,
  extractElementAttributes,
  extractElementDataset,
  findElement
} from './attributes'
import { extractReflexName } from './utils'

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
          if (data.operations.morph[0].stimulusReflex) {
            const urls = Array.from(
              new Set(data.operations.morph.map(m => m.stimulusReflex.url))
            )
            if (urls.length !== 1 || urls[0] !== location.href) return
          }
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
    // - options - [optional] an object that contains at least one of attrs, reflexId, selectors
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
      const options = {}
      if (
        args[0] &&
        typeof args[0] == 'object' &&
        Object.keys(args[0]).filter(key =>
          ['attrs', 'selectors', 'reflexId'].includes(key)
        )
      ) {
        const opts = args.shift()
        Object.keys(opts).forEach(o => (options[o] = opts[o]))
      }
      const attrs = options['attrs'] || extractElementAttributes(element)
      const reflexId = options['reflexId'] || uuidv4()
      let selectors = options['selectors'] || getReflexRoots(element)
      if (typeof selectors == 'string') selectors = [selectors]
      const datasetAttribute = stimulusApplication.schema.reflexDatasetAttribute
      const dataset = extractElementDataset(element, datasetAttribute)
      const data = {
        target,
        args,
        url,
        attrs,
        dataset,
        selectors,
        reflexId,
        permanent_attribute_name:
          stimulusApplication.schema.reflexPermanentAttribute
      }
      const { subscription } = this.StimulusReflex

      if (!this.isActionCableConnectionOpen())
        throw 'The ActionCable connection is not open! `this.isActionCableConnectionOpen()` must return true before calling `this.stimulate()`'

      // lifecycle setup
      element.reflexController = this
      element.reflexData = data

      dispatchLifecycleEvent('before', element)

      setTimeout(() => {
        const { params } = element.reflexData || {}
        element.reflexData = {
          ...data,
          params: {
            ...params,
            ...serializeForm(element.closest('form'), {
              hash: true,
              empty: true
            })
          }
        }

        subscription.send(element.reflexData)
      })

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
          data
        }
      })
      if (debugging) promise.catch(() => {}) // noop default catch
      return promise
    },

    // Wraps the call to stimulate for any data-reflex elements.
    // This is internal and should not be invoked directly.
    __perform (event) {
      let element = event.target
      let reflex

      while (element && !reflex) {
        reflex = element.getAttribute(
          stimulusApplication.schema.reflexAttribute
        )
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
        const controller = findControllerByReflexString(
          reflex,
          allReflexControllers(stimulusApplication, element)
        )
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
      if (
        controllerValue &&
        element.getAttribute(stimulusApplication.schema.controllerAttribute) !=
          controllerValue
      ) {
        element.setAttribute(
          stimulusApplication.schema.controllerAttribute,
          controllerValue
        )
      }
      if (
        actionValue &&
        element.getAttribute(stimulusApplication.schema.actionAttribute) !=
          actionValue
      )
        element.setAttribute(
          stimulusApplication.schema.actionAttribute,
          actionValue
        )
    })
}, 20)

// Given a reflex string such as 'click->TestReflex#create' and a list of
// controllers. It will find the matching controller based on the controller's
// identifier. e.g. Given these controller identifiers ['foo', 'bar', 'test'],
// it would select the 'test' controller.
const findControllerByReflexString = (reflexString, controllers) => {
  const controller = controllers.find(controller => {
    if (!controller.identifier) return

    return (
      extractReflexName(reflexString).toLowerCase() ===
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

  window.addEventListener('load', () => {
    setupDeclarativeReflexes()
    const observer = new MutationObserver(setupDeclarativeReflexes)
    observer.observe(document.documentElement, {
      attributes: true,
      childList: true,
      subtree: true
    })
  })

  // Trigger success and after lifecycle methods from before events (before-morph, before-inner-html) to ensure we can find a reference
  // to the source element in case it gets removed from the DOM via morph.
  // This is safe because the server side reflex completed successfully.
  const beforeDOMUpdateHandler = event => {
    const { selector, stimulusReflex } = event.detail || {}
    if (!stimulusReflex) return
    const { reflexId, attrs, last } = stimulusReflex
    const element = findElement(attrs)
    const promise = promises[reflexId]

    if (!last) return

    const response = {
      element,
      event,
      morphMode: promise && promise.morphMode,
      data: promise && promise.data
    }

    if (promise) {
      delete promises[reflexId]
      promise.resolve(response)
    }

    dispatchLifecycleEvent('success', element)
    if (debugging) Log.success(response)
  }
  document.addEventListener(
    'cable-ready:before-inner-html',
    beforeDOMUpdateHandler
  )
  document.addEventListener('cable-ready:before-morph', beforeDOMUpdateHandler)
  document.addEventListener('stimulus-reflex:server-message', event => {
    const { reflexId, attrs, serverMessage } = event.detail.stimulusReflex || {}
    const { subject, body } = serverMessage
    const element = findElement(attrs)
    const promise = promises[reflexId]
    const subjects = {
      error: true,
      halted: true,
      nothing: true,
      success: true
    }

    if (element && subject == 'error') element.reflexError = body

    const response = {
      data: promise && promise.data,
      element,
      event,
      toString: () => body
    }

    if (promise) {
      delete promises[reflexId]

      if (subject == 'error') {
        promise.reject(response)
      } else {
        promise.resolve(response)
      }
    }

    if (element && subjects[subject]) dispatchLifecycleEvent(subject, element)

    if (debugging) {
      switch (subject) {
        case 'error':
          Log.error(response)
          break
        case 'selector':
          Log.success(response)
          break
        case 'nothing':
          Log.success(response)
          break
        case 'halted':
          Log.success(response, { halted: true })
          break
        default:
          Log.success(response)
          break
      }
    }
  })
}

export default {
  initialize,
  register,
  get debug () {
    return debugging
  },
  set debug (value) {
    debugging = !!value
  }
}
