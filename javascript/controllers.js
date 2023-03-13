import App from './app'
import Schema from './schema'

import { attributeValues } from './attributes'
import { extractReflexName, reflexNameToControllerIdentifier } from './utils'

// Returns StimulusReflex controllers local to the passed element based on the data-controller attribute.
//
const localReflexControllers = element => {
  const potentialIdentifiers = attributeValues(element.getAttribute(Schema.controller))

  const potentialControllers = potentialIdentifiers.map(
    identifier => App.app.getControllerForElementAndIdentifier(element, identifier)
  )

  return potentialControllers.filter(
    controller => controller && controller.StimulusReflex
  )
}

// Returns all StimulusReflex controllers for the passed element.
// Traverses DOM ancestors starting with element.
//
const allReflexControllers = element => {
  let controllers = []
  while (element) {
    controllers = controllers.concat(localReflexControllers(element))
    element = element.parentElement
  }
  return controllers
}

// Given a reflex string such as 'click->TestReflex#create' and a list of
// controllers. It will find the matching controller based on the controller's
// identifier. e.g. Given these controller identifiers ['foo', 'bar', 'test'],
// it would select the 'test' controller.
const findControllerByReflexName = (reflexName, controllers) => {
  const controller = controllers.find(controller => {
    if (!controller || !controller.identifier) return

    const identifier = reflexNameToControllerIdentifier(extractReflexName(reflexName))

    return identifier === controller.identifier
  })

  return controller || controllers[0]
}

export { allReflexControllers, findControllerByReflexName }
