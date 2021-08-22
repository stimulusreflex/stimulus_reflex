import CableReady from 'cable_ready'
import Debug from './debug'
import Schema from './schema'
import isolationMode from './isolation_mode'
import { dispatchLifecycleEvent } from './lifecycle'
import { XPathToElement, debounce, emitEvent } from './utils'
import { allReflexControllers, findControllerByReflexName } from './controllers'
import { attributeValue, attributeValues } from './attributes'

const reflexes = {}

const received = data => {
  if (!data.cableReady) return

  let reflexOperations = []

  for (let i = data.operations.length - 1; i >= 0; i--) {
    if (data.operations[i].stimulusReflex) {
      reflexOperations.push(data.operations[i])
      data.operations.splice(i, 1)
    }
  }

  if (
    reflexOperations.some(operation => {
      return operation.stimulusReflex.url !== location.href
    })
  )
    return

  let reflexData

  if (reflexOperations.length) {
    reflexData = reflexOperations[0].stimulusReflex
    reflexData.payload = reflexOperations[0].payload
  }

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
      reflexes[reflexId].totalOperations = reflexOperations.length
      reflexes[reflexId].pendingOperations = reflexOperations.length
      reflexes[reflexId].completedOperations = 0
      reflexes[reflexId].piggybackOperations = data.operations
      CableReady.perform(reflexOperations)
    }
  } else {
    if (data.operations.length && reflexes[data.operations[0].reflexId])
      CableReady.perform(data.operations)
  }
}

const registerReflex = data => {
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
const setupDeclarativeReflexes = debounce(() => {
  document.querySelectorAll(`[${Schema.reflex}]`).forEach(element => {
    const controllers = attributeValues(element.getAttribute(Schema.controller))
    const reflexAttributeNames = attributeValues(
      element.getAttribute(Schema.reflex)
    )
    const actions = attributeValues(element.getAttribute(Schema.action))
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
      element.getAttribute(Schema.controller) != controllerValue
    ) {
      element.setAttribute(Schema.controller, controllerValue)
    }
    if (actionValue && element.getAttribute(Schema.action) != actionValue)
      element.setAttribute(Schema.action, actionValue)
  })
  emitEvent('stimulus-reflex:ready')
}, 20)

export default reflexes
export { received, registerReflex, getReflexRoots, setupDeclarativeReflexes }
