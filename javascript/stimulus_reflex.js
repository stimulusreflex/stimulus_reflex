import { Controller } from 'stimulus'
import { defaultSchema } from './schema'
import { uuidv4 } from './utils'
import { beforeDOMUpdate, afterDOMUpdate, serverMessage } from './callbacks'
import { reflexControllerMethods } from './controllers'
import { setupDeclarativeReflexes, reflexControllerMethods } from './reflexes'
import Debug from './debug'
import Deprecate from './deprecate'
import reflexes from './reflexes'
import isolationMode from './isolation_mode'
import actionCable from './transports/action_cable'

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
const initialize = (application, initializeOptions = {}) => {
  const {
    controller,
    consumer,
    debug,
    params,
    isolate,
    deprecate
  } = initializeOptions
  actionCable.set(consumer, params)
  setTimeout(() => {
    if (Deprecate.enabled && consumer)
      console.warn(
        "Deprecation warning: the next version of StimulusReflex will obtain a reference to consumer via the Stimulus application object.\nPlease add 'application.consumer = consumer' to your index.js after your Stimulus application has been established, and remove the consumer key from your StimulusReflex initialize() options object."
      )
  })
  isolationMode.set(!!isolate)
  setTimeout(() => {
    if (Deprecate.enabled && isolationMode.disabled)
      console.warn(
        'Deprecation warning: the next version of StimulusReflex will standardize isolation mode, and the isolate option will be removed.\nPlease update your applications to assume that every tab will be isolated.'
      )
  })
  reflexes.app = application
  reflexes.app.schema = { ...defaultSchema, ...application.schema }
  reflexes.app.register(
    'stimulus-reflex',
    controller || StimulusReflexController
  )
  Debug.set(!!debug)
  if (typeof deprecate !== 'undefined') Deprecate.set(deprecate)
  const observer = new MutationObserver(setupDeclarativeReflexes)
  observer.observe(document.documentElement, {
    attributeFilter: [
      reflexes.app.schema.reflexAttribute,
      reflexes.app.schema.actionAttribute
    ],
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
  actionCable.createSubscription(controller)
  Object.assign(controller, reflexControllerMethods)
}

// Uniquely identify this browser tab in each Reflex
const tabId = uuidv4()

const useReflex = (controller, options = {}) => {
  register(controller, options)
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
  useReflex,
  get debug () {
    return Debug.value
  },
  set debug (value) {
    Debug.set(!!value)
  },
  get deprecate () {
    return Deprecate.value
  },
  set deprecate (value) {
    Deprecate.set(!!value)
  }
}
