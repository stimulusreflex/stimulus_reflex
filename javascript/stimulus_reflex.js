import { Controller } from '@hotwired/stimulus'

import Schema from './schema'
import Log from './log'
import Debug from './debug'
import Deprecate from './deprecate'
import ReflexData from './reflex_data'
import IsolationMode from './isolation_mode'
import ActionCableTransport from './transports/action_cable'

import { dispatchLifecycleEvent } from './lifecycle'
import { uuidv4, serializeForm } from './utils'
import { beforeDOMUpdate, afterDOMUpdate, routeReflexEvent } from './callbacks'
import { registerReflex, setupDeclarativeReflexes } from './reflexes'
import { reflexes } from './reflex_store'
import { attributeValues } from './attributes'

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
  { controller, consumer, debug, params, isolate, deprecate } = {}
) => {
  ActionCableTransport.initialize(consumer, params)
  document.addEventListener(
    'DOMContentLoaded',
    () => {
      if (Deprecate.enabled && IsolationMode.disabled)
        console.warn(
          'Deprecation warning: the next version of StimulusReflex will standardize isolation mode, and the isolate option will be removed.\nPlease update your applications to assume that every tab will be isolated.'
        )
    },
    { once: true }
  )
  IsolationMode.set(!!isolate)
  reflexes.app = application
  Schema.set(application)
  reflexes.app.register(
    'stimulus-reflex',
    controller || StimulusReflexController
  )
  Debug.set(!!debug)
  if (typeof deprecate !== 'undefined') Deprecate.set(deprecate)
  const observer = new MutationObserver(setupDeclarativeReflexes)
  observer.observe(document.documentElement, {
    attributeFilter: [Schema.reflex, Schema.action],
    childList: true,
    subtree: true
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
  ActionCableTransport.subscribe(controller)
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
            'serializeForm',
            'suppressLogging',
            'includeInnerHTML',
            'includeTextContent'
          ].includes(key)
        ).length
      ) {
        const opts = args.shift()
        Object.keys(opts).forEach(o => (options[o] = opts[o]))
      }

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

      // lifecycle setup
      controllerElement.reflexController =
        controllerElement.reflexController || {}
      controllerElement.reflexData = controllerElement.reflexData || {}
      controllerElement.reflexError = controllerElement.reflexError || {}

      controllerElement.reflexController[reflexId] = this
      controllerElement.reflexData[reflexId] = reflexData.valueOf()

      dispatchLifecycleEvent(
        'before',
        reflexElement,
        controllerElement,
        reflexId
      )

      setTimeout(() => {
        const { params } = controllerElement.reflexData[reflexId] || {}
        const check = reflexElement.attributes[Schema.reflexSerializeForm]
        if (check) {
          // not needed after v4 because this is only here for the deprecation warning
          options['serializeForm'] = check.value !== 'false'
        }

        const form =
          reflexElement.closest(reflexData.formSelector) ||
          document.querySelector(reflexData.formSelector) ||
          reflexElement.closest('form')

        if (Deprecate.enabled && options['serializeForm'] === undefined && form)
          console.warn(
            `Deprecation warning: the next version of StimulusReflex will not serialize forms by default.\nPlease set ${Schema.reflexSerializeForm}=\"true\" on your Reflex Controller Element or pass { serializeForm: true } as an option to stimulate.`
          )
        const formData =
          options['serializeForm'] === false
            ? ''
            : serializeForm(form, {
                element: reflexElement
              })

        controllerElement.reflexData[reflexId] = {
          ...reflexData.valueOf(),
          params,
          formData
        }

        ActionCableTransport.enqueueReflex(controllerElement, reflexId)
      })

      const promise = registerReflex(reflexData.valueOf())

      Log.request(
        reflexId,
        target,
        args,
        this.context.scope.identifier,
        reflexElement,
        controllerElement
      )

      return promise
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
}

// Uniquely identify this browser tab in each Reflex
const tabId = uuidv4()

const useReflex = (controller, options = {}) => {
  register(controller, options)
}

document.addEventListener('cable-ready:after-dispatch-event', routeReflexEvent)
document.addEventListener('cable-ready:before-inner-html', beforeDOMUpdate)
document.addEventListener('cable-ready:before-morph', beforeDOMUpdate)
document.addEventListener('cable-ready:after-inner-html', afterDOMUpdate)
document.addEventListener('cable-ready:after-morph', afterDOMUpdate)
window.addEventListener('load', setupDeclarativeReflexes)

document.addEventListener('readystatechange', event => {
  if (event.target.readyState === 'complete') {
    setupDeclarativeReflexes()
  }
})

export { initialize, register, useReflex, setupDeclarativeReflexes }
