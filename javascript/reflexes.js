import CableReady from 'cable_ready'
import Debug from './debug'
import { dispatchLifecycleEvent } from './lifecycle'
import {
  debounce,
  elementToXPath,
  emitEvent,
  serializeForm,
  XPathToElement
} from './utils'
import { allReflexControllers, findControllerByReflexName } from './controllers'
import {
  attributeValue,
  attributeValues,
  extractElementAttributes,
  extractElementDataset
} from './attributes'
import isolationMode from './isolation_mode'
import Log from './log'

const reflexes = {}

export default reflexes

export const received = data => {
  if (!data.cableReady) return

  let reflexOperations = {}

  for (let name in data.operations) {
    if (data.operations.hasOwnProperty(name)) {
      for (let i = data.operations[name].length - 1; i >= 0; i--) {
        if (
          data.operations[name][i].stimulusReflex ||
          (data.operations[name][i].detail &&
            data.operations[name][i].detail.stimulusReflex)
        ) {
          reflexOperations[name] = reflexOperations[name] || []
          reflexOperations[name].push(data.operations[name][i])
          data.operations[name].splice(i, 1)
        }
      }
      if (!data.operations[name].length)
        Reflect.deleteProperty(data.operations, name)
    }
  }

  let totalOperations = 0
  let reflexData

  const dispatchEvent = reflexOperations['dispatchEvent']
  const morph = reflexOperations['morph']
  const innerHtml = reflexOperations['innerHtml']

  ;[dispatchEvent, morph, innerHtml].forEach(operation => {
    if (operation && operation.length) {
      const urls = Array.from(
        new Set(
          operation.map(m =>
            m.detail ? m.detail.stimulusReflex.url : m.stimulusReflex.url
          )
        )
      )

      if (urls.length !== 1 || urls[0] !== location.href) return
      totalOperations += operation.length

      if (!reflexData) {
        if (operation[0].detail) {
          reflexData = operation[0].detail.stimulusReflex
          reflexData.payload = operation[0].detail.payload
          reflexData.reflexId = operation[0].detail.reflexId
        } else {
          reflexData = operation[0].stimulusReflex
          reflexData.payload = operation[0].payload
        }
      }
    }
  })

  if (reflexData) {
    const { reflexId, payload } = reflexData

    if (!reflexes[reflexId] && isolationMode.disabled) {
      const controllerElement = XPathToElement(reflexData.xpathController)
      const reflexElement = XPathToElement(reflexData.xpathElement)
      controllerElement.reflexController =
        controllerElement.reflexController || {}
      controllerElement.reflexData = controllerElement.reflexData || {}
      controllerElement.reflexError = controllerElement.reflexError || {}

      controllerElement.reflexController[
        reflexId
      ] = reflexes.app.getControllerForElementAndIdentifier(
        controllerElement,
        reflexData.reflexController
      )

      controllerElement.reflexData[reflexId] = reflexData
      dispatchLifecycleEvent(
        'before',
        reflexElement,
        controllerElement,
        reflexId,
        payload
      )
      registerReflex(reflexData)
    }

    if (reflexes[reflexId]) {
      reflexes[reflexId].totalOperations = totalOperations
      reflexes[reflexId].pendingOperations = totalOperations
      reflexes[reflexId].completedOperations = 0
      reflexes[reflexId].piggybackOperations = data.operations
      CableReady.perform(reflexOperations)
    }
  } else {
    const operations = Object.entries(data.operations)
    if (operations.length && reflexes[operations[0][1][0].reflexId])
      CableReady.perform(data.operations)
  }
}

export const registerReflex = data => {
  const { reflexId } = data
  reflexes[reflexId] = { finalStage: 'finalize' }

  const promise = new Promise((resolve, reject) => {
    reflexes[reflexId].promise = {
      resolve,
      reject,
      data
    }
  })

  promise.reflexId = reflexId

  if (Debug.enabled) promise.catch(() => {})

  return promise
}

