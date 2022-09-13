import { reflexes } from './reflexes'
import Schema from './schema'
import { attributeValues, attributeValue } from './attributes'
import { findControllerByReflexName, allReflexControllers } from './controllers'
import { debounce, emitEvent } from './utils'

// Sets up declarative reflex behavior.
// Any elements that define data-reflex will automatically be wired up with the default StimulusReflexController.
//
const scanForReflexes = debounce(() => {
  const reflexElements = document.querySelectorAll(`[${Schema.reflex}]`)
  reflexElements.forEach(element => scanForReflexesOnElement(element))
  emitEvent('stimulus-reflex:ready')
}, 20)

const scanForReflexesOnElement = element => {
  const controllerAttribute = element.getAttribute(Schema.controller)
  const controllers = attributeValues(controllerAttribute)

  const reflexAttribute = element.getAttribute(Schema.reflex)
  const reflexAttributeNames = attributeValues(reflexAttribute)

  const actionAttribute = element.getAttribute(Schema.action)
  const actions = attributeValues(actionAttribute).filter(
    action => !action.includes('#__perform')
  )

  reflexAttributeNames.forEach(reflexName => {
    const controller = findControllerByReflexName(
      reflexName,
      allReflexControllers(element)
    )
    const controllerName = controller
      ? controller.identifier
      : 'stimulus-reflex'

    actions.push(`${reflexName.split('->')[0]}->${controllerName}#__perform`)
    controllers.push(controllerName)
  })

  const controllerValue = attributeValue(controllers)
  const actionValue = attributeValue(actions)

  if (
    controllerValue &&
    element.getAttribute(Schema.controller) != controllerValue
  ) {
    element.setAttribute(Schema.controller, controllerValue)
  }

  if (actionValue && element.getAttribute(Schema.action) != actionValue) {
    element.setAttribute(Schema.action, actionValue)
  }
}
export { scanForReflexes, scanForReflexesOnElement }
