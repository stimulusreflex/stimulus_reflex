import { Controller } from '@hotwired/stimulus'

import Stimulus from './app'
import Schema from './schema'
import Log from './log'
import Debug from './debug'
import Deprecate from './deprecate'
import Reflex from './reflex'
import ReflexData from './reflex_data'
import IsolationMode from './isolation_mode'
import Transport from './transport'
import ActionCableTransport from './transports/action_cable'

import { dispatchLifecycleEvent } from './lifecycle'
import { beforeDOMUpdate, afterDOMUpdate, routeReflexEvent } from './callbacks'
import { reflexes } from './reflex_store'
import { attributeValues } from './attributes'
import { uuidv4, serializeForm, elementInvalid } from './utils'
import { scanForReflexes, getReflexElement, getReflexOptions } from './reflexes'

// Default StimulusReflexController that is implicitly wired up as data-controller for any DOM elements
// that have configured data-reflex. Note that this default can be overridden when initializing the application.
// i.e. StimulusReflex.initialize(myStimulusApplication, MyCustomDefaultController)
//
class StimulusReflexController extends Controller {
  constructor (...args) {
    super(...args)
    register(this)
  }
}

// Uniquely identify this browser tab in each Reflex
const tabId = uuidv4()

// Initializes StimulusReflex by registering the default Stimulus controller with the passed Stimulus application.
//
// - application  - the Stimulus application
// - options
//   * controller - [optional] the default StimulusReflexController
//   * consumer   - [optional] the ActionCable consumer
//   * debug      - [false] log all Reflexes to the console
//   * params     - [{}] key/value parameters to send during channel subscription
//   * isolate    - [false] restrict Reflex playback to the tab which initiated it
//   * deprecate  - [true] show warnings regarding upcoming changes to the library
//
const initialize = (
  application,
  { controller, consumer, debug, params, isolate, deprecate, transport } = {}
) => {
  Transport.set(transport || ActionCableTransport)
  Transport.plugin.initialize(consumer, params)
  IsolationMode.set(!!isolate)
  Stimulus.set(application)
  Schema.set(application)
  Stimulus.app.register(
    'stimulus-reflex',
    controller || StimulusReflexController
  )
  Debug.set(!!debug)
  if (typeof deprecate !== 'undefined') Deprecate.set(deprecate)
  const observer = new MutationObserver(scanForReflexes)
  observer.observe(document.documentElement, {
    attributeFilter: [Schema.reflex, Schema.action],
    childList: true,
    subtree: true
  })
  return reflexes
}

// Registers a Stimulus controller and extends it with StimulusReflex behavior
//
// controller - the Stimulus controller
// options - [optional] configuration
//
const register = (controller, options = {}) => {
  const channel = 'StimulusReflex::Channel'
  controller.StimulusReflex = { ...options, channel }
  Transport.plugin.subscribe(controller)
  Object.assign(controller, {
    // Invokes a server side reflex method.
    //
    // - target - the reflex target (full name of the server side reflex) i.e. 'ReflexClassName#method'
    // - reflexElement - [optional] the element that triggered the reflex, defaults to this.element
    // - options - [optional] an object that contains at least one of attrs, reflexId, selectors, resolveLate, serializeForm
    // - *args - remaining arguments are forwarded to the server side reflex method
    //
    stimulate () {
      const url = location.href
      const controllerElement = this.element
      const args = Array.from(arguments)
      const target = args.shift() || 'StimulusReflex::Reflex#default_reflex'
      const reflexElement = getReflexElement(args, controllerElement)

      if (elementInvalid(reflexElement)) {
        if (Debug.enabled) console.warn('Reflex aborted: invalid numeric input')
        return
      }

      const options = getReflexOptions(args)

      const reflexData = new ReflexData(
        options,
        reflexElement,
        controllerElement,
        this.identifier,
        Schema.reflexPermanent,
        target,
        args,
        url,
        tabId
      )

      const reflexId = reflexData.reflexId

      // TODO: remove this in v4
      controllerElement.reflexController =
        controllerElement.reflexController || {}
      controllerElement.reflexData = controllerElement.reflexData || {}
      controllerElement.reflexError = controllerElement.reflexError || {}

      controllerElement.reflexController[reflexId] = this
      controllerElement.reflexData[reflexId] = reflexData.valueOf()
      // END TODO: remove

      const reflex = new Reflex(reflexData, this)
      reflexes[reflexId] = reflex
      this.lastReflex = reflex

      dispatchLifecycleEvent(reflex, 'before')

      setTimeout(() => {
        // TODO: in v4, params will be set on the reflex.data object
        const { params } = controllerElement.reflexData[reflexId] || {}

        const check = reflexElement.attributes[Schema.reflexSerializeForm]
        if (check) {
          options['serializeForm'] = check.value !== 'false'
        }

        const form =
          reflexElement.closest(reflexData.formSelector) ||
          document.querySelector(reflexData.formSelector) ||
          reflexElement.closest('form')

        // TODO: remove this in v4
        if (Deprecate.enabled && options['serializeForm'] === undefined && form)
          console.warn(
            `Deprecation warning: the next version of StimulusReflex will not serialize forms by default.\nPlease set ${Schema.reflexSerializeForm}=\"true\" on your Reflex Controller Element or pass { serializeForm: true } as an option to stimulate.`
          )
        // END TODO: remove

        const formData =
          options['serializeForm'] === false
            ? ''
            : serializeForm(form, {
                element: reflexElement
              })

        reflex.data = {
          ...reflexData.valueOf(),
          params,
          formData
        }

        // TODO: remove this in v4
        controllerElement.reflexData[reflexId] = reflex.data
        // END TODO: remove

        Transport.plugin.deliver(reflex)
      })

      Log.request(reflex)

      return reflex.getPromise
    },

    // Wraps the call to stimulate for any data-reflex elements.
    // This is internal and should not be invoked directly.
    __perform (event) {
      let element = event.target
      let reflex

      while (element && !reflex) {
        reflex = element.getAttribute(Schema.reflex)
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

  // Access the reflexes created by the current controller instance
  // reflexes is a Proxy to an object, keyed by reflexId
  // this.reflexes.all and this.reflexes.last are scoped to this controller instance
  // Reflexes can also be scoped by stage eg. this.reflexes.queued
  if (!controller.reflexes)
    Object.defineProperty(controller, 'reflexes', {
      get () {
        return new Proxy(reflexes, {
          get: function (target, prop) {
            if (prop === 'last') return this.lastReflex
            return Object.fromEntries(
              Object.entries(target[prop]).filter(
                ([_, reflex]) => reflex.controller === this
              )
            )
          }.bind(this)
        })
      }
    })
}

const useReflex = (controller, options = {}) => {
  register(controller, options)
}

document.addEventListener('cable-ready:after-dispatch-event', routeReflexEvent)
document.addEventListener('cable-ready:before-inner-html', beforeDOMUpdate)
document.addEventListener('cable-ready:before-morph', beforeDOMUpdate)
document.addEventListener('cable-ready:after-inner-html', afterDOMUpdate)
document.addEventListener('cable-ready:after-morph', afterDOMUpdate)
window.addEventListener('load', scanForReflexes)

export { initialize, register, useReflex }
