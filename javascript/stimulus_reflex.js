import { Controller } from 'stimulus'
import ActionCable from 'actioncable'
import { camelize } from 'inflected'
import CableReady from 'cable_ready'
import { defaultSchema } from './schema'
import {
  attributeValue,
  attributeValues,
  extractElementAttributes,
  findElement,
  isTextInput
} from './attributes'
import {
  allReflexControllers,
  findReflexController,
  localReflexControllers
} from './controllers'

// A reference to the Stimulus application registered with: StimulusReflex.initialize
//
let app

// Initializes implicit data-reflex-permanent for text inputs.
//
const initializeImplicitReflexPermanent = event => {
  const element = event.target
  if (!isTextInput(element)) return
  element.reflexPermanent = element.hasAttribute(
    app.schema.reflexPermanentAttribute
  )
  element.setAttribute(app.schema.reflexPermanentAttribute, '')
}

// Resets implicit data-reflex-permanent for text inputs.
//
const resetImplicitReflexPermanent = event => {
  const element = event.target
  if (!isTextInput(element)) return
  if (element.reflexPermanent !== undefined && !element.reflexPermanent) {
    element.removeAttribute(app.schema.reflexPermanentAttribute)
  }
}

// Invokes a lifecycle method on a StimulusReflex controller.
//
// - before
// - success
// - error
// - after
//
const invokeLifecycleMethod = (stage, reflex, element) => {
  if (!element) return

  // traverse the DOM for a matching reflex controller
  const reflexController = findReflexController(app, element, reflex)

  // find reflex controllers wired on this element
  const controllers = new Set(localReflexControllers(app, element))

  if (reflexController) controllers.add(reflexController)
  if (controllers.length === 0) return

  controllers.forEach(controller => {
    const reflexMethodName = reflex.split('#')[1]

    const specificLifecycleMethodName = ['before', 'after'].includes(stage)
      ? `${stage}${camelize(reflexMethodName)}`
      : `${camelize(reflexMethodName, false)}${camelize(stage)}`
    const specificLifecycleMethod = controller[specificLifecycleMethodName]

    const genericLifecycleMethodName = ['before', 'after'].includes(stage)
      ? `${stage}Reflex`
      : `reflex${camelize(stage)}`
    const genericLifecycleMethod = controller[genericLifecycleMethodName]

    if (typeof specificLifecycleMethod === 'function') {
      setTimeout(
        () =>
          specificLifecycleMethod.call(
            controller,
            element,
            reflex,
            element.reflexError
          ),
        1
      )
    }

    if (typeof genericLifecycleMethod === 'function') {
      setTimeout(
        () =>
          genericLifecycleMethod.call(
            controller,
            element,
            reflex,
            element.reflexError
          ),
        1
      )
    }
  })
}

// Subscribes a StimulusReflex controller to an ActionCable channel and room.
//
// controller - the StimulusReflex controller to subscribe
//
const createSubscription = controller => {
  const { channel, room } = controller.StimulusReflex
  const id = `${channel}${room}`

  const subscription =
    SR.subscriptions[id] ||
    SR.consumer.subscriptions.create(
      { channel, room },
      {
        received: data => {
          if (!data.cableReady) return
          if (!data.operations.morph || !data.operations.morph.length) return
          const urls = [
            ...new Set(data.operations.morph.map(m => m.stimulusReflex.url))
          ]
          if (urls.length !== 1 || urls[0] !== location.href) return
          CableReady.perform(data.operations)
        }
      }
    )

  SR.subscriptions[id] = subscription
  controller.StimulusReflex.subscription = subscription
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
    // - element - [optional] the triggering element, defaults to this.element
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
        permanent_attribute_name: app.schema.reflexPermanentAttribute
      }
      invokeLifecycleMethod('before', target, element)
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
        reflex = element.getAttribute(app.schema.reflexAttribute)
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
//   * room - the ActionCable room to subscribe to
//
const register = (controller, options = {}) => {
  const channel = 'StimulusReflex::Channel'
  const room =
    options.room ||
    controller.element.getAttribute(app.schema.roomAttribute) ||
    ''
  controller.StimulusReflex = { ...options, channel, room }
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
    .querySelectorAll(`[${app.schema.reflexAttribute}]`)
    .forEach(element => {
      const controllers = attributeValues(
        element.getAttribute(app.schema.controllerAttribute)
      )
      const reflexes = attributeValues(
        element.getAttribute(app.schema.reflexAttribute)
      )
      const actions = attributeValues(
        element.getAttribute(app.schema.actionAttribute)
      )
      reflexes.forEach(reflex => {
        const controller = allReflexControllers(app, element)[0]
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
        element.setAttribute(app.schema.controllerAttribute, controllerValue)
      }
      if (actionValue)
        element.setAttribute(app.schema.actionAttribute, actionValue)
    })
}

// compute the DOM element(s) which will be the morph root
// use the data-reflex-root attribute on the reflex or the controller
// optional value is a CSS selector(s); comma-separated list
// order of preference is data-reflex, data-controller, document body (default)
const getReflexRoots = element => {
  let list = []
  while (list.length === 0 && element) {
    const reflexRoot = element.getAttribute(app.schema.reflexRootAttribute)
    if (reflexRoot) {
      if (reflexRoot.length === 0 && element.id) reflexRoot = `#${element.id}`
      const selectors = reflexRoot.split(',').filter(s => s.trim().length)
      if (selectors.length === 0) {
        console.error(
          `No value found for ${app.schema.reflexRootAttribute}. Add an #id to the element or provide a value for ${app.schema.reflexRootAttribute}.`,
          element
        )
      }
      list = list.concat(selectors.filter(s => document.querySelector(s)))
    }
    element = element.parentElement
      ? element.parentElement.closest(`[${app.schema.reflexRootAttribute}]`)
      : null
  }
  return list
}

// Initializes StimulusReflex by registering the default Stimulus controller with the passed Stimulus application.
//
// - application - the Stimulus application
// - controller - [optional] the default StimulusReflexController
//
const initialize = (
  stimulusApplication,
  controller = StimulusReflexController
) => {
  app = stimulusApplication
  app.schema = { ...defaultSchema, ...app.schema }
  app.register('stimulus-reflex', controller)
}

// Wire everything up
//
const SR = window.StimulusReflex || {}
SR.consumer = SR.consumer || ActionCable.createConsumer()
SR.subscriptions = SR.subscriptions || {}

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
    invokeLifecycleMethod('success', target, element)
    invokeLifecycleMethod('after', target, element)
  })
  document.addEventListener('stimulus-reflex:500', event => {
    const { target, attrs, error } = event.detail.stimulusReflex || {}
    const element = findElement(attrs)
    element.reflexError = error
    invokeLifecycleMethod('error', target, element)
    invokeLifecycleMethod('after', target, element)
  })
  document.addEventListener('focusin', initializeImplicitReflexPermanent)
  document.addEventListener('focusout', resetImplicitReflexPermanent)
}

export default { initialize, register }
