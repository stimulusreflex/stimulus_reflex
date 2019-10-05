import { dasherize, underscore } from 'inflected'
import { attributeValues } from './attributes'

// Returns the expected matching controller name for the passed reflex.
//
//   matchingControllerName('ExampleReflex#do_stuff') // 'example'
//
export const matchingControllerName = reflex => {
  return dasherize(underscore(reflex.split('#')[0].replace(/Reflex$/, '')))
}

// Finds the registered StimulusReflex controller for the passed element that matches the reflex.
// Traverses DOM ancestors starting with element until a match is found.
//
export const findReflexController = (application, element, reflex) => {
  const name = matchingControllerName(reflex)
  let controller
  while (element && !controller) {
    const controllers = attributeValues(element.dataset.controller)
    if (controllers.includes(name)) {
      const candidate = application.getControllerForElementAndIdentifier(
        element,
        name
      )
      if (candidate && candidate.StimulusReflex) controller = candidate
    }
    element = element.parentElement
  }
  return controller
}

// Returns StimulsReflex controllers local to the passed element based on the data-controller attribute.
//
export const localReflexControllers = (application, element) => {
  return attributeValues(element.dataset.controller).reduce((memo, name) => {
    const controller = application.getControllerForElementAndIdentifier(
      element,
      name
    )
    if (controller && controller.StimulusReflex) memo.push(controller)
    return memo
  }, [])
}

// Returns all StimulsReflex controllers for the passed element.
// Traverses DOM ancestors starting with element.
//
export const allReflexControllers = (application, element) => {
  let controllers = []
  while (element) {
    controllers = controllers.concat(
      localReflexControllers(application, element)
    )
    element = element.parentElement
  }
  return controllers
}
