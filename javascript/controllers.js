import App from './app'
import Schema from './schema'

import { attributeValues } from './attributes'
import { extractReflexName, reflexNameToControllerIdentifier } from './utils'

// Returns StimulusReflex controllers local to the passed element based on the data-controller attribute.
//
const localReflexControllers = element => {
  return attributeValues(element.getAttribute(Schema.controller)).reduce(
    (memo, name) => {
      const controller = App.app.getControllerForElementAndIdentifier(
        element,
        name
      )
      if (controller && controller.StimulusReflex) memo.push(controller)
      return memo
    },
    []
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
    if (!controller.identifier) return

    return controller.identifier === reflexNameToControllerIdentifier(extractReflexName(reflexName))
  })

  return controller || controllers[0]
}

export { allReflexControllers, findControllerByReflexName }