// compute the DOM element(s) which will be the morph root
// use the data-reflex-root attribute on the reflex or the controller
// optional value is a CSS selector(s); comma-separated list
// order of preference is data-reflex, data-controller, document body (default)
export const getReflexRoots = element => {
  let list = []
  while (list.length === 0 && element) {
    let reflexRoot = element.getAttribute(
      reflexes.app.schema.reflexRootAttribute
    )
    if (reflexRoot) {
      if (reflexRoot.length === 0 && element.id) reflexRoot = `#${element.id}`
      const selectors = reflexRoot.split(',').filter(s => s.trim().length)
      if (Debug.enabled && selectors.length === 0) {
        console.error(
          `No value found for ${reflexes.app.schema.reflexRootAttribute}. Add an #id to the element or provide a value for ${application.schema.reflexRootAttribute}.`,
          element
        )
      }
      list = list.concat(selectors.filter(s => document.querySelector(s)))
    }
    element = element.parentElement
      ? element.parentElement.closest(
          `[${reflexes.app.schema.reflexRootAttribute}]`
        )
      : null
  }
  return list
}

// Sets up declarative reflex behavior.
// Any elements that define data-reflex will automatically be wired up with the default StimulusReflexController.
//
export const setupDeclarativeReflexes = debounce(() => {
  document
    .querySelectorAll(`[${reflexes.app.schema.reflexAttribute}]`)
    .forEach(element => {
      const controllers = attributeValues(
        element.getAttribute(reflexes.app.schema.controllerAttribute)
      )
      const reflexAttributeNames = attributeValues(
        element.getAttribute(reflexes.app.schema.reflexAttribute)
      )
      const actions = attributeValues(
        element.getAttribute(reflexes.app.schema.actionAttribute)
      )
      reflexAttributeNames.forEach(reflexName => {
        const controller = findControllerByReflexName(
          reflexName,
          allReflexControllers(reflexes.app, element)
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
        element.getAttribute(reflexes.app.schema.controllerAttribute) !=
          controllerValue
      ) {
        element.setAttribute(
          reflexes.app.schema.controllerAttribute,
          controllerValue
        )
      }
      if (
        actionValue &&
        element.getAttribute(reflexes.app.schema.actionAttribute) != actionValue
      )
        element.setAttribute(reflexes.app.schema.actionAttribute, actionValue)
    })
  emitEvent('stimulus-reflex:ready')
}, 20)

export const reflexControllerMethods = {
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
    const dataset = extractElementDataset(reflexElement)
    const xpathController = elementToXPath(controllerElement)
    const xpathElement = elementToXPath(reflexElement)
    const data = {
      target,
      args,
      url,
      tabId,
      attrs,
      dataset,
      selectors,
      reflexId,
      resolveLate,
      xpathController,
      xpathElement,
      reflexController: this.identifier,
      permanentAttributeName: reflexes.app.schema.reflexPermanentAttribute
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

    dispatchLifecycleEvent('before', reflexElement, controllerElement, reflexId)

    setTimeout(() => {
      const { params } = controllerElement.reflexData[reflexId] || {}
      const serializeAttribute =
        reflexElement.attributes[
          reflexes.app.schema.reflexSerializeFormAttribute
        ]
      if (serializeAttribute) {
        // not needed after v4 because this is only here for the deprecation warning
        options['serializeForm'] = false
        if (serializeAttribute.value === 'true') options['serializeForm'] = true
      }

      const form = reflexElement.closest('form')

      if (Deprecate.enabled && options['serializeForm'] === undefined && form)
        console.warn(
          `Deprecation warning: the next version of StimulusReflex will not serialize forms by default.\nPlease set ${reflexes.app.schema.reflexSerializeFormAttribute}=\"true\" on your Reflex Controller Element or pass { serializeForm: true } as an option to stimulate.`
        )
      const formData =
        options['serializeForm'] === false
          ? ''
          : serializeForm(form, {
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
      reflex = element.getAttribute(reflexes.app.schema.reflexAttribute)
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
}
