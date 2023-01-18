import Schema from './schema'
import Stimulus from './app'

import { attributeValues } from './attributes'
import { extractReflexName } from './utils'

// Returns StimulusReflex controllers local to the passed element based on the data-controller attribute.
//
const localReflexControllers = element => {
  return attributeValues(element.getAttribute(Schema.controller)).reduce(
    (memo, name) => {
      const controller = Stimulus.app.getControllerForElementAndIdentifier(
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

    return (
      extractReflexName(reflexName)
        .replace(/([a-z0–9])([A-Z])/g, '$1-$2')
        .replace(/(::)/g, '--')
        .toLowerCase() === controller.identifier
    )
  })

  return controller || controllers[0]
}

export { allReflexControllers, findControllerByReflexName }
