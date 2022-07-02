import CableReady from 'cable_ready'

import Debug from './debug'
import Stimulus from './app'
import Schema from './schema'
import Reflex from './reflex'
import IsolationMode from './isolation_mode'

import { reflexes } from './reflex_store'
import { dispatchLifecycleEvent } from './lifecycle'
import { XPathToElement, debounce, emitEvent } from './utils'
import { allReflexControllers, findControllerByReflexName } from './controllers'
import { attributeValue, attributeValues } from './attributes'

const received = data => {
  if (!data.cableReady) return

  if (data.version.replace('.pre', '-pre') !== CableReady.version) {
    if (Debug.enabled)
      console.error(
        `Reflex failed due to cable_ready gem/NPM package version mismatch. Package versions must match exactly.\nNote that if you are using pre-release builds, gems use the "x.y.z.preN" version format, while NPM packages use "x.y.z-preN".\n\ncable_ready gem: ${data.version}\ncable_ready NPM: ${CableReady.version}`
      )
    return
  }

  let reflexOperations = []

  for (let i = data.operations.length - 1; i >= 0; i--) {
    if (data.operations[i].stimulusReflex) {
      reflexOperations.push(data.operations[i])
      data.operations.splice(i, 1)
    }
  }

  if (
    reflexOperations.some(
      operation => operation.stimulusReflex.url !== location.href
    )
  ) {
    if (Debug.enabled) {
      console.error('Reflex failed due to mismatched URL.')
      return
    }
  }

  let reflexData

  if (reflexOperations.length) {
    reflexData = reflexOperations[0].stimulusReflex
    reflexData.payload = reflexOperations[0].payload
  }

  if (reflexData) {
    const { reflexId, payload } = reflexData
    let reflex

    // TODO: remove this in v4
    if (!reflexes[reflexId] && IsolationMode.disabled) {
      const controllerElement = XPathToElement(reflexData.xpathController)
      const reflexElement = XPathToElement(reflexData.xpathElement)

      controllerElement.reflexController =
        controllerElement.reflexController || {}
      controllerElement.reflexData = controllerElement.reflexData || {}
      controllerElement.reflexError = controllerElement.reflexError || {}

      const controller = Stimulus.app.getControllerForElementAndIdentifier(
        controllerElement,
        reflexData.reflexController
      )

      controllerElement.reflexController[reflexId] = controller
      controllerElement.reflexData[reflexId] = reflexData

      reflex = new Reflex(reflexData, controller)
      reflexes[reflexId] = reflex
      reflex.cloned = true
      reflex.element = reflexElement
      controller.lastReflex = reflex

      dispatchLifecycleEvent(reflex, 'before')
      reflex.getPromise
    } else {
      // v4 keep this, make it a const, kill line 55
      reflex = reflexes[reflexId]
    }
    // END TODO: remove

    if (reflex) {
      reflex.payload = payload
      reflex.totalOperations = reflexOperations.length
      reflex.pendingOperations = reflexOperations.length
      reflex.completedOperations = 0
      reflex.piggybackOperations = data.operations
      CableReady.perform(reflexOperations)
    }
  } else {
    if (data.operations.length && reflexes[data.operations[0].reflexId]) {
      CableReady.perform(data.operations)
    }
  }
}

const getReflexElement = (args, element) => {
  return args[0] && args[0].nodeType === Node.ELEMENT_NODE
    ? args.shift()
    : element
}

const getReflexOptions = args => {
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
  return options
}

// compute the DOM element(s) which will be the morph root
// use the data-reflex-root attribute on the reflex or the controller
// optional value is a CSS selector(s); comma-separated list
// order of preference is data-reflex, data-controller, document body (default)
const getReflexRoots = element => {
  let list = []
  while (list.length === 0 && element) {
    let reflexRoot = element.getAttribute(Schema.reflexRoot)
    if (reflexRoot) {
      if (reflexRoot.length === 0 && element.id) reflexRoot = `#${element.id}`
      const selectors = reflexRoot.split(',').filter(s => s.trim().length)
      if (Debug.enabled && selectors.length === 0) {
        console.error(
          `No value found for ${Schema.reflexRoot}. Add an #id to the element or provide a value for ${Schema.reflexRoot}.`,
          element
        )
      }
      list = list.concat(selectors.filter(s => document.querySelector(s)))
    }
    element = element.parentElement
      ? element.parentElement.closest(`[${Schema.reflexRoot}]`)
      : null
  }
  return list
}

// Sets up declarative reflex behavior.
// Any elements that define data-reflex will automatically be wired up with the default StimulusReflexController.
//
const scanForReflexes = debounce(() => {
  document.querySelectorAll(`[${Schema.reflex}]`).forEach(element => {
    const controllers = attributeValues(element.getAttribute(Schema.controller))
    const reflexAttributeNames = attributeValues(
      element.getAttribute(Schema.reflex)
    )
    const actions = attributeValues(element.getAttribute(Schema.action))
    reflexAttributeNames.forEach(reflexName => {
      const controller = findControllerByReflexName(
        reflexName,
        allReflexControllers(Stimulus.app, element)
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
      element.getAttribute(Schema.controller) != controllerValue
    ) {
      element.setAttribute(Schema.controller, controllerValue)
    }
    if (actionValue && element.getAttribute(Schema.action) != actionValue)
      element.setAttribute(Schema.action, actionValue)
  })
  emitEvent('stimulus-reflex:ready')
}, 20)

export {
  received,
  getReflexElement,
  getReflexOptions,
  getReflexRoots,
  scanForReflexes
}
