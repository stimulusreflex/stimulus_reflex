import Schema from './schema'

import { attributeValues, attributeValue } from './attributes'
import { debounce, dispatch } from './utils'
import { findControllerByReflexName, allReflexControllers } from './controllers'
import { reflexes } from './reflexes'

// Sets up declarative reflex behavior.
// Any elements that define data-reflex will automatically be wired up with the default StimulusReflexController.
//
const scanForReflexes = debounce(() => {
  const reflexElements = document.querySelectorAll(`[${Schema.reflex}]`)
  reflexElements.forEach(element => scanForReflexesOnElement(element))
}, 20)

const scanForReflexesOnElement = (element, controller = null) => {
  const controllerAttribute = element.getAttribute(Schema.controller)
  const controllers = attributeValues(controllerAttribute).filter(
    controller => controller !== 'stimulus-reflex'
  )

  const reflexAttribute = element.getAttribute(Schema.reflex)
  const reflexAttributeNames = attributeValues(reflexAttribute)

  const actionAttribute = element.getAttribute(Schema.action)
  const actions = attributeValues(actionAttribute).filter(
    action => !action.includes('#__perform')
  )

  reflexAttributeNames.forEach(reflexName => {
    const potentialControllers = [controller].concat(allReflexControllers(element))

    controller = findControllerByReflexName(
      reflexName,
      potentialControllers
    )
    const controllerName = controller
      ? controller.identifier
      : 'stimulus-reflex'

    actions.push(`${reflexName.split('->')[0]}->${controllerName}#__perform`)

    const parentControllerElement = element.closest(`[data-controller~=${controllerName}]`)

    if (!parentControllerElement) {
      controllers.push(controllerName)
    }
  })

  const controllerValue = attributeValue(controllers)
  const actionValue = attributeValue(actions)

  let emitReadyEvent = false

  if (
    controllerValue &&
    element.getAttribute(Schema.controller) != controllerValue
  ) {
    element.setAttribute(Schema.controller, controllerValue)
    emitReadyEvent = true
  }

  if (actionValue && element.getAttribute(Schema.action) != actionValue) {
    element.setAttribute(Schema.action, actionValue)
    emitReadyEvent = true
  }

  if (emitReadyEvent) {
    dispatch(element, 'stimulus-reflex:ready', {
      reflex: reflexAttribute,
      controller: controllerValue,
      action: actionValue,
      element
    })
  }
}
export { scanForReflexes, scanForReflexesOnElement }
