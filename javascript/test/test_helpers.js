import App from '../app'

export function registeredControllers () {
  return Array.from(App.app.router.modulesByIdentifier.keys())
}

export function unloadAllControllers () {
  App.app.unload(registeredControllers())
}

export function identifiers (controllers) {
  return controllers.map(controller => controller.identifier)
}
